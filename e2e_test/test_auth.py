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


async def test_tc04_admin_request_falls_back(artemis: ArtemisClient, fresh_app: None) -> None:
    result = await run_case(artemis, "TC-04",
        "Start at Login with a server Viewer account. Select/request Admin before signing in. "
        "If no UI allows requesting Admin, report this case as unsuccessful; do not substitute normal Viewer login. " +
        viewer_login() + "Verify notice 'Tài khoản chưa được cấp quyền Admin – đang dùng vai trò Barista.' "
        'and applied Viewer role. Return {"authenticated":true,"applied_role":"viewer","notice_shown":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"authenticated": True, "applied_role": "viewer", "notice_shown": True}


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


async def test_tc24_change_password_and_logout(signed_in_viewer: ArtemisClient) -> None:
    old = secret(required("RH_VIEWER_PASSWORD"))
    new = secret(secrets.token_urlsafe(18) + "aA1!")
    result = None
    restored = False
    try:
        result = await run_case(signed_in_viewer, "TC-24",
            "Start at Lookup, open 'Tài khoản' then 'Đổi mật khẩu tài khoản'. Enter "
            f"{json.dumps(old)} in 'Mật khẩu hiện tại', {json.dumps(new)} in 'Mật khẩu mới' "
            "and 'Nhập lại mật khẩu mới', tap 'Đổi mật khẩu'. Verify 'Đã đổi mật khẩu thành công.'. "
            "For repeatability, change the password back using the same form: current "
            f"{json.dumps(new)}, new and confirmation {json.dumps(old)}; verify success again. " +
            LOGOUT + 'Return {"password_changed":true,"password_restored":true,"logged_out":true,"current_screen":"login"}.')
        assert result.succeeded, result.error or result.status
        data = output(result)
        restored = data.get("password_restored") is True
        assert data == {"password_changed": True, "password_restored": True,
                        "logged_out": True, "current_screen": "login"}
    finally:
        if not restored:
            recovery = await execute(signed_in_viewer,
                "Recover the dedicated test account password. If logged out, try email " +
                json.dumps(required("RH_VIEWER_EMAIL")) + f" with password {json.dumps(new)}; "
                f"if rejected try {json.dumps(old)}. In Account change password back to "
                f"{json.dumps(old)} if the temporary password is active. Verify restored credentials "
                'by logging in, then log out. Return {"restored":true}.')
            assert recovery.succeeded, recovery.error or recovery.status
            assert output(recovery)["restored"] is True
