import json
import uuid

import pytest
from artemis_client import ArtemisClient

from conftest import LOGOUT, admin_login, output, run_case, viewer_login

pytestmark = pytest.mark.slow


async def test_tc19_feedback_image_admin_receives(signed_in_viewer: ArtemisClient) -> None:
    marker = "ARTEMIS-TC19-" + uuid.uuid4().hex[:12]
    result = await run_case(signed_in_viewer, "TC-19",
        "Start at Lookup as Barista A. Open 'Phản hồi', tap create feedback icon. Choose "
        "'Báo cáo vấn đề', enter detailed content " + json.dumps(marker + " Kiểm tra ảnh phản hồi tại quầy.") +
        ". Tap 'Thư viện', select the prepared nonprivate test image in the Android system media "
        "picker. Verify attachment preview, tap 'Gửi phản hồi', verify 'Đã gửi phản hồi thành công đến Quản lý Admin.'. " +
        LOGOUT + admin_login() + "Open 'Phản hồi'; without manual refresh wait for the live list "
        f"to show the exact new content {json.dumps(marker)}. Open it and verify the attached image renders. "
        'Return {"feedback_sent":true,"admin_received":true,"attachment_visible":true,"manual_refresh_used":false,"marker":' +
        json.dumps(marker) + '}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"feedback_sent": True, "admin_received": True,
                              "attachment_visible": True, "manual_refresh_used": False, "marker": marker}


async def test_tc20_feedback_owner_isolation(signed_in_viewer: ArtemisClient) -> None:
    # Establish A's record in this case, never depend on TC-19 or test order.
    marker = "ARTEMIS-TC20-" + uuid.uuid4().hex[:12]
    result = await run_case(signed_in_viewer, "TC-20",
        "Start at Lookup as Barista A. Open 'Phản hồi', create a 'Báo cáo vấn đề' feedback "
        "with content " + json.dumps(marker + " Private feedback by Barista A.") +
        ", submit 'Gửi phản hồi', verify success and that A can see its new item. " +
        LOGOUT + viewer_login("_B") + "Open 'Phản hồi'. Inspect the entire list by scrolling/loading "
        "all items, not just the first viewport. Verify every feedback belongs to B and no A item "
        f"including {json.dumps(marker)} is present. An empty list is valid only after loading finishes. "
        'Return {"a_feedback_created":true,"isolation_verified":true,"foreign_feedback_present":false,"all_items_checked":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"a_feedback_created": True, "isolation_verified": True,
                              "foreign_feedback_present": False, "all_items_checked": True}
