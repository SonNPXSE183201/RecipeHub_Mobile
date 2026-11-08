import re

import pytest
from artemis_client import ArtemisClient

from conftest import output, run_case

pytestmark = pytest.mark.slow


async def test_tc14_sop_pdf(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-14",
        "Start at Lookup. Open 'Tài khoản' then 'Sổ tay SOP'. Verify 'Sổ tay công thức & SOP' "
        "opens with the 3D flip book; flip a page then tap AppBar 'Mục lục'. Verify page 2/table "
        "of contents. Tap 'Xuất PDF', wait for SnackBar 'Đã lưu: Download/RecipeHub/...'. "
        'Return {"sop_book_opened":true,"toc_page":2,"pdf_exported":true,"path":""} with the actual saved path.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["sop_book_opened"] is True and data["toc_page"] == 2
    assert data["pdf_exported"] is True
    assert data["path"].startswith("Download/RecipeHub/") and data["path"].lower().endswith(".pdf")


async def test_tc15_complete_learning_task(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-15",
        "Start at Lookup, open 'Việc học', select a task marked 'Chưa học' (scroll the full list; fail clearly if none exists), and verify "
        "'Chi tiết nhiệm vụ học' with 'CÁC PHẦN CẦN HOÀN THÀNH'. Mark an incomplete section "
        "completed, complete remaining required read/watch sections and tap 'Hoàn thành'. "
        "Verify 'Đã xác nhận hoàn thành nội dung đọc/xem.' in the completion notice. "
        'Return {"task_detail_opened":true,"checklist_updated":true,"completed":true,"notice_shown":true}.')
    assert result.succeeded, result.error or result.status
    assert output(result) == {"task_detail_opened": True, "checklist_updated": True,
                              "completed": True, "notice_shown": True}


async def test_tc16_submit_quiz(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-16",
        "Start at Lookup, open 'Việc học'. Open quiz entry 'Làm bài Quiz', or open a quiz-enabled "
        "task and tap 'Làm quiz'. Select a quiz set, answer every question, tap 'Nộp bài kiểm tra'. "
        "Verify result score 'X / Y câu đúng', Đạt/Chưa đạt outcome and per-question explanations. "
        'Return {"quiz_submitted":true,"score":"","outcome_shown":true,"explanations_shown":true} with actual score.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["quiz_submitted"] is True
    assert re.search(r"\d+\s*/\s*\d+\s*câu đúng", data["score"])
    assert data["outcome_shown"] is True and data["explanations_shown"] is True


async def test_tc17_timer_and_report(signed_in_viewer: ArtemisClient) -> None:
    result = await run_case(signed_in_viewer, "TC-17",
        "Start at Lookup. Tap 'Tự luyện quầy bar' FAB (self_practice_fab). Select a recipe, "
        "tap 'Bấm giờ', wait at least 5 seconds, tap 'Tạm dừng', enter notes 'Test thực hành chuẩn', "
        "tap 'Lưu lần luyện tập'. Verify saved notice and open history using 'Lịch sử' or toolbar "
        "'Lịch sử tự luyện' if it does not open automatically. Verify the new entry and notes. "
        "Tap 'Xuất báo cáo PDF'; verify SnackBar 'Đã lưu: Download/RecipeHub/...'. "
        'Return {"timer_saved":true,"elapsed_seconds":0,"notes_verified":true,"report_exported":true,"path":""} with observed duration/path.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["timer_saved"] is True and data["elapsed_seconds"] >= 5
    assert data["notes_verified"] is True and data["report_exported"] is True
    assert data["path"].startswith("Download/RecipeHub/") and data["path"].lower().endswith(".pdf")


async def test_tc18_admin_evaluation(signed_in_admin: ArtemisClient) -> None:
    result = await run_case(signed_in_admin, "TC-18",
        "Start at Lookup as Store Admin. Open 'Đào tạo', tap 'Chấm ngay'. On the evaluation "
        "form choose a dedicated test Barista and recipe, toggle criteria switches, select "
        "'Đạt yêu cầu', enter comments 'ARTEMIS E2E observation', tap 'Lưu đánh giá thực hành tại quầy'. Verify "
        "success SnackBar and the saved evaluation in results. Do not evaluate a production employee. "
        'Return {"evaluation_saved":true,"trainee":"","saved_result_visible":true} with observed trainee name.')
    assert result.succeeded, result.error or result.status
    data = output(result)
    assert data["evaluation_saved"] is True and data["saved_result_visible"] is True
    assert isinstance(data["trainee"], str) and data["trainee"].strip()
