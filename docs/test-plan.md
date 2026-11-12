# Kế hoạch Kiểm thử Tự động E2E với ARTEMIS – RecipeHub Mobile

Tài liệu kế hoạch kiểm thử tự động toàn diện (Lab 3, Appendix B) cho ứng dụng **RecipeHub Mobile** sử dụng agent AI kiểm thử bằng ngôn ngữ tự nhiên **ARTEMIS** trên thiết bị Android thật (Xiaomi Redmi 7, Android 10).

> Kết quả chạy thực tế ở mục 5.1. TC-04 và TC-09 là ca thủ công bị chặn bởi điều kiện UI/phiên; không tính là đã pass.

> Cập nhật 12/11/2026: `flutter analyze` 0 issue; `flutter test` 320/320 pass; APK release build thành công. Các ca ARTEMIS và ảnh Console bên dưới là bằng chứng lịch sử, chưa chạy lại suite ARTEMIS sau đợt đổi UI. Thông báo hiện tại dùng `ToastMessenger` phía trên thay cho vị trí SnackBar cũ; câu chữ/action nghiệp vụ giữ nguyên. Xem [bản cập nhật 12/11](releases/2026-11-12.md) cho thay đổi sổ tay, ảnh món và kiểm tra mạng Redmi 7.

---

## 1. Flow quan trọng → Màn hình

Bảng ánh xạ các luồng nghiệp vụ trọng yếu của ứng dụng tới tệp giao diện tương ứng trong `lib/features/`:

| STT | Luồng nghiệp vụ trọng yếu | Mô tả nghiệp vụ | Tệp màn hình (`lib/features/...`) |
| :-: | :--- | :--- | :--- |
| 1 | **Đăng nhập & Xác thực** | Đăng nhập Email/Mật khẩu, Google Sign-In, tài khoản Khách, điều hướng AuthGate | `features/auth/login_page.dart`<br>`features/auth/auth_gate.dart` |
| 2 | **Tra cứu tại quầy** | Tìm kiếm món không dấu, lọc theo nhóm, giới hạn danh sách theo Remote Config | `features/lookup/counter_recipe_lookup_page.dart` |
| 3 | **Chi tiết món theo size** | Định lượng thành phần theo size, cảnh báo nguyên liệu, quy cách phục vụ chuẩn | `features/lookup/recipe_detail_size_page.dart` |
| 4 | **Video chuẩn từng bước** | Trình phát video thao tác chuẩn, mốc timeline bước, chuyển bước trước/sau, toàn màn hình | `features/lookup/step_video_guide_page.dart` |
| 5 | **Sổ tay SOP điện tử** | Sách điện tử lật trang 3D, nhảy trang theo mục lục, tìm kiếm nhanh và xuất PDF toàn bộ sổ tay | `features/sop_book/sop_book_page.dart` |
| 6 | **Đào tạo, Nhiệm vụ học & Quiz** | Quản lý nhiệm vụ (Đang học, Chưa học, Hoàn thành), checklist đọc/xem, làm bài trắc nghiệm nộp điểm | `features/learning/my_learning_page.dart`<br>`features/learning/learning_task_detail_page.dart`<br>`features/practice/quiz_exam_page.dart` |
| 7 | **Tự luyện & Báo cáo PDF** | Đồng hồ bấm giờ pha chế, lưu nhận xét cá nhân, xem lịch sử và xuất PDF lưu máy vào `Download/RecipeHub` | `features/practice/self_practice_timer_page.dart`<br>`features/practice/practice_history_page.dart` |
| 8 | **Chấm thực hành (Admin)** | Bảng theo dõi nhân sự toàn chi nhánh, form chấm điểm thao tác quầy theo checklist tiêu chuẩn | `features/admin_training/admin_store_training_page.dart`<br>`features/practice/practical_evaluation_page.dart` |
| 9 | **Phản hồi kèm ảnh & Trao đổi real-time** | Gửi phản hồi kèm ảnh qua photo picker hệ thống, quản lý trao đổi 2 chiều và cập nhật trạng thái | `features/feedback/create_feedback_page.dart`<br>`features/feedback/my_feedback_list_page.dart`<br>`features/feedback/feedback_detail_page.dart` |
| 10 | **Thông báo FCM & Deep link** | Trung tâm thông báo, lọc loại tin, xử lý chạm push notification từ khay hệ thống mở màn tương ứng | `features/learning/notifications_page.dart` |
| 11 | **Tài khoản & Đổi mật khẩu & Đăng xuất** | Hồ sơ nhân viên, đổi mật khẩu bảo mật, mở primer quyền thông báo, kiểm thử sự cố và đăng xuất an toàn | `features/account/account_profile_page.dart`<br>`features/account/change_password_page.dart` |

