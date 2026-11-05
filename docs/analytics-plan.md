# Analytics plan – 7 sự kiện chuẩn (Firebase Analytics)

Quy ước: tên `snake_case` (≤ 40 ký tự); không PII (email, tên, SĐT, ảnh). `AnalyticsEvent.sanitize` lọc key PII và giá trị chứa `@` hoặc ≥ 9 chữ số.
User ID = Firebase `uid` (chuỗi ngẫu nhiên, không phải email). User property: `user_role`, `auth_mode`, `store_code`.

Luồng Lab 2 được gắn:
- **Flow 1 – Tra cứu tại quầy:** đăng nhập → danh sách công thức (M-02) → chi tiết (M-03).
- **Flow 2 – Tự luyện:** chi tiết → đồng hồ tự luyện (M-14) → lịch sử và báo cáo PDF (M-15).
- **Flow 3 – Tài khoản và phản hồi:** gửi phản hồi kèm ảnh (M-11), tài khoản và đăng xuất (M-13).

## Danh sách sự kiện

| # | Event | Thời điểm kích hoạt | Tham số (kiểu) | Câu hỏi sản phẩm | Luồng Lab 2 |
| :--: | :--- | :--- | :--- | :--- | :--- |
| 1 | `login` | Firebase Auth trả user thành công (Google hoặc khách) | `method`: string (`google`/`guest`), `user_role`: string (`viewer`/`admin`) | Barista dùng Google hay chế độ khách nhiều hơn? Có bao nhiêu Admin đăng nhập bằng điện thoại? | Flow 1 |
| 2 | `logout` | Người dùng xác nhận "Đăng xuất" | `user_role`: string, `session_minutes`: int | Một ca tra cứu kéo dài bao lâu? | Flow 3 |
| 3 | `view_recipe` | Mở màn chi tiết công thức (M-03) | `recipe_code`: string, `category`: string, `size`: string, `source`: string (hiện luôn là `lookup`) | Món nào được tra nhiều nhất tại quầy? Nhóm đồ uống nào được tra nhiều nhất? | Flow 1 |
| 4 | `start_brew_timer` | Lần bấm "Bấm giờ" đầu tiên (M-14) | `recipe_code`: string, `size`: string, `target_seconds`: int | Món nào được Barista tự luyện nhiều nhất? | Flow 2 |
| 5 | `complete_brew_timer` | Dừng đồng hồ và lưu phiên tự luyện | `recipe_code`: string, `size`: string, `actual_seconds`: int, `deviation_seconds`: int, `within_tolerance`: bool | Barista có pha kịp thời gian chuẩn không? Món nào hay bị lệch giờ? | Flow 2 |
| 6 | `submit_feedback` | Gửi phản hồi thành công (M-11), sau khi upload ảnh (nếu có) | `feedback_type`: string (tên loại phản hồi), `target_type`: string (`recipe`/`sop`), `target_code`: string, `has_attachment`: bool | Công thức nào bị báo lỗi nhiều nhất? Bao nhiêu phản hồi có kèm ảnh? | Flow 3 |
| 7 | `export_report_pdf` | Upload PDF báo cáo lên `reports/{uid}/` thành công (M-15) | `report_type`: string (`practice_history`), `record_count`: int, `file_size_kb`: int | Quản lý có dùng báo cáo tự luyện không? File PDF có quá lớn không? | Flow 2 |

## Kiểm chứng

1. `adb shell setprop debug.firebase.analytics.app com.recipehub.mobile` rồi mở Firebase Console → DebugView.
2. Đọc log trên máy: `adb shell setprop log.tag.FA-SVC VERBOSE`, lọc dòng `Logging event: origin=app`.
3. Kết quả chạy trên Redmi 7 (05/11/2026) ghi trong `docs/artemis-test-plan.md`.
