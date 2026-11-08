# Ma trận Truy vết Thiết kế – Yêu cầu → Màn hình → MVVM → Dịch vụ → Kiểm thử

Nguồn yêu cầu: `requirements-draft.md` mục 10 (M-01 → M-18). Thiết kế UI ban đầu: `docs/lab2/DESIGN.md`, `docs/lab2/ux/`.  
Mã ca kiểm thử: `FT-xx` = unit/widget test Flutter trong `test/`; `FT-xx` là alias tài liệu cho nhãn `TC-xx` cũ trong `test/artemis_e2e_test.dart` và `test/admin_link_test.dart`. `ART-xx` = mã runner adb lịch sử (`docs/artemis-test-plan.md`), không phải kết quả của suite ARTEMIS mới. Suite ARTEMIS hiện tại dùng `TC-01`–`TC-24` trong `e2e_test/`, xem `docs/test-plan.md` (chưa chạy).

---

## 1. Ma trận truy vết chi tiết từng màn hình & Luồng nghiệp vụ

> [!NOTE]
> `MockDataService` đã được xóa bỏ hoàn toàn khỏi mã nguồn `lib/`. Toàn bộ dữ liệu công thức, SOP, nhiệm vụ đào tạo, bài quiz, chấm điểm thực hành, phản hồi và sự cố đều hoạt động trên **Cloud Firestore (real-time)** và **Firebase Storage**.