---

## 2. Ca kiểm thử tự động (ARTEMIS Test Cases)

Bộ ca kiểm thử tự động bao gồm 24 ca (tối thiểu 22 ca theo yêu cầu), bao phủ toàn bộ các luồng chức năng, phân quyền, xử lý lỗi và kiểm chứng sự kiện Analytics.

| Mã ca | Vai trò | Điều kiện đầu | Instruction tiếng Anh cho ARTEMIS | Kết quả mong đợi (tiếng Việt) | File test pytest dự kiến |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Barista (Viewer) | App đã cài đặt, mở màn hình Đăng nhập | Start at the Login screen, enter the email from $RH_VIEWER_EMAIL into the email field, enter the password from $RH_VIEWER_PASSWORD into the password field, tap 'Đăng nhập', verify that the app successfully authenticates and displays the Counter Lookup screen with the headline 'Tra cứu tại quầy', and return JSON {status: 'success', screen: 'lookup', role: 'viewer'}. | Đăng nhập thành công, chuyển sang màn hình Tra cứu tại quầy bar với vai trò Barista (`VIEWER`). | `e2e_test/test_auth.py` |
| **TC-02** | Barista (Viewer) | Màn hình Đăng nhập | Start at the Login screen, enter the email from $RH_VIEWER_EMAIL, enter an incorrect password 'WrongPass@2026', tap 'Đăng nhập', verify that a SnackBar appears displaying the error message 'Email hoặc mật khẩu không đúng.', and return JSON {error_displayed: true, message: 'Email hoặc mật khẩu không đúng.'}. | Ứng dụng từ chối đăng nhập, hiển thị SnackBar đỏ với nội dung "Email hoặc mật khẩu không đúng.". | `e2e_test/test_auth.py` |
| **TC-03** | Barista (Viewer) | Màn hình Đăng nhập | Start at the Login screen, tap 'Quên mật khẩu?', in the modal bottom sheet enter the email from $RH_VIEWER_EMAIL into the email field, tap 'Gửi thư đặt lại', verify that the result text displays 'Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu.', and return JSON {reset_requested: true, confirmation: 'Nếu email đã được cấp tài khoản, bạn sẽ nhận thư đặt lại mật khẩu.'}. | Gửi yêu cầu đặt lại mật khẩu thành công, hiển thị thông điệp trung tính không để lộ thông tin tài khoản. | `e2e_test/test_auth.py` |
| **TC-04** | Barista | Thủ công, bị chặn | Login không có UI yêu cầu Admin; kiểm tra fallback bằng Flutter AuthViewModel test. | Không chạy ARTEMIS giả lập control không tồn tại; chưa có kết quả thủ công. | `e2e_test/test_auth.py` (manual/skip) |
| **TC-05** | Barista (Viewer) | Màn hình Đăng nhập, thiết bị đã liên kết tài khoản Google | Start at the Login screen, tap 'Đăng nhập với Google', in the Android system Google account picker dialog select the target Google account, verify that authentication succeeds, the role badge 'VIEWER' is shown, and the Counter Lookup screen appears, returning JSON {auth_method: 'google', status: 'authenticated'}. | Đăng nhập Google thành công qua Account Picker hệ thống, ứng dụng mở màn hình Tra cứu với vai trò Barista. | `e2e_test/test_auth.py` |
| **TC-06** | Barista (Viewer) | Màn hình Đăng nhập | Start at the Login screen, tap 'Đăng nhập với Google', when the Android system account picker dialog appears press the device Back button to dismiss it, verify that the Login screen remains active and an error SnackBar displays 'Bạn đã hủy đăng nhập Google. Chưa có thay đổi nào.', returning JSON {cancelled: true, current_screen: 'login'}. | Người dùng hủy chọn tài khoản Google, ứng dụng giữ nguyên trạng thái chưa đăng nhập và báo thông điệp hủy thân thiện. | `e2e_test/test_auth.py` |
| **TC-07** | Barista (Viewer) | Đã đăng nhập, đang ở màn hình Tra cứu | Start at the Counter Lookup screen, enter 'long' into the search input with key 'lookup_search', verify that the recipe list filters and displays matching cards such as 'Bòng Bưởi - Ô Long Bưởi Nha Đam', and return JSON {query: 'long', results_count: count, first_item_name: name}. | Từ khóa `long` trả về các món Ô Long, có `Bòng Bưởi - Ô Long Bưởi Nha Đam`; ghi nhận số lượng thực tế. | `e2e_test/test_search.py` |
| **TC-08** | Barista (Viewer) | Đang ở màn hình Tra cứu | Start at the Counter Lookup screen, enter 'MonKhongTonTai999' into the search field, verify that the recipe list becomes empty and displays the empty state message 'Không tìm thấy công thức phù hợp' with subtitle 'Thử đổi từ khóa hoặc bộ lọc danh mục.', returning JSON {empty_state_shown: true, title: 'Không tìm thấy công thức phù hợp'}. | Hiển thị màn hình trạng thái rỗng (Empty State) với thông điệp hướng dẫn đổi từ khóa/bộ lọc. | `e2e_test/test_search.py` |
| **TC-09** | Barista | Thủ công, bị chặn | Force-stop, pm clear; tắt Wi-Fi/data trước khi mở app. Xác nhận không có cache. Cần phiên Auth hợp lệ để vào tra cứu; hiện app dừng tại Login khi mở offline sau pm clear. | Chỉ kiểm lỗi tải và retry khi có setup Auth không kèm cache; chưa có setup nên không kết luận pass. | `e2e_test/test_search.py` (manual/skip) |
| **TC-10** | Barista (Viewer) | Đã đăng nhập, ở màn hình chính | From the bottom navigation bar, successively tap tab 'Tra cứu', tab 'Việc học', tab 'Phản hồi', and tab 'Tài khoản', verify that the top AppBar title or screen content updates accordingly for each tab, and return JSON {tabs_verified: ['Tra cứu', 'Việc học', 'Phản hồi', 'Tài khoản'], status: 'pass'}. | Chuyển đổi mượt mà qua cả 4 tab cấp 1 trên NavigationBar; nội dung từng tab tải đúng IndexedStack. | `e2e_test/test_search.py` |
| **TC-11** | Barista (Viewer) | Đang ở màn hình Tra cứu | Start at the Counter Lookup screen, search for 'Latte Đá', then tap that exact recipe card, verify that the Detail screen opens showing the recipe name, 'ĐỊNH LƯỢNG NGUYÊN LIỆU', and standard serving note, returning JSON {recipe_name: 'Latte Đá', detail_opened: true, ingredients_count: count}. | Mở màn hình chi tiết món, hiển thị đầy đủ thông tin định lượng, nguyên liệu và quy cách phục vụ. | `e2e_test/test_detail.py` |
| **TC-12** | Barista (Viewer) | Đang ở màn hình Chi tiết món | Search and open Latte Đá, then at the Recipe Detail screen, tap the 'Xem video chuẩn' button, verify that StepVideoGuidePage opens with video player loaded, verify step timeline chips 'Bước 1', 'Bước 2', tap 'Bước tiếp theo', and verify that active step advances, returning JSON {video_guide_opened: true, active_step: 2}. | Mở trình phát video chuẩn; các nút chuyển bước và mốc video hoạt động đồng bộ với bài hướng dẫn. | `e2e_test/test_detail.py` |
| **TC-13** | Barista (Viewer) | Đã đăng nhập, kết nối logcat ADB | Start logcat filter for 'FA-SVC', open the recipe detail for 'Americano Nóng' from the Lookup list, verify in logcat that an analytics event 'view_recipe' is logged containing parameters 'recipe_code', 'category', 'size', and 'source=lookup' without any PII, returning JSON {event_name: 'view_recipe', params_found: true}. | Sự kiện Analytics `view_recipe` được ghi nhận chính xác trong logcat `FA-SVC`, không chứa PII (đáp ứng tiêu chuẩn đo lường). | `e2e_test/test_detail.py` |
| **TC-14** | Barista (Viewer) | Đang ở màn hình Tài khoản | Start at the Account screen, tap 'Sổ tay SOP', verify that SopBookPage opens with 3D flip page view, tap the 'Mục lục' action icon on AppBar to jump to the Table of Contents on page 2, tap 'Xuất PDF', and verify that a SnackBar shows 'Đã lưu: Download/RecipeHub/...', returning JSON {sop_book_opened: true, pdf_exported: true, path: saved_path}. | Sổ tay SOP hiển thị dạng lật sách 3D, nhảy mục lục chính xác và xuất file PDF lưu vào thư mục máy thành công. | `e2e_test/test_practice_export.py` |
| **TC-15** | Barista (Viewer) | Đang ở tab 'Việc học' | Start at the MyLearningPage, select the 'Chưa học' tab, then tap a learning task (fail clearly if none exists), verify that LearningTaskDetailPage opens showing sections checklist, toggle a section checkbox to completed, tap 'Hoàn thành', and verify completion notice appears, returning JSON {task_detail_opened: true, completed: true}. | Xem chi tiết nhiệm vụ học tập, tick chọn các mục checklist và xác nhận hoàn thành nội dung đọc/xem. | `e2e_test/test_practice_export.py` |
| **TC-16** | Barista (Viewer) | Đang ở tab 'Việc học' | Start at MyLearningPage, tap 'Làm bài Quiz', select a quiz set, answer all multiple-choice questions, tap 'Nộp bài kiểm tra', verify that the result card displays score 'X / Y câu đúng' along with detailed explanations for each question, returning JSON {quiz_submitted: true, score: score_string}. | Nộp bài kiểm tra lý thuyết thành công, xem điểm số, trạng thái Đạt/Chưa đạt và phần giải thích chi tiết từng câu. | `e2e_test/test_practice_export.py` |
| **TC-17** | Barista (Viewer) | Đang ở màn hình Tra cứu | Tap the FloatingActionButton with key 'self_practice_fab' to open SelfPracticeTimerPage, tap 'Bấm giờ', wait 5 seconds, tap 'Tạm dừng', enter notes 'Test thực hành chuẩn', tap 'Lưu lần luyện tập', verify that PracticeHistoryPage opens, tap 'Xuất báo cáo PDF', and verify SnackBar 'Đã lưu: Download/RecipeHub/...', returning JSON {timer_saved: true, report_exported: true}. | Bấm giờ thao tác tự luyện, lưu kết quả vào lịch sử cá nhân và xuất báo cáo PDF lưu trữ cục bộ tại máy. | `e2e_test/test_practice_export.py` |
| **TC-18** | Admin | Đã đăng nhập tài khoản Store Admin | Navigate to the 'Đào tạo' tab (AdminStoreTrainingPage), tap 'Chấm ngay' on evaluation card, in PracticalEvaluationPage select trainee Barista and recipe, toggle criteria switches, select overall result 'Đạt yêu cầu', enter comments, tap 'Lưu đánh giá', and verify success SnackBar, returning JSON {evaluation_saved: true, trainee: name}. | Quản lý Admin thực hiện quan sát và chấm thực hành tại quầy theo checklist tiêu chí; lưu kết quả thành công lên Firestore. | `e2e_test/test_practice_export.py` |
| **TC-19** | Barista (Viewer) | Đang ở tab 'Phản hồi' | Start at MyFeedbackListPage, tap the create feedback icon, in CreateFeedbackPage choose feedback type 'Báo cáo vấn đề', enter detailed content, tap 'Thư viện' to pick an image from Android media picker, tap 'Gửi phản hồi', verify success message, switch to Admin account, and verify that Admin sees the new feedback with attachment instantly, returning JSON {feedback_sent: true, admin_received: true}. | Barista gửi phản hồi kèm ảnh chọn từ photo picker hệ thống; tài khoản Admin thấy ngay phản hồi và ảnh trên luồng real-time. | `e2e_test/test_feedback.py` |
| **TC-20** | Barista (Viewer) | Barista A đã gửi 1 phản hồi | Log out of Barista A, log in with Barista B credentials ($RH_VIEWER_B_EMAIL), navigate to the 'Phản hồi' tab, verify that Barista B's list only shows B's own feedbacks and does NOT contain any feedback from Barista A, returning JSON {isolation_verified: true, foreign_feedback_present: false}. | Đảm bảo tính bảo mật và phân quyền: Barista B tuyệt đối không nhìn thấy các phản hồi riêng tư của Barista A. | `e2e_test/test_feedback.py` |
| **TC-21** | Barista + Console operator | Ghi giá trị `max_lookup_results` gốc mỗi vòng | Operator ghi số nguyên gốc vào `tc21-baseline-done`; chọn target 1 (hoặc 2 nếu gốc là 1), đếm baseline khác target, publish sau ready; theo dõi app foreground không reload; finally khôi phục đúng giá trị gốc qua `tc21-restore-ready/done`. | Số card đổi đúng target; cấu hình được khôi phục trước vòng kế tiếp. | `e2e_test/test_profile_remote_config.py` |
| **TC-22** | Admin | Đã đăng nhập tài khoản Store Admin | Check the Counter Lookup screen to verify that the floating action button 'self_practice_fab' is NOT present, check tab 2 is 'Đào tạo' instead of 'Việc học', open the 'Tài khoản' screen and verify that 'Tiến độ đào tạo cá nhân' and 'Lịch sử tự luyện với Timer' are hidden, returning JSON {admin_restrictions_verified: true, personal_learning_hidden: true}. | Giao diện vai trò Admin ẩn hoàn toàn nút tự luyện quầy bar, thanh tiến độ cá nhân và lịch sử tự luyện (chỉ tập trung quản lý). | `e2e_test/test_profile_remote_config.py` |
| **TC-23** | Barista (Viewer) | App đang chạy nền (background) | Send a test FCM push notification with title 'Cập nhật công thức' and payload '{type: recipe}', open Android system notification shade, tap the RecipeHub notification, verify that the app is brought to foreground and navigates to NotificationsPage ('Thông báo & Thay đổi'), returning JSON {push_received: true, navigated_screen: 'notifications'}. | Chạm vào push notification từ khay hệ thống Android đánh thức app và điều hướng thẳng vào màn hình "Thông báo & Thay đổi". | `e2e_test/test_notifications.py` |
| **TC-24** | Barista riêng | `RH_PASSWORD_TEST_EMAIL` / `RH_PASSWORD_TEST_PASSWORD` | Đăng nhập tài khoản riêng, nhập mật khẩu hiện tại, mới và xác nhận; kiểm tra thành công; đổi lại mật khẩu gốc. Nếu lỗi giữa chừng, finally đăng nhập và phục hồi mật khẩu gốc, rồi đăng xuất. | Đổi và phục hồi thành công; không dùng tài khoản Viewer chung. | `e2e_test/test_auth.py` |

