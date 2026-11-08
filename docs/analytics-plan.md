# Kế hoạch Analytics – 8 sự kiện chuẩn trên Firebase Analytics

Tài liệu đặc tả các sự kiện theo dõi hành vi người dùng trên RecipeHub Mobile.

## Nguyên tắc & Quy ước bảo mật

- **Tên sự kiện**: `snake_case`, tối đa 40 ký tự, mang nghĩa rõ ràng.
- **Không PII (Personally Identifiable Information)**: Tuyệt đối không thu thập email, họ tên, số điện thoại, mật khẩu hoặc ảnh cá nhân.
- **Cơ chế lọc tự động**: `AnalyticsEvent.sanitize` tự động loại bỏ các tham số nhạy cảm hoặc chuỗi chứa ký tự `@` và dãy số $\ge 9$ chữ số liên tiếp.
- **Định danh người dùng**: `User ID` là chuỗi `uid` ngẫu nhiên do Firebase Auth cấp (không phải email hay mã nhân viên).
- **User Properties**:
  - `user_role`: Vai trò người dùng (`admin` / `viewer`).
  - `auth_mode`: Phương thức đăng nhập (`password` / `google` / `guest`).
  - `store_code`: Mã chi nhánh cửa hàng (ví dụ: `CN-QUAN1`).

---

## Luồng nghiệp vụ Lab 2 được gắn kết

- **Flow 1 – Tra cứu tại quầy**: Đăng nhập → Danh sách công thức (M-02) → Chi tiết công thức & bước (M-03).
- **Flow 2 – Tự luyện pha chế**: Chi tiết món → Đồng hồ bấm giờ tự luyện (M-14) → Lịch sử và xuất báo cáo PDF (M-15).
- **Flow 3 – Phản hồi & Quản lý**: Gửi phản hồi kèm ảnh (M-11) → Tài khoản, đổi mật khẩu và đăng xuất (M-13).

---

## Danh sách 8 sự kiện trong mã nguồn (`lib/`)

Toàn bộ 8 sự kiện được định nghĩa trong `IAnalyticsService` và gọi thực tế trong các ViewModel/View:

| # | Tên Event | Thời điểm kích hoạt trong code | Danh sách tham số & Kiểu | Câu hỏi sản phẩm trả lời | Luồng Lab 2 |
| :-: | :--- | :--- | :--- | :--- | :--- |
| 1 | `login` | Khi đăng nhập thành công qua Google, Email/Password, hoặc Khách (`AuthViewModel._onSignedIn`) | - `method`: string (`google`, `password`, `guest`)<br>- `user_role`: string (`admin`, `viewer`) | Tỷ lệ dùng Google, Email hay Khách? Có bao nhiêu Admin đăng nhập từ di động? | Flow 1 |
| 2 | `logout` | Khi người dùng xác nhận "Đăng xuất" tại màn Tài khoản (`AuthViewModel.signOut`) | - `user_role`: string (`admin`, `viewer`)<br>- `session_minutes`: int | Một ca tra cứu/luyện tập kéo dài bao lâu theo vai trò? | Flow 3 |
| 3 | `view_recipe` | Mở màn hình chi tiết công thức (`RecipeDetailSizePage.initState`) | - `recipe_code`: string<br>- `category`: string<br>- `size`: string<br>- `source`: string (`lookup`, `notification`) | Món/nhóm món nào được tra cứu nhiều nhất? Bao nhiêu lượt mở từ thông báo FCM so với tìm kiếm quầy? | Flow 1 |
| 4 | `start_brew_timer` | Lần bấm nút "Bấm giờ" đầu tiên trong màn tự luyện (`SelfPracticeTimerPage._toggleTimer`) | - `recipe_code`: string<br>- `size`: string<br>- `target_seconds`: int | Món nào được Barista chủ động tự luyện bấm giờ nhiều nhất? | Flow 2 |
| 5 | `complete_brew_timer` | Bấm "Lưu lần luyện tập" sau khi bấm giờ hoàn thành (`SelfPracticeTimerPage._savePracticeRecord`) | - `recipe_code`: string<br>- `size`: string<br>- `actual_seconds`: int<br>- `deviation_seconds`: int<br>- `within_tolerance`: bool | Barista pha có kịp thời gian chuẩn (dung sai ±5s) không? Món nào hay bị trễ giờ nhất? | Flow 2 |
| 6 | `submit_feedback` | Gửi thành công phản hồi lên Firestore, sau khi upload ảnh nếu có (`CreateFeedbackPage._submitFeedback`) | - `feedback_type`: string (`issue`, `inquiry`, `suggestion`)<br>- `target_type`: string (`recipe`, `sop`)<br>- `target_code`: string<br>- `has_attachment`: bool | Loại phản hồi nào phổ biến nhất? Công thức/SOP nào bị báo lỗi nhiều? Tỷ lệ kèm ảnh hiện trường? | Flow 3 |
| 7 | `export_report_pdf` | Tạo file PDF và upload thành công lên Firebase Storage (`StorageViewModel.exportPracticeReport`) | - `report_type`: string (`practice_history`)<br>- `record_count`: int<br>- `file_size_kb`: int | Nhân viên có dùng tính năng xuất báo cáo tự luyện không? Kích thước tệp PDF có tối ưu? | Flow 2 |
| 8 | `trigger_test_crash` | Bấm nút kiểm thử "Gây crash" hoặc "Ghi non-fatal" ở màn Tài khoản (`AccountProfilePage._crashDemo`) | - `kind`: string (`fatal`, `non_fatal`) | Tính năng kiểm thử sự cố được chạy bao nhiêu lần, có gây nhiễu dữ liệu thật không? | Kiểm thử Lab 3 |

---

## Phân định vai trò & Bảo mật dữ liệu

1. **Nhóm phát triển & Quản trị hệ thống**:
   - Theo dõi 8 sự kiện hành vi trên Google Analytics qua **Firebase Console** (`DebugView` trong lúc dev, `Dashboard` / `Events` khi release).
   - Tuyệt đối không gửi email, họ tên, hoặc dữ liệu nhạy cảm vào Analytics.

2. **Quản lý cửa hàng (Store Admin)**:
   - Sử dụng Web Admin (`recipehub-mobile.web.app`) để xem dữ liệu quản trị: sự cố hệ thống (`incidents`), danh sách nhân viên, thông báo, quản lý công thức/SOP.
   - Web Admin **không** hiển thị log thao tác học tập/tra cứu chi tiết của từng Barista (đảm bảo quyền riêng tư người dùng theo yêu cầu đồ án).

---

## Hướng dẫn kiểm chứng sự kiện

1. **Bật chế độ DebugView**:
   ```bash
   adb shell setprop debug.firebase.analytics.app com.recipehub.mobile
   ```
   Mở Firebase Console → mục **Analytics** → **DebugView** để xem luồng event thời gian thực.

2. **Kiểm tra Logcat trên thiết bị**:
   ```bash
   adb shell setprop log.tag.FA-SVC VERBOSE
   adb logcat -v time -s FA-SVC:V
   ```
   Xem log xác nhận: `Logging event: origin=app, name=<event_name>, params=...`.
