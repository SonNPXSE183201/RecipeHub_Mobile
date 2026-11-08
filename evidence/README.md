# Evidence

Ảnh chụp trực tiếp trên Redmi 7 (Android 10) bằng `adb exec-out screencap -p`, bản APK release, dự án Firebase `recipehub-mobile`. Không chỉnh sửa nội dung; email của người khác đã được làm mờ.

| Thư mục | Nội dung | Ngày |
| :-- | :-- | :-- |
| `lab3/01-feedback-realtime/` | Gửi phản hồi có ảnh → Admin thấy ngay, mở chi tiết có ảnh, trả lời kèm đổi trạng thái | 2026-11-07 |
| `lab3/02-seed-real-data/` | Sau khi nạp dữ liệu thật: tra cứu, thư viện SOP, tìm món, định lượng theo size, giám sát đào tạo, tiêu chí chấm | 2026-11-07 |
| `lab3/03-round2-ui/` | Admin không còn tiến độ cá nhân / tự luyện, sổ tay SOP lật trang, video chuẩn phát thật | 2026-11-08 |
| `lab3/04-round3-ui/` | Ẩn mã món, Tài khoản có Sổ tay SOP, món chưa có video, video toàn màn hình, PDF sổ tay (133 trang) | 2026-11-08 |
| `lab3/05-round4-ui/` | Thẻ tra cứu mới, Theo dõi đào tạo không tràn chữ, Tài khoản Admin | 2026-11-08 |
| `lab3/06-firebase-console/` | Firebase Console (giao diện tiếng Anh) và thiết bị: Analytics events + log debug, Crashlytics, Remote Config (tham số + lịch sử phiên bản), Storage (file + rules), Authentication (email/UID đã làm mờ), FCM (báo cáo; test message tới Redmi 7 ở foreground / background / terminated; chạm mở đúng màn), Firestore | 2026-11-08 |

Ghi chú `06-firebase-console`:
- DebugView không hiện thiết bị dù log cho thấy event gửi kèm `_dbg` và upload trả về 204 (`01-analytics-debug-logcat.log`). Vì vậy dùng báo cáo Events của GA4 (`01-analytics-events.jpg`) làm minh chứng event.
- Token FCM trong ảnh Console đã làm mờ.
- Lượt chạy ARTEMIS sẽ được bổ sung theo test plan.
