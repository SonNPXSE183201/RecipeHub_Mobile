import os

import pytest
from artemis_client import ArtemisClient

from conftest import output, run_case, wait_operator_signal

pytestmark = pytest.mark.slow


async def test_tc21_remote_config_live_limit(signed_in_viewer: ArtemisClient) -> None:
    # Record the actual Console value for EACH run, rather than assuming a default.
    recorded = await wait_operator_signal("tc21-baseline",
        "Read current max_lookup_results in Firebase Console. Write its positive integer "
        "value into the matching tc21-baseline-done file; do not change it yet.")
    try:
        initial_limit = int(recorded.strip())
    except ValueError:
        pytest.fail("tc21-baseline-done must contain the original integer limit", pytrace=False)
    assert initial_limit > 0
    target = 2 if initial_limit == 1 else 1
    result = await run_case(signed_in_viewer, "TC-21",
        "Start at Lookup. Clear search, select all categories, count ALL recipe cards by scrolling. "
        'Return {"baseline_count":0} with the observed count.')
    assert result.succeeded, result.error or result.status
    baseline = output(result)["baseline_count"]
    assert baseline > 0 and baseline != target, "Need a distinct visible baseline"
    try:
        await wait_operator_signal("tc21",
            f"Publish max_lookup_results={target} NOW. Keep app foreground; confirm in tc21-done.")
        result = await run_case(signed_in_viewer, "TC-21",
            f"Keep the same foreground Lookup. Wait up to 90 seconds for realtime config; "
            f"verify exactly {target} cards. Never restart, navigate away, sync or reload. "
            'Return {"count":0,"restart_used":false,"manual_reload_used":false} with observed count.')
        assert result.succeeded, result.error or result.status
        assert output(result) == {"count": target, "restart_used": False, "manual_reload_used": False}
    finally:
        await wait_operator_signal("tc21-restore",
            f"Restore the EXACT original max_lookup_results={initial_limit}, publish, "
            f"then confirm in tc21-restore-done before the next round.")


async def test_tc22_admin_personal_features_hidden(signed_in_admin: ArtemisClient) -> None:
    result = await run_case(signed_in_admin, "TC-22",
        "Start at Lookup as Store Admin. Verify 'Tự luyện quầy bar' FAB (self_practice_fab) "
        "is absent. Verify second bottom tab is 'Đào tạo' and 'Việc học' is absent. Open 'Tài khoản', "
        "scroll the entire screen; verify 'Tiến độ đào tạo cá nhân' and 'Lịch sử tự luyện với Timer' "
        "are absent. Return {\"admin_restrictions_verified\":true,\"personal_learning_hidden\":true,"
        '"fab_hidden":true,"second_tab":"Đào tạo"}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"admin_restrictions_verified": True, "personal_learning_hidden": True,
                              "fab_hidden": True, "second_tab": "Đào tạo"}
