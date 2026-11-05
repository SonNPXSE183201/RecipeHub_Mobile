# ARTEMIS – kế hoạch và kết quả kiểm thử trên thiết bị

- **Thiết bị:** Xiaomi Redmi 7, Android 10 (API 29), 720×1520
- **Backend:** Docker local (Gateway + Recipe service + PostgreSQL), nối qua `adb reverse tcp:5000 tcp:5000`
- **Firebase:** project `recipehub-mobile`
- **Bản build:** debug APK, `--dart-define=API_BASE_URL=http://127.0.0.1:5000 --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>`
- **Cách chạy:** runner Python điều khiển máy qua `adb` (chạm, nhập, chụp màn hình, đọc logcat), gọi Storage API và Firebase CLI. Mỗi ca chỉ ĐẠT khi **giá trị quan sát được** đúng: event Analytics và tham số trong log `FA-SVC`, object mới trên Storage, mã món được mở, màn hình hiện tại (so vùng ảnh với ảnh tham chiếu). Runner và log nằm ngoài repo (thư mục scratchpad của phiên làm việc); ảnh và log chính được trích vào báo cáo.
- **Test Flutter:** 15 ca trong `test/artemis_e2e_test.dart` (TC-01 → TC-13) bổ trợ cho bộ này, không thay thế.

Luồng Lab 2: **Flow 1** tra cứu tại quầy (đăng nhập → danh sách → chi tiết), **Flow 2** tự luyện (bấm giờ → lịch sử → PDF), **Flow 3** phản hồi và tài khoản.

## 10 ca kiểm thử

| Mã | Luồng | Điều kiện đầu | Bước | Kết quả mong đợi (kiểm tra tự động) |
| :-- | :-- | :-- | :-- | :-- |
| ART-01 | Flow 1 | Đang ở màn đăng nhập, có mạng, máy có tài khoản Google | Chạm "Tiếp tục với Google" → chọn tài khoản | Event `login` {method=google, user_role=viewer}, không PII; màn Tra cứu hiện ra. Cuối lượt: Tài khoản → Đăng xuất → xác nhận → event `logout` có `session_minutes`, về màn đăng nhập |
| ART-02 | Flow 1, nhánh lỗi | Màn đăng nhập | Chạm Google → Back trong hộp chọn tài khoản (**tương tác Android gốc**) | Vẫn ở màn đăng nhập; không có event `login` |
| ART-03 | Flow 1, nhánh lỗi | Màn đăng nhập | Tắt Wi-Fi + dữ liệu → Google → chọn tài khoản | Vẫn ở màn đăng nhập; log có `AuthFailureCode.network`; không có `login`; bật lại mạng |
| ART-04 | Flow 1 | Đã đăng nhập, danh sách đã tải | Chạm thẻ công thức đầu tiên | Event `view_recipe` {recipe_code=CF-COLDBREW, source=lookup} |
| ART-05 | Flow 1, nhánh lỗi | Đã đăng nhập | `docker stop recipehub-gateway` → mở lại app → bật Gateway → "Thử lại" | Màn lỗi "Không tải được công thức"; sau Thử lại về màn Tra cứu |
| ART-06 | Flow 2 | Đang ở chi tiết CF-COLDBREW | "Tự luyện món này" → Bấm giờ ~6 giây → Dừng → Lưu | `start_brew_timer` {target_seconds=30}; `complete_brew_timer` với `actual_seconds` lệch ≤ 1,5 s so với thời gian đo; màn Lịch sử |
| ART-07 | Flow 3 | Đã đăng nhập | Phản hồi → Gửi phản hồi → nhập nội dung → Thư viện (**picker hệ thống**) → chọn ảnh ~4,9 MB → Gửi | Có thanh tiến độ; event `submit_feedback` {has_attachment=true}; số object trong `feedback/` tăng 1 |
| ART-08 | Flow 2 | Đang ở Lịch sử tự luyện | Chạm icon PDF | Event `export_report_pdf` {file_size_kb>0}; số object trong `reports/` tăng 1 |
| ART-09 | Flow 1, FCM | Đã đăng nhập, app chạy nền | Gửi FCM HTTP v1 `{type: recipe, target_id: <mã>}` → mở khay thông báo (**tương tác Android gốc**) → chạm | Mở đúng chi tiết món: `view_recipe.recipe_code` = mã đã gửi |
| ART-10 | Flow 1, Remote Config | Đã đăng nhập, ở màn Tra cứu | Deploy `max_lookup_results` mới bằng Firebase CLI, không khởi động lại app | Trong ≤ 4 phút, món cuối danh sách đổi đúng (3 → TT-DAOCAMSA; 50 → TS-OOLONG) |

## Kết quả

Lượt 1–3: bản build trước khi sửa lỗi deep link. Lượt 4–6: bản đã sửa lỗi 1. Lượt 7–10: bản đã sửa lỗi 1 và 2. Lượt 11–14: bản cuối, đã sửa thêm lỗi tải lại khi tăng giới hạn.