| Mã | Màn hình (View) | File mã nguồn | ViewModel phụ trách | Service Interface → Triển khai Production | Sự kiện Analytics | Ca kiểm thử xác nhận |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| **M-01** | Đăng nhập quầy bar | `features/auth/login_page.dart`<br>`features/auth/auth_gate.dart` | `AuthViewModel` | `IAuthService` → `FirebaseAuthService` (Google, Email/Password, Anonymous)<br>`IUserProfileService` → `FirebaseUserProfileService` | `login`<br>`logout` | FT-01, FT-02, FT-03, FT-10, ART-01, ART-02, ART-03 |
| **M-01b**| Đổi / Quên mật khẩu | `features/account/change_password_page.dart`<br>`features/auth/forgot_password_dialog.dart` | `AuthViewModel` | `IAuthService` → `FirebaseAuthService` | – | Khám phá, kiểm thử giao diện |
| **M-02** | Tra cứu tại quầy | `features/lookup/counter_recipe_lookup_page.dart` | `RecipeViewModel`<br>`AppConfigViewModel` | `IRecipeSource` → `FirestoreRecipeSource` (hoặc `GatewayRecipeSource`)<br>`IRemoteConfigService` → `FirebaseRemoteConfigService` | – | FT-04, FT-05, FT-09, FT-10, ART-04, ART-05, ART-10 |
| **M-03** | Chi tiết công thức | `features/lookup/recipe_detail_size_page.dart` | `RecipeViewModel` | `IRecipeSource` → `FirestoreRecipeSource`<br>`IAnalyticsService` → `FirebaseAnalyticsService` | `view_recipe` | FT-08, ART-04, ART-09 |
| **M-04** | Hướng dẫn bước / Video chuẩn | `features/lookup/step_video_guide_page.dart` | `StepVideoViewModel` | `video_player` (stream video thật từ Cloud Storage URL `recipe.videoUrl`, hỗ trợ toàn màn hình) | – | Khám phá, kiểm thử playback |
| **M-05** | Thư viện SOP | `features/sop/sop_catalog_page.dart` | `TrainingViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository` (bộ sưu tập `sops` real-time) | – | Khám phá |
| **M-06** | Chi tiết SOP | `features/sop/sop_detail_page.dart` | `TrainingViewModel`<br>`StorageViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository`<br>`IStorageService` → `FirebaseStorageService` (PDF SOP gốc) | – | Khám phá, deep link FCM |
| **M-07** | Việc học của tôi | `features/learning/my_learning_page.dart` | `TrainingViewModel`<br>`AuthViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository` (`learningTasks`, `users/{uid}/taskProgress`) | – | Khám phá |
| **M-08** | Chi tiết nhiệm vụ học | `features/learning/learning_task_detail_page.dart` | `TrainingViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository` (`setSectionDone`) | – | Khám phá, deep link FCM |
| **M-09** | Tiến độ đào tạo cá nhân | `features/learning/personal_progress_page.dart` | `TrainingViewModel`<br>`AuthViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository` (tổng hợp SOP, Quiz, Thực hành) | – | Khám phá |
| **M-10** | Thông báo & Điều hướng | `features/learning/notifications_page.dart` | `NotificationViewModel` | `INotificationService` → `FirebaseNotificationService` (FCM)<br>`IDeviceRegistry` → `FirestoreDeviceRegistry` | – | FT-08, ART-09, ART-11 |
| **M-11** | Tạo phản hồi công thức/SOP | `features/feedback/create_feedback_page.dart` | `StorageViewModel`<br>`RecipeViewModel` | `IFeedbackRepository` → `FirestoreFeedbackRepository`<br>`IStorageService` → `FirebaseStorageService`<br>`IMediaPickerService` → `ImagePickerMediaService` | `submit_feedback` | FT-06, FT-07, ART-07 |
| **M-12** | Danh sách phản hồi | `features/feedback/my_feedback_list_page.dart` | `FeedbackListViewModel`<br>`AuthViewModel` | `IFeedbackRepository` → `FirestoreFeedbackRepository` (real-time `watchMine` hoặc `watchAll`) | – | ART-07 |
| **M-12b**| Chi tiết phản hồi & Trả lời | `features/feedback/feedback_detail_page.dart` | `FeedbackDetailViewModel` | `IFeedbackRepository` → `FirestoreFeedbackRepository` (`watchOne`, `watchReplies`, `reply`, `setStatus`) | – | Khám phá, trao đổi 2 chiều |
| **M-13** | Tài khoản & Phân quyền | `features/account/account_profile_page.dart` | `AuthViewModel`<br>`AppConfigViewModel` | `IAuthService` → `FirebaseAuthService`<br>`ICrashReporter` → `FirebaseCrashReporter`<br>`IIncidentReporter` → `FirestoreIncidentReporter` | `logout`<br>`trigger_test_crash` | ART-01, ART-12, Crashlytics manual |
| **M-14** | Tự luyện và bấm giờ | `features/practice/self_practice_timer_page.dart` | `RecipeViewModel`<br>`PracticeHistoryViewModel`<br>`AuthViewModel` | `IPracticeHistoryStore` → `FirestorePracticeHistoryStore`<br>`IAnalyticsService` → `FirebaseAnalyticsService` | `start_brew_timer`<br>`complete_brew_timer` | ART-06 |
| **M-15** | Lịch sử tự luyện & Xuất PDF | `features/practice/practice_history_page.dart` | `PracticeHistoryViewModel`<br>`StorageViewModel`<br>`AuthViewModel` | `IPracticeHistoryStore` → `FirestorePracticeHistoryStore`<br>`IStorageService` → `FirebaseStorageService`<br>`IFileSaveService` → `AndroidFileSaveService` | `export_report_pdf` | ART-08 |
| **M-16** | Làm bài kiểm tra Quiz | `features/practice/quiz_exam_page.dart` | `TrainingViewModel`<br>`AuthViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository` (`quizzes`, `answerKey`, `quizAttempts`) | – | Khám phá, nộp bài Firestore |
| **M-17** | Kết quả đánh giá thực hành | `features/practice/practical_evaluation_page.dart` | `TrainingViewModel`<br>`AdminTrainingViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository` (`evaluations`, `evaluationCriteria`) | – | Khám phá, chấm tại quầy |
| **M-18** | Sổ tay SOP lật trang & PDF | `features/sop_book/sop_book_page.dart` | `SopBookViewModel`<br>`TrainingViewModel` | `IRecipeSource` → `FirestoreRecipeSource`<br>`IFileSaveService` → `AndroidFileSaveService`<br>`SopBookPdf` | – | Khám phá, lật trang 3D |
| **Admin**| Bảng theo dõi đào tạo chi nhánh | `features/admin_training/admin_store_training_page.dart` | `AdminTrainingViewModel`<br>`AuthViewModel` | `ITrainingRepository` → `FirestoreTrainingRepository` (nhân viên thật trên `users` role viewer) | – | Khám phá, quản lý chi nhánh |
| **Hệ thống**| Khởi động / Phục hồi lỗi / Chuyển tiếp | `features/system/loading_transition_page.dart`<br>`features/system/error_recovery_page.dart` | `RecipeViewModel`<br>`AuthViewModel` | `core/widgets/load_state_view.dart` | – | ART-05 |

---

## 2. 6 dịch vụ Firebase: Khởi tạo, Tích hợp & Bằng chứng kiểm chứng

