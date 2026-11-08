"""Device fixtures and a redacted, one-row-per-case JSONL journal (sequential only)."""
from __future__ import annotations

import asyncio
import json
import os
import re
import subprocess
import time
from collections.abc import Generator, Iterator
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal, cast

import pytest
from artemis_client import ArtemisClient
from artemis_client.models import TaskResult
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env")
RUN_ID = os.getenv("RUN_ID") or datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
if not re.fullmatch(r"[A-Za-z0-9_.-]+", RUN_ID) or RUN_ID in {".", ".."}:
    raise ValueError("RUN_ID must be a filename, without directory separators")
JOURNAL = ROOT / "results" / f"{RUN_ID}.jsonl"
_secrets: set[str] = {v for k, v in os.environ.items() if "PASSWORD" in k and v}
_active: dict[str, Any] | None = None


def required(name: str) -> str:
    value = os.getenv(name, "")
    if not value.strip():
        pytest.skip(f"Missing environment variable: {name}")
    return value


def secret(value: str) -> str:
    _secrets.add(value)
    return value


def redact(value: Any) -> Any:
    if isinstance(value, str):
        for password in sorted(_secrets, key=len, reverse=True):
            variants = {password}
            for ascii_only in (True, False):
                encoded = password
                for _ in range(3):
                    encoded = json.dumps(encoded, ensure_ascii=ascii_only)[1:-1]
                    variants.add(encoded)
            for encoded in sorted(variants, key=len, reverse=True):
                value = value.replace(encoded, "***")
        return value
    if isinstance(value, dict):
        return {redact(k): redact(v) for k, v in value.items()}
    if isinstance(value, (tuple, list)):
        return [redact(v) for v in value]
    return value


def adb(*args: str) -> str:
    command = ["adb", "-s", required("ANDROID_SERIAL"), *args]
    process = subprocess.run(command, capture_output=True, text=True, encoding="utf-8",
                             errors="replace", timeout=60, check=False)
    if process.returncode:
        pytest.fail(redact(f"adb failed: {process.stderr or process.stdout}"), pytrace=False)
    return process.stdout


def app_package() -> str:
    return os.getenv("RH_APP_PACKAGE", "com.recipehub.mobile")


def output(result: TaskResult) -> dict[str, Any]:
    value = result.output
    if isinstance(value, str):
        text = value.strip()
        if text.startswith("```json") and text.endswith("```"):
            text = text[7:-3].strip()
        elif text.startswith("```") and text.endswith("```"):
            text = text[3:-3].strip()
        try:
            value = json.loads(text)
        except ValueError:
            pytest.fail("ARTEMIS output is not a JSON object", pytrace=False)
    if not isinstance(value, dict):
        pytest.fail("ARTEMIS output must be a JSON object", pytrace=False)
    return value


async def execute(artemis: ArtemisClient, instruction: str) -> TaskResult:
    """Only SDK-supported output options; this client has no JSON-schema argument."""
    try:
        result = await artemis.run(
            instruction + " Return only the requested JSON object. Report only observed evidence; "
            "never invent success, data or missing controls. Never return credentials.",
            enable_outputter=True,
            expected_output="A JSON object with the fields explicitly requested in the goal; "
                            "booleans as JSON booleans, counts as integers, no Markdown or secrets.",
        )
    except Exception as exc:
        pytest.fail(redact(f"ARTEMIS {type(exc).__name__}: {exc}"), pytrace=False)
    # A failed pytest assertion must not expose the original goal through dataclass repr.
    return replace(result, goal=redact(result.goal), output=redact(result.output),
                   error=redact(result.error), raw={})


async def run_case(artemis: ArtemisClient, tc_id: str, instruction: str) -> TaskResult:
    """Run and write a row, updated after assertions/teardown without duplicate rows."""
    assert _active is not None and _active["tc_id"] == tc_id
    result = await execute(artemis, instruction)
    _active["trace_id"] = result.trace_id
    _active["traces"].append(result.trace_id)
    _active["succeeded"] = _active["succeeded"] and result.succeeded
    if result.error or not result.succeeded:
        _active["error"] = result.error or result.status
    _active["output"] = result.output
    _write_active()
    return result


