import pytest
from artemis_client import ArtemisClient

from conftest import RUN_ID, output, run_case, wait_operator_signal

pytestmark = pytest.mark.slow


async def test_tc21_remote_config_live_limit(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-21",
        "Start at Lookup. Clear search, select all categories, count all recipes using count/scrolling. "
        "Keep the app foreground on Lookup. Do not restart or sync configuration. "
        'Return {"baseline_count":0} with the actual count.')
    assert result.succeeded, result.error or result.status
    assert output(result)["baseline_count"] > 5, "Need baseline >5 to prove a live limit change"
    await wait_operator_signal("tc21",
        "Publish Firebase Remote Config max_lookup_results=5 NOW. Keep RecipeHub foreground. "
        f"After publish, create results/{RUN_ID}.tc21-done. Restore baseline (>5) after this case.")
    result = await run_case(signed_in_viewer, "TC-21",
        "Start on the same still-foreground Lookup screen after the operator published "
        "max_lookup_results=5. Wait up to 90 seconds for realtime config. Never restart, navigate "
        "away, tap sync or manually reload. Verify the unfiltered full list now has exactly 5 "
        "recipes (baseline was >5). Count all cards, not only the viewport. "
        'Return {"remote_config_applied":true,"count":5,"restart_used":false,"manual_reload_used":false}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"remote_config_applied": True, "count": 5,
                              "restart_used": False, "manual_reload_used": False}


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
