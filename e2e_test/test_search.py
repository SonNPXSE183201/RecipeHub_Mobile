import pytest
from artemis_client import ArtemisClient

from conftest import output, run_case

pytestmark = pytest.mark.slow


async def test_tc07_search_has_results(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-07",
        "Start at 'Tra cứu tại quầy'. Enter 'long' in 'Tìm theo tên món...' (lookup_search). "
        "Verify filtering and matching recipe cards including 'Bòng Bưởi - Ô Long Bưởi Nha Đam'. Count all matches "
        "using the result count/scrolling, not just visible cards. "
        'Return {"query":"long","results_count":0,"first_item_name":"","matches_only":true,"target_found":true}, replacing count/name with observations.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["query"] == "long"
    assert type(data["results_count"]) is int and data["results_count"] > 0
    assert data["first_item_name"] and data["matches_only"] is True
    assert data["target_found"] is True


async def test_tc08_search_empty_state(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-08",
        "Start at Lookup, enter 'MonKhongTonTai999' in 'Tìm theo tên món...'. Verify no recipe cards, "
        "title 'Không tìm thấy công thức phù hợp' and subtitle 'Thử đổi từ khóa hoặc bộ lọc danh mục.'. "
        'Return {"empty_state_shown":true,"title":"Không tìm thấy công thức phù hợp","subtitle_shown":true,"results_count":0}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"empty_state_shown": True, "title": "Không tìm thấy công thức phù hợp",
                              "subtitle_shown": True, "results_count": 0}


@pytest.mark.manual
@pytest.mark.skip(reason="pm clear removes Auth session; offline fresh install stops at Login, not recipe error. Needs authenticated cache-free device setup")
async def test_tc09_offline_retry() -> None:
    pass


async def test_tc10_bottom_tabs(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-10",
        "Start at Lookup. Successively tap bottom tabs 'Tra cứu', 'Việc học', 'Phản hồi', 'Tài khoản'. "
        "At each stop wait for data and verify its matching screen content/AppBar, finally "
        "'Tài khoản & Phân quyền'. "
        'Return {"tabs_verified":["Tra cứu","Việc học","Phản hồi","Tài khoản"],"status":"pass"}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"tabs_verified": ["Tra cứu", "Việc học", "Phản hồi", "Tài khoản"], "status": "pass"}