def _write_active() -> None:
    assert _active is not None
    JOURNAL.parent.mkdir(exist_ok=True)
    if "journal_offset" not in _active:
        _active["journal_offset"] = JOURNAL.stat().st_size if JOURNAL.exists() else 0
    row = {key: value for key, value in _active.items() if key not in {"started", "journal_offset"}}
    row["duration_s"] = round(time.monotonic() - _active["started"], 3)
    row.setdefault("status", "passed" if row["succeeded"] else "failed")
    payload = (json.dumps(redact(row), ensure_ascii=False) + "\n").encode("utf-8")
    with JOURNAL.open("r+b" if JOURNAL.exists() else "w+b") as stream:
        stream.seek(_active["journal_offset"])
        stream.write(payload)
        stream.truncate()


def pytest_itemcollected(item: pytest.Item) -> None:
    # Add aliases before pytest's built-in -k deselection hook runs.
    match = re.search(r"test_tc(\d{2})_", item.name)
    if match:
        item.extra_keyword_matches.add(f"TC-{match[1]}")


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item: pytest.Item, call: pytest.CallInfo[Any]) -> Generator[None, Any, None]:
    global _active
    outcome = yield
    report = outcome.get_result()
    if _active is None:
        return
    if report.failed or report.skipped:
        _active["succeeded"] = False
        _active["error"] = redact(str(report.longrepr))
        _active["status"] = "skipped" if report.skipped else "failed"
    if report.when == "teardown":
        _write_active()
        _active = None


@pytest.hookimpl(hookwrapper=True, tryfirst=True)
def pytest_runtest_setup(item: pytest.Item) -> Iterator[None]:
    global _active
    match = re.search(r"test_tc(\d{2})_", item.name)
    if match:
        _active = {"tc_id": f"TC-{match[1]}", "succeeded": True, "started": time.monotonic(),
                   "trace_id": None, "error": None, "output": None, "traces": []}
    yield


@pytest.fixture
def artemis() -> ArtemisClient:
    profile = os.getenv("ARTEMIS_PROFILE", "flash")
    if profile not in {"flash", "pro"}:
        pytest.fail("ARTEMIS_PROFILE must be flash or pro", pytrace=False)
    return ArtemisClient(os.getenv("ARTEMIS_URL", "http://127.0.0.1:8000"),
                         device_serial=required("ANDROID_SERIAL"),
                         default_profile=cast(Literal["flash", "pro"], profile))


@pytest.fixture
def fresh_app() -> None:
    package = app_package()
    adb("shell", "am", "force-stop", package)
    cleared = adb("shell", "pm", "clear", package)
    assert "Success" in cleared, "pm clear did not succeed"
    (ROOT / "results" / ".session").unlink(missing_ok=True)
    adb("shell", "monkey", "-p", package, "1")


def viewer_login(suffix: str = "") -> str:
    email = required(f"RH_VIEWER{suffix}_EMAIL")
    password = secret(required(f"RH_VIEWER{suffix}_PASSWORD"))
    return (f"At the Login screen enter email {json.dumps(email)} and password {json.dumps(password)} "
            "in the Email and 'Mật khẩu' fields, tap 'Đăng nhập'. Dismiss 'Bật thông báo?' "
            "with 'Để sau' if necessary. Verify 'Tra cứu tại quầy' and the Barista role. ")


def admin_login() -> str:
    account = required("RH_ADMIN_GOOGLE_ACCOUNT")
    return ("At Login tap 'Đăng nhập với Google'; in the Android system account picker select "
            f"exactly {json.dumps(account)}. Never select a different account. "
            "Dismiss 'Bật thông báo?' with 'Để sau' if needed. Verify Store Admin role and 'Đào tạo' tab. ")


LOGOUT = ("Open 'Tài khoản', tap 'Đăng xuất khỏi quầy bar', confirm 'Đăng xuất', "
          "and verify the Login screen. ")


async def sign_in(artemis: ArtemisClient, instruction: str) -> ArtemisClient:
    result = await execute(artemis, instruction + 'Return {"authenticated": true}.')
    assert result.succeeded, result.error or result.status
    assert output(result)["authenticated"] is True
    return artemis