| Dịch vụ | Interface trừu tượng | Điểm sử dụng trong mã nguồn | Kiểm chứng thực tế trên Redmi 7 |
| :-- | :-- | :-- | :-- |
| **Authentication** | `IAuthService` | `AuthViewModel`, `AuthGate` | ART-01/02/03: Đăng nhập Google thành công, hủy chọn tài khoản, mất mạng, đăng nhập email/mật khẩu, chế độ khách. |
| **Cloud Storage** | `IStorageService` | `StorageViewModel` | ART-07/08: Tải ảnh feedback lên `feedback/{uid}/`, tải báo cáo PDF lên `reports/{uid}/`; chặn file > 5MB hoặc sai định dạng theo rules. |
| **Cloud Messaging (FCM)** | `INotificationService` | `NotificationViewModel`, `FirestoreDeviceRegistry` | ART-09/11: Nhận tin nhắn foreground (banner), background và terminated; deep link mở đúng chi tiết công thức (M-03) hoặc SOP (M-06). |
| **Analytics** | `IAnalyticsService` | `AuthViewModel`, `RecipeDetailSizePage`, `SelfPracticeTimerPage`, `StorageViewModel`, `CreateFeedbackPage`, `AccountProfilePage` | Đủ 8 sự kiện chuẩn (`snake_case`), tham số đã qua `sanitize` lọc PII; kiểm chứng qua `adb logcat -s FA-SVC` và báo cáo Events GA4. |
| **Crashlytics** | `ICrashReporter` | `firebase_bootstrap.dart`, `AuthViewModel`, toàn bộ ViewModel catches | Non-fatal `manual_demo` (custom key, user id), crash thật kiểm thử (báo cáo hiển thị trên Firebase Crashlytics Console). |
| **Remote Config** | `IRemoteConfigService` | `AppConfigViewModel`, `CounterRecipeLookupPage` | ART-10: Cập nhật `max_lookup_results` trên Firebase Console, app nhận giá trị mới và tự động cập nhật danh sách hiển thị. |

---

## 3. Liên kết với Web Admin & Cloud Functions

Dự án sử dụng chung cơ sở dữ liệu Firebase giữa Mobile app và Web Admin (`https://recipehub-mobile.web.app`):

| Yêu cầu | Web Admin (View → ViewModel) | Cloud Functions / Dữ liệu Firestore | Ứng dụng Mobile tương ứng | Mã kiểm thử |
| :-- | :-- | :-- | :-- | :-- |
| **FR-01** Admin đăng nhập, chặn viewer | `login_page`, `forbidden_page` → `AdminAuthViewModel` | `ensureProfile`, custom claim `role: 'admin'` | Kiểm tra vai trò trong token và hồ sơ `users/{uid}` | W-01..03, ART-14 |
| **FR-02/03** Danh sách user, cấp quyền | `users_page` → `UsersViewModel` | `setUserRole`, ghi `users/{uid}.claimsUpdatedAt` | `AuthViewModel` lắng nghe để làm mới token | W-08, F04, FT-14/17, ART-15 |
| **FR-04** Khóa / mở khóa tài khoản | `users_page` | `setUserDisabled`, ghi `users/{uid}.disabled` | `AuthViewModel` lắng nghe `users/{uid}` → tự động đăng xuất ngay | F05, FT-15, ART-13 |
| **FR-05..07** Gửi thông báo chi nhánh | `notifications_page` → `NotificationsViewModel` | `sendNotification`, `notifications/`, `devices/` | `NotificationViewModel` + `FirestoreDeviceRegistry` lưu token | W-07, F06/07, FT-16, ART-11 |
| **FR-08** Nút kiểm thử sự cố | – | `incidents/` | `AccountProfilePage` ghi Firestore và gọi Crashlytics | FT-18/20, ART-12 |
| **FR-09..11** Giám sát sự cố real-time | `incidents_page`, `dashboard_page` | `incidents/`, `onIncidentCreated/Updated` | `FirestoreIncidentReporter` đẩy lỗi fatal/non-fatal | W-05/06/09, F08/09, ART-12 |
| **FR-12** Quản lý công thức & SOP | `recipes_page`, `recipe_form_dialog` | `recipes/`, `sops/`, `seedRecipes` | `FirestoreRecipeSource` nạp dữ liệu chuẩn ban hành | W-10/11, F10, FT-21, ART-16 |
| **FR-13** Báo bù sự cố trước | – | `incidents/` | `FirebaseBootstrap.attachIncidentReporter` báo crash lần chạy trước | FT-19 |
| **FR-14** Bảo mật thao tác cá nhân | Web không có màn hình soi vết thao tác | – | Analytics phân tích tập trung, không hiện thao tác riêng tư của từng Barista | Rà soát bảo mật |

---

## 4. Các điểm điều chỉnh so với thiết kế Lab 2 (Kèm lý do thực tế)

Các điều chỉnh dưới đây do chủ dự án yêu cầu khi chạy thử bản APK trên Redmi 7 ngày **07–08/11/2026** (không phải khảo sát người dùng thật). Figma sẽ được cập nhật theo các lệch này.