---

## 3. Dữ liệu và Điều kiện đầu

### 3.1. Tài khoản kiểm thử theo vai trò (Biến môi trường)
Nhằm bảo mật tuyệt đối, thông tin đăng nhập **không được viết trực tiếp vào mã nguồn hay tài liệu**, mà được nạp qua biến môi trường trước khi chạy bộ test:

- **Tài khoản Barista A (Viewer chính):**
  - Email: `$RH_VIEWER_EMAIL`
  - Mật khẩu: `$RH_VIEWER_PASSWORD`
- **Tài khoản Barista B (Viewer phụ – kiểm thử cách ly dữ liệu phản hồi TC-20):**
  - Email: `$RH_VIEWER_B_EMAIL`
  - Mật khẩu: `$RH_VIEWER_B_PASSWORD`
- **Tài khoản Quản lý cửa hàng (Store Admin):**
  - Google account có custom claim Admin: `$RH_ADMIN_GOOGLE_ACCOUNT`
- **Tài khoản đổi mật khẩu riêng (TC-24):** `$RH_PASSWORD_TEST_EMAIL` / `$RH_PASSWORD_TEST_PASSWORD`

### 3.2. Thiết bị kiểm thử vật lý
- **Thiết bị:** Xiaomi Redmi 7 (Onclite).
- **Hệ điều hành:** Android 10 (API level 29).
- **Độ phân giải màn hình:** 720 × 1520 pixels.
- **Bản dựng ứng dụng:** APK bản Release chính thức (`app-release.apk`), build với cờ tối ưu hóa:
  ```powershell
  flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=$GOOGLE_SERVER_CLIENT_ID
  ```

