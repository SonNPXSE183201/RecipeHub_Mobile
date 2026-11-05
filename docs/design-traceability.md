# Truy vết thiết kế – yêu cầu → màn hình → MVVM → dịch vụ → kiểm thử

Nguồn yêu cầu: `requirements-draft.md` mục 10 (M-01 → M-17). Thiết kế UI: `DESIGN.md`, `ux/`.
Mã ca kiểm thử: `TC-xx` = test Flutter trong `test/artemis_e2e_test.dart`; `ART-xx` = ca ARTEMIS chạy trên thiết bị, xem `docs/artemis-test-plan.md`.

## Ma trận truy vết

| Mã | Màn hình (View) | File | ViewModel | Service interface → triển khai | Event Analytics | Kiểm thử |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| M-01 | Đăng nhập | `features/auth/login_page.dart`, `auth_gate.dart` | `AuthViewModel` | `IAuthService` → `FirebaseAuthService` (Google, Anonymous) | `login`, `logout` | TC-01, TC-02, TC-03, TC-10, ART-01, ART-02, ART-03 |
| M-02 | Tra cứu tại quầy | `features/lookup/counter_recipe_lookup_page.dart` | `RecipeViewModel`, `AppConfigViewModel` | `IRecipeSource` → `GatewayRecipeSource` (Gateway thật); `IRemoteConfigService` → `FirebaseRemoteConfigService` | – | TC-04, TC-05, TC-09, TC-10, ART-04, ART-05, ART-10 |
| M-03 | Chi tiết công thức | `features/lookup/recipe_detail_size_page.dart` | `RecipeViewModel` | `IAnalyticsService` | `view_recipe` | TC-08, ART-04, ART-09 |
| M-04 | Hướng dẫn theo bước/video | `features/lookup/step_video_guide_page.dart` | – (dữ liệu từ `RecipeItem`) | – | – | Khám phá |
| M-05 | Thư viện SOP | `features/sop/sop_catalog_page.dart` | – | `MockDataService` (chưa có API) | – | Khám phá |
| M-06 | Chi tiết SOP | `features/sop/sop_detail_page.dart` | – | `MockDataService`; deep link FCM `type=sop` | – | Khám phá |
| M-07 | Việc học của tôi | `features/learning/my_learning_page.dart` | – | `MockDataService` | – | Khám phá |
| M-08 | Chi tiết nhiệm vụ học | `features/learning/learning_task_detail_page.dart` | – | `MockDataService`; deep link `type=task` | – | Khám phá |
| M-09 | Tiến độ cá nhân | `features/learning/personal_progress_page.dart` | – | `MockDataService` | – | Khám phá |
| M-10 | Thông báo | `features/learning/notifications_page.dart` | `NotificationViewModel` | `INotificationService` → `FirebaseNotificationService` (FCM) | – | TC-08, ART-09 |
| M-11 | Tạo phản hồi | `features/feedback/create_feedback_page.dart` | `StorageViewModel` | `IStorageService` → `FirebaseStorageService` (`feedback/{uid}/`); `IMediaPickerService` | `submit_feedback` | TC-06, TC-07, ART-07 |
| M-12 | Phản hồi của tôi | `features/feedback/my_feedback_list_page.dart` | – | `MockDataService` (chưa có API phản hồi) | – | ART-07 |
| M-13 | Tài khoản | `features/account/account_profile_page.dart` | `AuthViewModel` | `IAuthService`, `ICrashReporter` → `FirebaseCrashReporter` | `logout` | ART-01 (đăng xuất), kiểm thử Crashlytics thủ công |
| M-14 | Tự luyện và bấm giờ | `features/practice/self_practice_timer_page.dart` | – | `IAnalyticsService` | `start_brew_timer`, `complete_brew_timer` | ART-06 |
| M-15 | Lịch sử tự luyện | `features/practice/practice_history_page.dart` | `StorageViewModel` | `IStorageService` (`reports/{uid}/`) + `PracticeReportPdf` | `export_report_pdf` | ART-08 |
| M-16 | Làm bài quiz | `features/practice/quiz_exam_page.dart` | – | `MockDataService` | – | Khám phá |
| M-17 | Kết quả đánh giá thực hành | `features/practice/practical_evaluation_page.dart` | – | `MockDataService` | – | Khám phá |
| Admin | Bảng theo dõi đào tạo chi nhánh | `features/admin_training/admin_store_training_page.dart` | `AuthViewModel` (vai trò) | `MockDataService` | – | Khám phá |
| Hệ thống | Đang tải / Lỗi | `features/system/loading_transition_page.dart`, `error_recovery_page.dart` | `RecipeViewModel` | – | – | ART-05 |

