"""Offline regression checks: python -m unittest discover -s tools -p test_review_helpers.py.

Extract helpers with ast so these tests need neither Pillow nor ARTEMIS/pytest.
"""
import ast
import copy
import hashlib
import json
import os
from pathlib import Path
import shlex
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parent.parent


def helpers(file, names, **namespace):
    tree = ast.parse((ROOT / file).read_text(encoding="utf-8"))
    tree.body = [node for node in tree.body
                 if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in names]
    exec(compile(tree, file, "exec"), namespace)
    return SimpleNamespace(**namespace)


class ReviewHelpersTest(unittest.TestCase):
    def test_wrap_omits_blank_lines_and_keeps_long_words(self):
        module = helpers("tools/video/make_videos.py", {"wrap"})
        draw = SimpleNamespace(textlength=lambda text, font: len(text))
        self.assertEqual(module.wrap(draw, "\nlongword\n\na b\n", None, 3), ["longword", "a b"])

    def test_duration_matches_mapper(self):
        module = helpers("tools/video/make_videos.py", {"step_duration"})
        for step in ({}, {"durationSeconds": None}, {"durationSeconds": 0}, {"durationSeconds": -1}):
            self.assertEqual(module.step_duration(step), 10)
        self.assertEqual(module.step_duration({"durationSeconds": 7}), 7)

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
        module = helpers("e2e_test/conftest.py", {"adb_input_text"}, adb=adb, shlex=shlex)
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