### 3.3. Quy trình làm sạch trạng thái trước mỗi ca kiểm thử
Để đảm bảo tính độc lập và tránh ảnh hưởng dữ liệu giữa các ca kiểm thử:
1. Thực thi lệnh xóa dữ liệu app qua ADB:
   ```bash
   adb -s $ANDROID_SERIAL shell pm clear com.recipehub.mobile
   ```
2. Khởi chạy lại ứng dụng:
   ```bash
   adb -s $ANDROID_SERIAL shell am start -n com.recipehub.mobile/.MainActivity
   ```
3. Đăng nhập lại đúng vai trò yêu cầu của từng ca kiểm thử.

---

## 4. Cách chạy bộ kiểm thử tự động

Bộ test E2E được điều khiển bởi ARTEMIS agent (sử dụng Gemini Flash/Pro) kết hợp cùng framework pytest trong thư mục `e2e_test/`.

### 4.1. Cài đặt môi trường
Sử dụng công cụ quản lý gói `uv`:
```powershell
cd e2e_test
uv sync
```

### 4.2. Cấu hình biến môi trường
Thiết lập các biến môi trường bắt buộc trong phiên dòng lệnh:
```powershell
$env:GEMINI_API_KEY = "AIzaSy..."
$env:ANDROID_SERIAL = "dc6a090b"  # Serial của Redmi 7 kết nối adb
$env:RH_VIEWER_EMAIL = "barista.hcm01@recipehub.vn"
$env:RH_VIEWER_PASSWORD = "..."
$env:RH_VIEWER_B_EMAIL = "barista.hcm02@recipehub.vn"
$env:RH_VIEWER_B_PASSWORD = "..."
$env:RH_ADMIN_GOOGLE_ACCOUNT = "<admin-google-account>"
$env:RH_PASSWORD_TEST_EMAIL = "<dedicated-password-test-account>"
$env:RH_PASSWORD_TEST_PASSWORD = "..."
```

