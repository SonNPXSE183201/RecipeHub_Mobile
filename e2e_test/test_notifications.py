import os

import pytest
from artemis_client import ArtemisClient

from conftest import adb, output, run_case, wait_operator_signal

pytestmark = pytest.mark.slow


@pytest.mark.manual
@pytest.mark.skipif(os.getenv("RH_FCM_SENT") != "1", reason="Set RH_FCM_SENT=1 and arrange a Console operator")
async def test_tc23_push_opens_notifications(signed_in_viewer: ArtemisClient) -> None:
    adb("shell", "input", "keyevent", "KEYCODE_HOME")
    # pm clear during setup invalidates old registration: send to the CURRENT token only now.
    await wait_operator_signal("tc23",
        "RecipeHub is backgrounded. Send FCM to its CURRENT registration token from Firebase Console: "
        "title='Cập nhật công thức', data type=recipe. Then create the matching tc23-done file.")
    adb("shell", "cmd", "statusbar", "expand-notifications")
    result = await run_case(signed_in_viewer, "TC-23",
        "Start at Android notification shade with RecipeHub in background. Find the NEW RecipeHub "
        "notification titled 'Cập nhật công thức' and tap it. Do not open via launcher or navigate "
        "manually inside the app. Verify app foregrounds directly at 'Thông báo & Thay đổi'. "
        'Return {"push_received":true,"navigated_screen":"notifications","direct_navigation":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"push_received": True, "navigated_screen": "notifications", "direct_navigation": True}