## 6 dịch vụ Firebase → nơi dùng → bằng chứng

| Dịch vụ | Nơi khởi tạo | Kiểm chứng trên Redmi 7 (05/11/2026) |
| :-- | :-- | :-- |
| Authentication | `AuthViewModel` | ART-01/02/03: Google thành công, hủy chọn tài khoản, mất mạng |
| Cloud Storage | `StorageViewModel` | ART-07/08: object xuất hiện trong `feedback/{uid}/`, `reports/{uid}/`; ảnh > 5MB bị chặn |
| Cloud Messaging | `NotificationViewModel` | ART-09: foreground (banner), background, terminated → mở đúng M-03 |
| Analytics | `IAnalyticsService` | Đủ 7 event trong log `FA-SVC`, không PII |
| Crashlytics | `firebase_bootstrap.dart` + `ICrashReporter` | Non-fatal `demo_non_fatal` (custom key), crash thật (report `6AEBAA1D…`) |
| Remote Config | `AppConfigViewModel` | ART-10: đổi `max_lookup_results` trên server, danh sách đổi real-time |

## Web Admin + Cloud Functions (plan 261105-admin-web-firebase)

| Yêu cầu | Web (View → ViewModel) | Function / dữ liệu | Mobile | Kiểm thử |
| :-- | :-- | :-- | :-- | :-- |
| FR-01 Admin đăng nhập, non-admin bị chặn | `login_page`, `forbidden_page` → `AdminAuthViewModel` | `ensureProfile`, claim `role` | – | W-01..03, ART-14 |
| FR-02/03 Danh sách user, đổi vai trò | `users_page` → `UsersViewModel` | `setUserRole`, `users/` | `AuthViewModel` nghe `claimsUpdatedAt` | W-08, F04, TC-14/17, ART-15 |
| FR-04 Khóa / mở khóa | `users_page` | `setUserDisabled` | `AuthViewModel` nghe `disabled` | F05, TC-15, ART-13 |
| FR-05..07 Gửi thông báo, lịch sử | `notifications_page` → `NotificationsViewModel` | `sendNotification`, `notifications/`, `devices/` | `NotificationViewModel` + `IDeviceRegistry` | W-07, F06/07, TC-16, ART-11 |
| FR-08 Nút Gây crash | – | – | `account_profile_page` + `IIncidentReporter` | TC-18/20, ART-12 |
| FR-09..11 Sự cố real-time, xử lý, thống kê | `incidents_page`, `dashboard_page` → `IncidentsViewModel`, `DashboardViewModel` | `incidents/`, `onIncidentCreated/Updated`, `onCrashlyticsNewFatal`, `stats/` | `FirestoreIncidentReporter` | W-05/06/09, F08/09, R07..14, ART-12 |
| FR-12 Quản lý món | `recipes_page`, `recipe_form_dialog` → `RecipesViewModel` | `recipes/`, `seedRecipes` | `FirestoreRecipeSource` | W-10/11, F10, TC-21, R16/17, ART-16 |
| FR-13 Crash thật báo bù | – | – | `FirebaseBootstrap.attachIncidentReporter` | TC-19 |
| FR-14 Không theo dõi thao tác user cho Admin | Web không có màn hành vi | – | Analytics chỉ ở Console | rà code |

## Lệch thiết kế đã biết

- `create_feedback_page.dart` gọi `services.analytics.logSubmitFeedback` trực tiếp từ View (không qua ViewModel). Không gọi Firebase SDK trực tiếp, vẫn qua interface.
- M-05 → M-09, M-12, M-16, M-17 dùng dữ liệu cục bộ vì backend chưa có API (xem `docs/mobile-backend-api-gaps.md`).
- `view_recipe.source` luôn là `lookup`, kể cả khi mở từ thông báo FCM.