### 4.3. Chạy kiểm thử đơn lẻ hoặc theo suite
Chạy toàn bộ các ca pytest:
```powershell
uv run pytest -v
```
Chạy từng nhóm kiểm thử theo tệp:
```powershell
uv run pytest test_auth.py -v
uv run pytest test_search.py -v
uv run pytest test_detail.py -v
uv run pytest test_practice_export.py -v
uv run pytest test_feedback.py -v
uv run pytest test_profile_remote_config.py -v
uv run pytest test_notifications.py -v
```

### 4.4. Chạy đối soát 3 vòng độc lập
Để đo lường độ ổn định (Pass Rate) và phát hiện flaky test, chạy tập lệnh lặp 3 vòng và xuất kết quả ra file `results.csv`:
```powershell
.\run_suite.ps1
```

---

## 5. Kết quả chạy kiểm thử & Phiên khám phá

<!-- ARTEMIS-TP:START -->
> [!NOTE]
> **Trạng thái (cập nhật 09/11/2026 09:02):** **18/19 ca tự động đã PASS ít nhất 1 vòng**, 3 vòng · 49/55 lượt-ca PASS · lượt thử gồm cả lần thử lại do Gemini 429/503; 5 ca thủ công (TC-04, TC-09, TC-21, TC-23, TC-24). Model: Gemini 3.5/3.1 Flash-Lite (free tier, xoay 5 key). Số liệu sinh tự động từ `e2e_test/results/round*.jsonl` (+ `rerun*.jsonl`).

