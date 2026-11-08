import asyncio
import os
import re
import time

import pytest
from artemis_client import ArtemisClient

from conftest import adb, output, run_case

pytestmark = pytest.mark.slow


async def test_tc11_recipe_detail(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-11",
        "Start at Lookup. Search 'Trà Sữa Oolong' and open that exact card. Verify recipe name, "
        "'ĐỊNH LƯỢNG NGUYÊN LIỆU', nonempty ingredients for the selected size and "
        "'Quy cách phục vụ chuẩn:'. Switch size if available and verify amounts update. "
        'Return {"recipe_name":"Trà Sữa Oolong","detail_opened":true,"ingredients_count":0,"serving_note_shown":true} with observed count.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["recipe_name"] == "Trà Sữa Oolong" and data["detail_opened"] is True
    assert data["ingredients_count"] > 0 and data["serving_note_shown"] is True


async def test_tc12_step_video(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-12",
        "Start at Lookup, search and open 'Trà Sữa Oolong' detail, then 'Xem video chuẩn'. "
        "Verify loaded playable video and timeline 'Bước 1', 'Bước 2'. Select step 1, then tap "
        "'Bước tiếp theo'. Verify active step 2 and video seeks to its timeline position. "
        'Return {"video_guide_opened":true,"player_loaded":true,"active_step":2,"timeline_synced":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"video_guide_opened": True, "player_loaded": True,
                              "active_step": 2, "timeline_synced": True}


async def test_tc13_view_recipe_analytics(analytics_debug: None, signed_in_viewer: ArtemisClient) -> None:
    adb("logcat", "-c")
    result = await run_case(signed_in_viewer, "TC-13",
        "Start at Lookup. Search 'Cà Phê Muối' and open that recipe detail. Verify its name "
        "and ingredients. The host, not the UI agent, checks Analytics logcat. "
        'Return {"recipe_name":"Cà Phê Muối","detail_opened":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"recipe_name": "Cà Phê Muối", "detail_opened": True}
    deadline = time.monotonic() + 30
    event = ""
    while time.monotonic() < deadline:
        logs = adb("logcat", "-d", "-s", "FA-SVC")
        # Bound parameters to this event rather than matching unrelated log lines.
        event = next((line for line in logs.splitlines()
                      if re.search(r"\bname=view_recipe\b", line)), "")
        if event:
            break
        await asyncio.sleep(1)
    assert event, "FA-SVC did not log name=view_recipe within 30 seconds"
    for key in ("recipe_code", "category", "size"):
        assert re.search(rf"\b{key}=([^,}}\s]+)", event), f"Missing Analytics parameter {key}"
    assert re.search(r"\bsource=lookup\b", event), "Missing source=lookup"
    assert not re.search(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}|\b(?:email|phone|display_name|password|uid|user_id)=", event, re.I), "PII in Analytics event"
    for name in ("RH_VIEWER_EMAIL", "RH_VIEWER_PASSWORD", "RH_VIEWER_B_EMAIL", "RH_VIEWER_B_PASSWORD"):
        value = os.getenv(name)
        assert not value or value not in event, "Test credentials found in Analytics event"
