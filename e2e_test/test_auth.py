import json
import secrets

import pytest
from artemis_client import ArtemisClient

from conftest import LOGOUT, execute, output, required, run_case, secret, viewer_login

pytestmark = pytest.mark.slow


async def test_tc01_email_login(artemis: ArtemisClient, fresh_app: None) -> None:
    result = await run_case(artemis, "TC-01", viewer_login() +
        'Return {"status":"success","screen":"lookup","role":"viewer"}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"status": "success", "screen": "lookup", "role": "viewer"}


async def test_tc02_wrong_password(artemis: ArtemisClient, fresh_app: None) -> None:
    wrong = secret("WrongPass@2026")
    result = await run_case(artemis, "TC-02",
        f"Start at Login. Enter email {json.dumps(required('RH_VIEWER_EMAIL'))}, "
        f"password {json.dumps(wrong)}, tap 'Đăng nhập'. Verify the error SnackBar "
        "'Email hoặc mật khẩu không đúng.' and remain at Login. "
        'Return {"error_displayed":true,"message":"Email hoặc mật khẩu không đúng.","screen":"login"}.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["error_displayed"] is True
    assert data["message"] == "Email hoặc mật khẩu không đúng."
    assert data["screen"] == "login"


async def test_tc03_password_reset(artemis: ArtemisClient, fresh_app: None) -> None:
    result = await run_case(artemis, "TC-03",
        "Start at Login, tap 'Quên mật khẩu?', enter " + json.dumps(required("RH_VIEWER_EMAIL")) +
        " in the bottom sheet Email field, tap 'Gửi thư đặt lại'. Verify the submitted result "
        "(not just the initial explanatory text) is 'Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu.'. "
        'Return {"reset_requested":true,"confirmation":"Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu."}.')
    assert result.succeeded, result.error or result.status
    assert output(result)["reset_requested"] is True
    assert output(result)["confirmation"] == "Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu."


@pytest.mark.manual
@pytest.mark.skip(reason="Login has no Admin role request UI; validate fallback in Flutter AuthViewModel tests")
async def test_tc04_admin_request_falls_back() -> None:
    pass


async def test_tc05_google_viewer_login(artemis: ArtemisClient, fresh_app: None) -> None:
    result = await run_case(artemis, "TC-05",
        "Start at Login, tap 'Đăng nhập với Google'. In the Android system account picker choose " +
        json.dumps(required("RH_VIEWER_EMAIL")) + ". Verify authentication, 'Tra cứu tại quầy' "
        "and Viewer/Barista role, dismissing notification primer via 'Để sau' if shown. "
        'Return {"auth_method":"google","status":"authenticated","role":"viewer"}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"auth_method": "google", "status": "authenticated", "role": "viewer"}


async def test_tc06_cancel_google_picker(artemis: ArtemisClient, fresh_app: None) -> None:
    result = await run_case(artemis, "TC-06",
        "Start at Login, tap 'Đăng nhập với Google', wait for the Android system account picker, "
        "then press device Back without choosing an account. Verify Login remains and the SnackBar "
        "'Bạn đã hủy đăng nhập Google. Chưa có thay đổi nào.' appears. "
        'Return {"cancelled":true,"current_screen":"login","notice_shown":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"cancelled": True, "current_screen": "login", "notice_shown": True}


async def test_tc24_change_password_and_logout(artemis: ArtemisClient, fresh_app: None) -> None:
    email = required("RH_PASSWORD_TEST_EMAIL")
    old = secret(required("RH_PASSWORD_TEST_PASSWORD"))
    new = secret(secrets.token_urlsafe(18) + "aA1!")
    test_error = None
    try:
        result = await run_case(artemis, "TC-24",
            f"At Login enter email {json.dumps(email)} and password {json.dumps(old)}; tap Đăng nhập. "
            "Dismiss notification primer with Để sau if shown. "
            "Start at Lookup, open 'Tài khoản' then 'Đổi mật khẩu tài khoản'. Enter "
            f"{json.dumps(old)} in 'Mật khẩu hiện tại', {json.dumps(new)} in 'Mật khẩu mới' "
            "and 'Nhập lại mật khẩu mới', tap 'Đổi mật khẩu'. Verify 'Đã đổi mật khẩu thành công.'. "
            + LOGOUT + 'Return {"password_changed":true,"logged_out":true,"current_screen":"login"}.')
        assert result.succeeded, result.error or result.status
        data = output(result)
        assert data == {"password_changed": True,
                        "logged_out": True, "current_screen": "login"}
    except (Exception, pytest.fail.Exception) as exc:
        test_error = exc
        raise
    finally:
        try:
            recovery = await execute(artemis,
                "Recover the dedicated test account password. If logged out, try email " +
                json.dumps(email) + f" with password {json.dumps(new)}; "
                f"if rejected try {json.dumps(old)}. In Account change password back to "
                f"{json.dumps(old)} if the temporary password is active: current password is "
                f"{json.dumps(new)}, both new and confirmation fields are {json.dumps(old)}. Verify success. "
                "Verify restored credentials "
                'by logging in, then log out. Return {"restored":true}.')
            assert recovery.succeeded, recovery.error or recovery.status
            assert output(recovery)["restored"] is True
        except (Exception, pytest.fail.Exception) as recovery_error:
            if test_error is not None:
                raise BaseExceptionGroup("TC-24: test and password recovery both failed",
                                         [test_error, recovery_error]) from None
            raise