### 5.1. Bảng kết quả chạy tự động (3 vòng đối soát)

| Test ID | Ca kiểm thử | Số vòng | Pass | Thời gian TB (lượt pass) | Trace mẫu | Ghi chú |
| :--- | :--- | :-: | :-: | :-: | :--- | :--- |
| **TC-01** | Đăng nhập Email/Mật khẩu thành công | 3 | 3/3 | 267s | `72cbde45` | – |
| **TC-02** | Đăng nhập sai mật khẩu báo lỗi | 3 | 3/3 | 171s | `8c7a98e3` | – |
| **TC-03** | Quên mật khẩu gửi thư đặt lại | 3 | 3/3 | 92s | `31141d22` | – |
| **TC-04** | Tài khoản chưa cấp quyền hạ vai trò | – | Thủ công | – | – | Thủ công: màn đăng nhập không có lựa chọn xin quyền Admin |
| **TC-05** | Đăng nhập Google qua Account Picker | 3 | 3/3 | 200s | `c26179a0` | – |
| **TC-06** | Hủy chọn tài khoản Google Sign-In | 3 | 3/3 | 53s | `0ce4f207` | – |
| **TC-07** | Tìm kiếm công thức có kết quả tại quầy | 3 | 3/3 | 175s | `3f9c1159` | – |
| **TC-08** | Tìm kiếm không có kết quả (Empty State) | 3 | 3/3 | 154s | `e13b2520` | – |
| **TC-09** | Xử lý mất mạng và bấm nút Thử lại | – | Thủ công | – | – | Thủ công: pm clear xoá phiên nên không tạo được lỗi tải khi đã đăng nhập |
| **TC-10** | Chuyển đổi qua 4 tab điều hướng cấp 1 | 3 | 1/3 | 42s | `dd13bd6a` | Vòng 2–3: agent trả lời văn xuôi thay vì JSON (model lite); đã đổi khoá kết quả + chỉ dẫn |
| **TC-11** | Xem chi tiết công thức và thông tin size | 3 | 3/3 | 109s | `7bd16778` | – |
| **TC-12** | Xem video chuẩn từng bước thao tác | 3 | 3/3 | 174s | `33e5af3d` | – |
| **TC-13** | Kiểm tra event Analytics `view_recipe` logcat | 3 | 3/3 | 97s | `1879fed5` | – |
| **TC-14** | Sổ tay SOP lật trang 3D & xuất PDF | 3 | 3/3 | 101s | `ccaf0466` | – |
| **TC-15** | Chi tiết nhiệm vụ học & tick checklist | 3 | 2/3 | 91s | `8261ff25` | Vòng 2: agent trả lời văn xuôi; vòng 3 PASS sau khi thêm chỉ dẫn JSON |
| **TC-16** | Làm trắc nghiệm Quiz & nộp xem điểm | 3 | 3/3 | 261s | `d2032ead` | – |
| **TC-17** | Tự luyện bấm giờ & xuất PDF vào máy | 3 | 3/3 | 183s | `fbaa4c40` | – |
| **TC-18** | Admin chấm thực hành tại quầy theo tiêu chí | 3 | 2/3 | 314s | `5fd11e30` | Vòng 3: hết quota Gemini (429) trên cả 5 key lúc đăng nhập Admin |
| **TC-19** | Gửi phản hồi kèm ảnh & Admin nhận real-time | 3 | 3/3 | 236s | `4e324883` | – |
| **TC-20** | Cách ly dữ liệu phản hồi giữa Barista A và B | 1 | Đang chờ chạy lại | – | – | Vòng 1: adb gõ email sai (@→#); đã sửa gõ từng ký tự |
| **TC-21** | Áp dụng cấu hình Remote Config giới hạn món | – | PASS (thủ công) | – | – | Thủ công 08/11: Remote Config 50 → 5 → 50, áp dụng khi mở lại app |
| **TC-22** | Admin bị ẩn tự luyện & tiến độ cá nhân | 3 | 2/3 | 156s | `312a02c3` | Vòng 3: gián đoạn do hết quota 429, chờ reset quota |
| **TC-23** | Chạm push notification khay hệ thống mở app | – | PASS (thủ công) | – | – | Thủ công 08/11: FCM foreground/background/terminated, chạm mở đúng màn |
| **TC-24** | Đổi mật khẩu tài khoản & đăng xuất an toàn | – | PASS (thủ công) | – | – | PASS – kiểm thủ công bởi chủ dự án (đổi mật khẩu) |
<!-- ARTEMIS-TP:END -->

### 5.2. Phiên kiểm thử khám phá (Exploratory Testing – 15 đến 30 phút)

> [!IMPORTANT]
> **Phiên khám phá bằng ARTEMIS profile Pro chưa chạy.** Free tier Gemini chỉ khoảng 20 request/ngày/model, đã dùng hết cho 3 vòng hồi quy. Không ghi kết quả giả.

Đã có một phiên khám phá **không theo kịch bản** ngày 05/11/2026, khoảng 25 phút (2 phiên 04:53–05:03 và 05:14–05:35). Phiên này do agent điều khiển Redmi 7 qua adb (chạm, nhập, chụp màn hình, đọc logcat), trên bản build khi app còn gọi Gateway .NET; xem đầy đủ tại [`exploratory-testing-log.md`](exploratory-testing-log.md). Nhật ký có 40 phát hiện (8 Cao, 12 Trung bình, còn lại Thấp/Thông tin), gồm cả các lượt chạy sau phiên. Một số phát hiện Cao tiêu biểu:

| STT | Màn hình | Thao tác thực hiện | Hiện tượng quan sát được | Mức độ | Trạng thái |
| :-: | :--- | :--- | :--- | :--- | :--- |
| E-01 | Tra cứu | Mở danh sách trên màn 360 dp | Tràn ngang 9.5 px ở hàng chip và meta thẻ công thức | Cao | Đã sửa (`Flexible`/ellipsis) |
| E-21 | Thông báo | Chạm thông báo trỏ tới món ngoài giới hạn Remote Config | Mở trang Thông báo thay vì chi tiết món | Cao | Đã sửa |
| E-23 | Đăng xuất / đăng nhập | Bị khoá rồi đăng nhập lại ngay | `ConcurrentModificationError` trong `NotificationViewModel.reset()` | Cao | Đã sửa |
| E-32 | Thông báo | Đổi vai trò khi đang ở trang Thông báo rồi bấm back | `setState() called after dispose()` gây crash | Cao | Đã sửa (kiểm `mounted`) |

---

## 6. Ca đã kiểm thủ công ngày 08/11/2026

Ghi nhận trung thực kết quả kiểm thử thủ công chức năng **Firebase Cloud Messaging (FCM)** gửi từ Firebase Console tới thiết bị thật Xiaomi Redmi 7 vào ngày **08/11/2026**:

### 6.1. Kết quả tiếp nhận thông báo trên 3 trạng thái ứng dụng
Đã thực hiện gửi Test Message từ mục **Messaging** trên Firebase Console trực tiếp tới FCM Registration Token của Redmi 7:
1. **Trạng thái Foreground (Ứng dụng đang mở trên màn hình):**
   - Ứng dụng nhận thông báo tức thì, hiển thị banner **SnackBar nổi trong app** (`SnackBarBehavior.floating`) kèm nút bấm "Xem".
   - Biểu tượng quả chuông thông báo trên AppBar tự động kích hoạt **chấm đỏ chỉ báo có tin mới** (`unreadNotifs > 0`).
2. **Trạng thái Background (Ứng dụng đang ẩn dưới nền):**
   - Thiết bị nhận thông báo hệ thống và hiển thị trên **khay thông báo (Notification Shade) của Android**.
   - Có đầy đủ tiêu đề, nội dung và âm thanh thông báo tiêu chuẩn.
3. **Trạng thái Terminated (Ứng dụng đã bị đóng hoàn toàn / Kill process):**
   - Thiết bị đánh thức tiến trình nhận tin ngầm thành công, hiển thị thông báo trên **khay thông báo hệ thống**.
   - Khi người dùng chạm vào thông báo từ khay hệ thống, ứng dụng được khởi động lạnh và điều hướng chính xác vào màn hình **"Thông báo & Thay đổi"** (`NotificationsPage`).

### 6.2. Hai vấn đề thực tế phát hiện cần cải tiến
Trong quá trình kiểm thử thủ công ngày 08/11/2026, nhóm kiểm thử phát hiện 2 vấn đề phát sinh trên Android 10:
1. **Hiển thị SnackBar trùng khi mở app từ thông báo:**
   - *Hiện tượng:* Khi chạm vào push notification từ khay hệ thống để mở ứng dụng, màn hình đã được điều hướng tới "Thông báo & Thay đổi", nhưng đồng thời giao diện vẫn bật thêm một SnackBar nổi chứa nội dung thông báo vừa chạm (gây trùng lặp hiển thị 2 lần).
2. **Hộp thoại xin quyền hiển thị không cần thiết trên Android 10:**
   - *Hiện tượng:* Khi mở lạnh ứng dụng trên Redmi 7 (Android 10), app vẫn bật hộp thoại quyền `Bật thông báo?` (`permission_primer_dialog`) với hai nút "Để sau" và "Cho phép", mặc dù trên Android 10 quyền thông báo được cấp mặc định khi cài đặt và hệ thống thông báo đã đang hoạt động bình thường.

### 6.3. Bằng chứng kiểm thử
Toàn bộ ảnh chụp màn hình kiểm chứng các bước kiểm thử thủ công FCM được lưu trữ tại thư mục:
- Đường dẫn: `evidence/lab3/06-firebase-console/`
- Tệp bằng chứng: `11-fcm-foreground.jpg`, `12-fcm-background.jpg`, `13-fcm-tap-opens-inbox.jpg`, `14-fcm-terminated.jpg`, `15-fcm-terminated-tap-open.jpg`, `10b-fcm-console-test-token-blurred.jpg`.