1. **Ẩn hoàn toàn mã món trên UI mobile**:
   - *Ban đầu*: Thẻ món và chi tiết hiển thị mã kỹ thuật thô (ví dụ: `CF-CB-01`).
   - *Hiện tại*: Chỉ hiển thị tên món, nhóm món và định lượng phục vụ chuẩn.
   - *Lý do*: Yêu cầu của chủ dự án: mã món là mã kỹ thuật, người dùng tại quầy chỉ cần tên món. Mã vẫn dùng làm khóa Firestore và tham số Analytics.
2. **Bỏ chip "Ban hành · version" ở thẻ tra cứu tại quầy**:
   - *Ban đầu*: Mỗi thẻ trong danh sách tra cứu đều có chip xanh ghi "Ban hành · v2.0".
   - *Hiện tại*: Thẻ chỉ hiển thị tên món, nhóm món, số bước chuẩn và thời gian chuẩn.
   - *Lý do*: Yêu cầu của chủ dự án: thẻ chỉ cần tên món; phiên bản vẫn xem được ở màn chi tiết.
3. **Bỏ thẻ phạm vi cửa hàng / chi nhánh tại màn Tài khoản**:
   - *Ban đầu*: Cho phép chọn hoặc xem phạm vi chi nhánh trên giao diện Tài khoản.
   - *Hiện tại*: Bỏ thẻ này, chỉ hiển thị thông tin tài khoản và vai trò.
   - *Lý do*: Yêu cầu của chủ dự án: thông tin chi nhánh chưa được quản lý thật (chưa có collection `stores`), nên không hiển thị số liệu không có nguồn.
4. **SOP chuyển vào "Sổ tay SOP" tại Tài khoản (Bỏ chip Thư viện SOP ở Tra cứu)**:
   - *Ban đầu*: Màn Tra cứu có chip "Thư viện SOP" dẫn sang danh mục SOP.
   - *Hiện tại*: Màn Tra cứu chỉ tập trung vào đồ uống; SOP được tổ chức thành mục "Sổ tay SOP" trong màn Tài khoản với tính năng lật trang 3D và xuất PDF toàn diện.
   - *Lý do*: Yêu cầu của chủ dự án: Tra cứu đã hiển thị và tìm được mọi công thức; SOP gom vào một sổ tay duy nhất.
5. **Admin không có tiến độ đào tạo cá nhân và đồng hồ tự luyện**:
   - *Ban đầu*: Mọi vai trò đều thấy thanh tiến độ đào tạo và nút tự luyện.
   - *Hiện tại*: Kiểm tra thuộc tính `hasPersonalLearning` (`false` khi là Admin) để ẩn thanh tiến độ cá nhân, ẩn mục Lịch sử tự luyện cá nhân và ẩn nút FAB tự luyện.
   - *Lý do*: Store Admin là người quản lý, giám sát và chấm thi nhân viên, không phải đối tượng cần tự luyện; giao diện Admin tập trung vào "Bảng theo dõi đào tạo chi nhánh".
6. **Nút phụ trên thanh công cụ chuyển thành icon đơn giản**:
   - *Ban đầu*: Nút phụ kèm nhãn chữ (ví dụ: "Phản hồi món này").
   - *Hiện tại*: Chuyển thành icon tròn/vuông gọn gàng (icon cây bút, icon lịch sử).
   - *Lý do*: Yêu cầu của chủ dự án; mỗi nút icon có tooltip và Semantics để vẫn đọc được bằng TalkBack.
7. **Bỏ khối hiển thị quy tắc nghiệp vụ (BR) thô**:
   - *Ban đầu*: Các màn hình có khung chữ nhật in văn bản quy tắc BR khô khan.
   - *Hiện tại*: Bỏ khối này khỏi giao diện.
   - *Lý do*: Yêu cầu của chủ dự án: khối chữ quy tắc không giúp thao tác tại quầy.
8. **Chuyển đổi nguồn dữ liệu chính từ Gateway .NET sang Cloud Firestore**:
   - *Ban đầu*: Gọi Gateway YARP .NET 8 cục bộ qua HTTP.
   - *Hiện tại*: Sử dụng Cloud Firestore real-time với hệ thống Security Rules chặt chẽ (`AppServices.firebase()`).
   - *Lý do*: Backend .NET chưa được triển khai lên hạ tầng cloud công cộng và quy định chấm Final cấm dựng server riêng ngoài phạm vi cho phép; Firestore đảm bảo tính sẵn sàng cao, đồng bộ tức thì và bảo mật phân quyền.