| Ca | Lượt 1 | Lượt 2 | Lượt 3 | Chạy lại | Tỷ lệ đạt (lượt 1–3) | Ghi chú |
| :-- | :-: | :-: | :-: | :-- | :-: | :-- |
| ART-01 | Đạt | Rớt | Rớt | L4 Đạt, L5 Rớt, L6 Đạt; L7–L10 Đạt | 1/3 | Lỗi app: thông báo đã mở bị xử lý lại khi đăng nhập lại (L2, L3: mở trang Thông báo; L5: mở lại Cà Phê Muối). Sửa ở `NotificationViewModel`, test TC-12. Đăng xuất đạt ở mọi lượt có chạy |
| ART-02 | Đạt | Đạt | Đạt | L10 Đạt | 3/3 | |
| ART-03 | Đạt | Rớt | Đạt | L4, L5 Đạt; L6 Rớt; L7–L10 Đạt | 2/3 | Rớt do kịch bản: khi mất mạng, hộp chọn tài khoản hiện chậm hơn 7 s nên lần chạm bị hụt. Đã sửa runner chờ dòng tài khoản hiện ra |
| ART-04 | Đạt | Đạt | Đạt | L10 Đạt | 3/3 | |
| ART-05 | Đạt | Đạt | Đạt | L10 Đạt | 3/3 | |
| ART-06 | Đạt | Đạt | Đạt | L10 Đạt | 3/3 | `actual_seconds` khớp thời gian đo (6 s so với 6,8 s) |
| ART-07 | Đạt* | Đạt | Đạt | L10 Rớt; L11–L14: xem dưới | 3/3 | *Lượt 1 chạy lại sau khi sửa runner (bàn phím bật lại sau khi quay về từ picker). L10 rớt do kịch bản: chạm vào ảnh trong picker bị hụt |
| ART-08 | Đạt | Đạt | Đạt | L10 Đạt | 3/3 | |
| ART-09 | Đạt | Rớt | Đạt | L4–L10 Đạt (7/7) | 2/3 | Lỗi app: món nằm ngoài danh sách bị giới hạn bởi `max_lookup_results` → mở trang Thông báo. Sửa ở `DeepLinkRouter` + `RecipeViewModel.findForDeepLink`, test TC-11 |
| ART-10 | Đạt (50→3) | Rớt (3→50) | Đạt (50→3) | L10 Rớt (3→50); L11–L14: xem dưới | 2/3 | Lỗi app: tăng giới hạn không tải thêm món (chỉ tải đúng số món theo giới hạn cũ). Sửa: `RecipeViewModel.applyLimit` + `AuthGate` nghe `AppConfigViewModel`, test TC-13 |

**Tổng lượt 1–3:** 25/30 ca đạt (83%). 3 lỗi thật của app (ART-01, ART-09, ART-10), 1 lỗi kịch bản (ART-03 lượt 2).

### Hồi quy lỗi Remote Config (lượt 11–24)

| Lượt | Bản build | Hướng đổi | Kết quả | Ghi chú |
| :-- | :-- | :-- | :-- | :-- |
| 11 | Sửa lớp 1 (`applyLimit`) | 50 → 3 | Hủy | Runner thoát khỏi app (Back quá số lần), đã dừng và thêm chốt kiểm tra cửa sổ focus trước mọi lần chạm |
| 15, 17 | Sửa lớp 1 | 50 → 3 | Đạt, Đạt | |
| 16, 18 | Sửa lớp 1 | 3 → 50 | Rớt, Rớt | Log `[Recipe] applyLimit 50 … loaded=3 items=3`: đã tải lại nhưng màn hình không vẽ lại → lớp 2: View đọc `MockDataService` thay vì `watch` `RecipeViewModel` |
| 19, 21, 23 | Bản cuối (sửa cả 2 lớp) | 50 → 3 | Đạt ×3 | |
| 20, 24 | Bản cuối | 3 → 50 | Đạt ×2 | Lượt 24 có log: `realtime … max_lookup_results=50`, `applyLimit 50 … loaded=3 items=3`, danh sách lên 6 món sau 8 s |
| 22 | Bản cuối | 3 → 50 | Rớt | Danh sách vẫn 3 món sau 253 s; log lượt này bị xóa nên không xác định được real-time có tới hay không (một lần đo tay khác: real-time tới sau 2 phút 42 giây). Cửa sổ chờ đã nâng lên 8 phút |

**ART-10 trên bản cuối:** 5/6 đạt. Các ca khác chạy lại trên bản cuối: ART-01 ×6 đạt (lượt 19–24, kèm đăng xuất), ART-09 đạt ở lượt 7–10 (bản đã sửa deep link). ART-07 chưa chạy lại trên bản cuối (thay đổi cuối không đụng tới luồng phản hồi).

**Sự cố khi chạy:** ở lượt 11, runner thoát ra màn hình chính và chạm vào Dialer, Chrome trước khi bị dừng. Chốt an toàn hiện chỉ cho phép chạm khi cửa sổ focus là RecipeHub, picker hệ thống, hộp chọn tài khoản Google hoặc khay thông báo.

## Bằng chứng

- Ảnh chụp màn hình từng bước của mỗi lượt: `r<lượt>_<ca>*.png`, log `run<lượt>.log`, tổng hợp `results.json` (thư mục evidence/artemis của runner).
- Event Analytics thật trong log `FA-SVC` (ví dụ): `name=complete_brew_timer,params={within_tolerance=false, size=M, deviation_seconds=-24, recipe_code=CF-COLDBREW, actual_seconds=6}`.
- Object Storage kiểm tra bằng `GET https://firebasestorage.googleapis.com/v0/b/recipehub-mobile.firebasestorage.app/o?prefix=feedback/`.
- Kiểm thử khám phá: `docs/exploratory-testing-log.md`.