# Free-tier Gemini quota is tiny, and the agent types unreliably into Flutter text
# fields. With ADB_LOGIN=1 the viewer fixtures sign in deterministically over adb
# (coordinates measured on Redmi 7, 720x1520) so model calls go to the case under test.
# With E2E_REUSE_SESSION=1 a signed-in viewer session is kept between cases.
_SESSION_FILE = ROOT / "results" / ".session"
_LOGIN_POINTS = {"email": (400, 660), "password": (380, 848), "submit": (360, 1134)}


def _type_field(point: tuple[int, int], text: str) -> None:
    adb("shell", "input", "tap", str(point[0]), str(point[1]))
    time.sleep(0.5)
    adb("shell", "input", "keyevent", "KEYCODE_MOVE_END")
    for _ in range(45):
        adb("shell", "input", "keyevent", "KEYCODE_DEL")
    adb("shell", "input", "text", text)


def adb_viewer_login(suffix: str = "") -> None:
    package = app_package()
    adb("shell", "am", "force-stop", package)
    adb("shell", "pm", "clear", package)
    adb("shell", "monkey", "-p", package, "1")
    time.sleep(8)
    _type_field(_LOGIN_POINTS["email"], required(f"RH_VIEWER{suffix}_EMAIL"))
    _type_field(_LOGIN_POINTS["password"], required(f"RH_VIEWER{suffix}_PASSWORD"))
    adb("shell", "input", "keyevent", "KEYCODE_BACK")
    time.sleep(1)
    tx, ty = _LOGIN_POINTS["submit"]
    adb("shell", "input", "tap", str(tx), str(ty))
    time.sleep(8)


async def _viewer(artemis: ArtemisClient, suffix: str) -> ArtemisClient:
    package = app_package()
    if os.getenv("ADB_LOGIN") == "1":
        tag = f"viewer{suffix}"
        reuse = os.getenv("E2E_REUSE_SESSION") == "1"
        if reuse and _SESSION_FILE.exists() and _SESSION_FILE.read_text() == tag:
            adb("shell", "am", "force-stop", package)
            adb("shell", "monkey", "-p", package, "1")
            time.sleep(6)
        else:
            adb_viewer_login(suffix)
            _SESSION_FILE.parent.mkdir(exist_ok=True)
            _SESSION_FILE.write_text(tag)
        return artemis
    adb("shell", "am", "force-stop", package)
    adb("shell", "pm", "clear", package)
    adb("shell", "monkey", "-p", package, "1")
    return await sign_in(artemis, viewer_login(suffix))


@pytest.fixture
async def signed_in_viewer(artemis: ArtemisClient) -> ArtemisClient:
    return await _viewer(artemis, "")


@pytest.fixture
async def signed_in_viewer_b(artemis: ArtemisClient) -> ArtemisClient:
    return await _viewer(artemis, "_B")


@pytest.fixture
async def signed_in_admin(artemis: ArtemisClient, fresh_app: None) -> ArtemisClient:
    return await sign_in(artemis, admin_login())


@pytest.fixture
def analytics_debug() -> Iterator[None]:
    adb("shell", "setprop", "debug.firebase.analytics.app", app_package())
    try:
        yield
    finally:
        adb("shell", "setprop", "debug.firebase.analytics.app", ".none.")


@pytest.fixture
def offline() -> Iterator[None]:
    try:
        adb("shell", "svc", "wifi", "disable")
        adb("shell", "svc", "data", "disable")
        yield
    finally:
        try:
            adb("shell", "svc", "wifi", "enable")
        finally:
            adb("shell", "svc", "data", "enable")


async def wait_operator_signal(case: str, detail: str, timeout: float = 180) -> None:
    """Wait for a Console operator after writing a ready file; never simulate a publish."""
    directory = ROOT / "results"
    directory.mkdir(exist_ok=True)
    ready = directory / f"{RUN_ID}.{case}-ready"
    done = directory / f"{RUN_ID}.{case}-done"
    done.unlink(missing_ok=True)
    ready.write_text(detail, encoding="utf-8")
    deadline = time.monotonic() + timeout
    try:
        while not done.exists():
            if time.monotonic() >= deadline:
                pytest.fail(f"Operator did not confirm {case} within {timeout:g}s; see {ready.name}", pytrace=False)
            await asyncio.sleep(1)
    finally:
        ready.unlink(missing_ok=True)
        done.unlink(missing_ok=True)
