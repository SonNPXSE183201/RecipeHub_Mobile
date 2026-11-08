import pytest
from artemis_client import ArtemisClient

from conftest import adb, app_package, output, run_case

pytestmark = pytest.mark.slow


async def test_tc07_search_has_results(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-07",
        "Start at 'Tra cứu tại quầy'. Enter 'Trà Sữa' in 'Tìm theo tên món...' (lookup_search). "
        "Verify filtering and matching recipe cards including 'Trà Sữa Oolong'. Count all matches "
        "using the result count/scrolling, not just visible cards. "
        'Return {"query":"Trà Sữa","results_count":0,"first_item_name":"","matches_only":true}, replacing count/name with observations.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["query"] == "Trà Sữa"
    assert type(data["results_count"]) is int and data["results_count"] > 0
    assert data["first_item_name"] and data["matches_only"] is True


async def test_tc08_search_empty_state(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-08",
        "Start at Lookup, enter 'MonKhongTonTai999' in 'Tìm theo tên món...'. Verify no recipe cards, "
        "title 'Không tìm thấy công thức phù hợp' and subtitle 'Thử đổi từ khóa hoặc bộ lọc danh mục.'. "
        'Return {"empty_state_shown":true,"title":"Không tìm thấy công thức phù hợp","subtitle_shown":true,"results_count":0}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"empty_state_shown": True, "title": "Không tìm thấy công thức phù hợp",
                              "subtitle_shown": True, "results_count": 0}


async def test_tc09_offline_retry(signed_in_viewer: ArtemisClient, request: pytest.FixtureRequest) -> None:
    # Activate only after login. Its finalizer restores both radios even on a failed assertion.
    request.getfixturevalue("offline")
    adb("shell", "am", "force-stop", app_package())
    adb("shell", "monkey", "-p", app_package(), "1")
    result = await run_case(signed_in_viewer, "TC-09",
        "The app has been reopened offline after Viewer login. Wait for recipe loading to finish. "
        "Trigger reload if available. Verify an error containing 'Không tải được công thức' and "
        "'Thử lại'. A cached recipe list does not satisfy the error assertion. "
        'Return {"error_shown":true,"retry_visible":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"error_shown": True, "retry_visible": True}
    adb("shell", "svc", "wifi", "enable")
    adb("shell", "svc", "data", "enable")
    result = await run_case(signed_in_viewer, "TC-09",
        "Start at the offline error screen. Network is now enabled by the host. Tap 'Thử lại', "
        "wait for recipe cards. Verify error disappears and a nonempty list loads. "
        'Return {"error_resolved":true,"status":"ready","results_count":0} with the observed count.')
    assert result.succeeded, result.error or result.status
    assert output(result)["error_resolved"] is True
    assert output(result)["status"] == "ready"
    assert output(result)["results_count"] > 0


async def test_tc10_bottom_tabs(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-10",
        "Start at Lookup. Successively tap bottom tabs 'Tra cứu', 'Việc học', 'Phản hồi', 'Tài khoản'. "
        "At each stop wait for data and verify its matching screen content/AppBar, finally "
        "'Tài khoản & Phân quyền'. "
        'Return {"tabs_verified":["Tra cứu","Việc học","Phản hồi","Tài khoản"],"status":"pass"}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"tabs_verified": ["Tra cứu", "Việc học", "Phản hồi", "Tài khoản"], "status": "pass"}
