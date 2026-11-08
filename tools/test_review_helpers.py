"""Offline regression checks: python -m unittest discover -s tools -p test_review_helpers.py.

Extract helpers with ast so these tests need neither Pillow nor ARTEMIS/pytest.
"""
import ast
import asyncio
import copy
import hashlib
import json
import os
import re
from pathlib import Path
import shlex
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parent.parent


def helpers(file, names, **namespace):
    tree = ast.parse((ROOT / file).read_text(encoding="utf-8"))
    tree.body = [node for node in tree.body
                 if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in names]
    for node in tree.body:
        node.decorator_list = []  # Test the body without E2E markers or device fixtures.
    exec(compile(tree, file, "exec"), namespace)
    return SimpleNamespace(**namespace)


class ReviewHelpersTest(unittest.TestCase):
    def test_adb_rejects_unsupported_text_before_clearing_app(self):
        def fail(message, **kwargs):
            raise ValueError(message)
        adb = Mock()
        for password in ("has%sescape", "tiếngViệt", "line\nbreak", "tab\t", "emoji😀"):
            module = helpers("e2e_test/conftest.py", {"validate_adb_text", "adb_input_text", "adb_viewer_login"},
                adb=adb, re=re, shlex=shlex, pytest=SimpleNamespace(fail=fail),
                required=lambda name: "viewer@example.test" if name.endswith("EMAIL") else password,
                app_package=lambda: "test")
            with self.assertRaisesRegex(ValueError, "ADB_LOGIN.*ASCII.*%"):
                module.adb_viewer_login()
            adb.assert_not_called()

    def test_tc24_preserves_body_and_recovery_failures(self):
        class Failed(BaseException):
            pass
        for body_error in (None, AssertionError("body failed"), Failed("body pytest failed")):
            for recovery_error in (None, AssertionError("restore failed"), Failed("restore pytest failed")):
                async def run_case(*args):
                    if body_error:
                        raise body_error
                    return SimpleNamespace(succeeded=True)
                async def execute(*args):
                    if recovery_error:
                        raise recovery_error
                    return SimpleNamespace(succeeded=True)
                module = helpers("e2e_test/test_auth.py", {"test_tc24_change_password_and_logout"},
                    ArtemisClient=object, pytest=SimpleNamespace(fail=SimpleNamespace(Exception=Failed)),
                    required=lambda name: "test", secret=lambda value: value, json=json,
                    secrets=SimpleNamespace(token_urlsafe=lambda n: "temp"), LOGOUT="",
                    run_case=run_case, execute=execute)
                # Body output must match its exact expected object.
                outputs = iter([{"password_changed": True, "logged_out": True, "current_screen": "login"},
                                {"restored": True}])
                module.test_tc24_change_password_and_logout.__globals__["output"] = lambda result: (
                    next(outputs) if body_error is None else {"restored": True})
                with self.subTest(body=body_error, recovery=recovery_error):
                    try:
                        asyncio.run(module.test_tc24_change_password_and_logout(None, None))
                    except BaseException as exc:
                        if body_error and recovery_error:
                            self.assertIsInstance(exc, BaseExceptionGroup)
                            self.assertEqual(exc.exceptions, (body_error, recovery_error))
                        else:
                            self.assertIs(exc, body_error or recovery_error)
                    else:
                        self.assertIsNone(body_error or recovery_error)

    def test_tc21_restore_timeout_blocks_new_baseline_across_rounds(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "results").mkdir()
            for original in (1, 2, 20):
                with self.subTest(original=original):
                    signals = []
                    async def signal(case, detail):
                        signals.append((case, detail))
                        if case == "tc21-baseline":
                            return str(original)
                        if case == "tc21-restore":
                            raise TimeoutError("restore timeout")
                        return "done"
                    async def run_case(*args):
                        return SimpleNamespace(succeeded=True)
                    module = helpers("e2e_test/test_profile_remote_config.py",
                        {"test_tc21_remote_config_live_limit"}, ArtemisClient=object, ROOT=root,
                        wait_operator_signal=signal, run_case=run_case)
                    # Supply the distinct shapes returned by the two ARTEMIS calls.
                    outputs = iter([{"baseline_count": original},
                        {"count": 2 if original == 1 else 1, "restart_used": False, "manual_reload_used": False}])
                    module.test_tc21_remote_config_live_limit.__globals__["output"] = lambda result: next(outputs)
                    with self.assertRaises(TimeoutError):
                        asyncio.run(module.test_tc21_remote_config_live_limit(None))
                    pending = root / "results" / ".tc21-original-limit"
                    self.assertTrue(pending.exists())
                    self.assertEqual(pending.read_text(), str(original))
                    signals.clear()
                    with self.assertRaises(TimeoutError):
                        asyncio.run(module.test_tc21_remote_config_live_limit(None))
                    self.assertEqual([case for case, _ in signals], ["tc21-restore"])
                    self.assertIn(f"={original}", signals[0][1])
                    self.assertEqual(pending.read_text(), str(original))
                    # A later round may take a new baseline only after successful restore.
                    signals.clear()
                    async def restored(case, detail):
                        signals.append(case)
                        if case == "tc21-baseline":
                            raise RuntimeError("new baseline requested")
                        return "done"
                    module.test_tc21_remote_config_live_limit.__globals__["wait_operator_signal"] = restored
                    with self.assertRaisesRegex(RuntimeError, "new baseline requested"):
                        asyncio.run(module.test_tc21_remote_config_live_limit(None))
                    self.assertEqual(signals, ["tc21-restore", "tc21-baseline"])
                    self.assertFalse(pending.exists())

    def test_wrap_omits_blank_lines_and_keeps_long_words(self):
        module = helpers("tools/video/make_videos.py", {"wrap"})
        draw = SimpleNamespace(textlength=lambda text, font: len(text))
        self.assertEqual(module.wrap(draw, "\nlongword\n\na b\n", None, 3), ["longword", "a b"])

    def test_duration_matches_mapper(self):
        module = helpers("tools/video/make_videos.py", {"step_duration"})
        for step in ({}, {"durationSeconds": None}, {"durationSeconds": 0}, {"durationSeconds": -1}):
            self.assertEqual(module.step_duration(step), 10)
        self.assertEqual(module.step_duration({"durationSeconds": 7}), 7)

    def test_frame_duration_label_matches_effective_duration(self):
        draw = Mock()
        draw.textlength.return_value = 0
        module = helpers("tools/video/make_videos.py", {"frame", "step_duration"},
            Image=SimpleNamespace(new=Mock()), ImageDraw=SimpleNamespace(Draw=lambda img: draw),
            W=1280, H=720, CANVAS=0, SAND_LIGHT=0, BORDER=0, INK=0, SAND_DARK=0,
            SAND=0, OCEAN=0, SECONDARY=0, LIQUID=[0], font=lambda *args: None,
            wrap=lambda *args: [], draw_cup=Mock())
        for raw in (None, 0, -5, 7):
            draw.reset_mock()
            step = {"durationSeconds": raw}
            duration = module.step_duration(step)
            module.frame({"name": "recipe"}, 0, step, duration, duration, 1)
            labels = [call.args[1] for call in draw.text.call_args_list]
            self.assertIn(f"{duration} giây", labels)
            if raw != duration:
                self.assertNotIn(f"{raw} giây", labels)

    def test_font_environment_and_missing_font(self):
        module = helpers("tools/video/make_videos.py", {"find_font"}, os=os, Path=Path)
        with patch.dict(os.environ, {"RH_FONT": str(Path(__file__).resolve())}):
            self.assertEqual(module.find_font(), str(Path(__file__).resolve()))
        with patch.object(Path, "is_file", return_value=False):
            with self.assertRaisesRegex(RuntimeError, "RH_FONT_BOLD"):
                module.find_font(True)

    def test_cli_validates_before_build(self):
        import sys
        build = Mock()
        module = helpers("tools/video/make_videos.py", {"main"}, sys=sys, json=json,
                         os=os, build=build)
        with patch.object(sys, "argv", ["make_videos.py"]):
            with self.assertRaisesRegex(SystemExit, "Usage"):
                module.main()
        with patch.object(sys, "argv", ["make_videos.py", str(ROOT / "tools/seed/recipes.json"), ".", "MISSING"]):
            with self.assertRaisesRegex(SystemExit, "MISSING"):
                module.main()
        build.assert_not_called()

    def test_adb_quotes_shell_metacharacters(self):
        adb = Mock()
        module = helpers("e2e_test/conftest.py", {"validate_adb_text", "adb_input_text"},
                         adb=adb, shlex=shlex, re=re)
        text = "a b'\";$()&|<>`"
        module.adb_input_text(text)
        args = adb.call_args.args
        self.assertEqual(args[:3], ("shell", "input", "text"))
        self.assertEqual(shlex.split(args[3]), [text.replace(" ", "%s")])

    def test_required_rejects_empty_and_missing(self):
        def fail(message, **kwargs):
            raise ValueError(message)
        module = helpers("e2e_test/conftest.py", {"required"}, os=os,
                         pytest=SimpleNamespace(fail=fail))
        with patch.dict(os.environ, {}, clear=True):
            for value in (None, "", "   "):
                if value is not None:
                    os.environ["REVIEW_TEST_REQUIRED"] = value
                with self.assertRaisesRegex(ValueError, "Missing or empty.*REVIEW_TEST_REQUIRED"):
                    module.required("REVIEW_TEST_REQUIRED")

    def test_shuffle_preserves_answers_and_is_idempotent(self):
        module = helpers("tools/seed/shuffle_quizzes.py", {"shuffle_quizzes"}, hashlib=hashlib)
        data = json.loads((ROOT / "tools/seed/quizzes.json").read_text(encoding="utf-8"))
        before = copy.deepcopy(data)
        after = module.shuffle_quizzes(data)
        self.assertEqual(after, before)  # Checked-in seed is already canonical.
        self.assertEqual(module.shuffle_quizzes(copy.deepcopy(after)), after)
        for quiz in data:
            for question in quiz["questions"]:
                reversed_question = copy.deepcopy(question)
                correct = question["options"][question["correctIndex"]]
                reversed_question["options"].reverse()
                reversed_question["correctIndex"] = reversed_question["options"].index(correct)
                candidate = [{"id": quiz["id"], "questions": [reversed_question]}]
                self.assertEqual(module.shuffle_quizzes(candidate)[0]["questions"][0], question)


if __name__ == "__main__":
    unittest.main()
