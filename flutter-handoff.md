# RecipeHub Mobile — Flutter Handoff

Figma: https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub (key `FycUpbP0PtH6Q4sg6IvZr6`).
Tài liệu này khớp với code trong `lib/` (2 vai trò Viewer / Admin, 17 màn hình + Admin Đào tạo + 2 màn hình hệ thống). Danh mục màn hình: `ux/user-flow.md`.

## 1. Ánh xạ token sang Flutter (`lib/core/theme/nomad_kit.dart`)

| Token | Hex | Code |
| :--- | :--- | :--- |
| Vàng cát (chính) | `#C49A6C` | `NomadKit.sand` |
| Nâu nhãn | `#A07040` | `NomadKit.sandDark` |
| Nền thẻ nhấn | `#FAF6F0` | `NomadKit.sandLight` |
| Thông tin | `#0891B2`, nền `#F0F9FF` | `NomadKit.ocean`, `oceanLight` |
| Đạt, hoàn thành | `#166534`, nền `#DCFCE7` | `NomadKit.forest`, `forestLight` |
| Cảnh báo, nháp | `#CA8A04`, nền `#FEF9C3` | `NomadKit.warning`, `warningLight` |
| Lỗi | `#DC2626` | `NomadKit.error` |
| Chữ chính | `#292524` | `NomadKit.ink` |
| Chữ phụ | `#78716C` | `NomadKit.secondary` |
| Nền | `#FFFDF7` | `NomadKit.canvas` |
| Thẻ | `#FFFFFF` | `NomadKit.surface` |
| Viền 1 dp | `#E7E0D5` | `NomadKit.border` |

Bo góc: 4 (badge), 8 (ô nhập), 14 (thẻ), 16 (nút, hộp thoại), pill (chip). Nút cao 52 dp, vùng chạm tối thiểu 48 dp, lề ngang 16 dp.
Hiện `NomadKit` chưa có `ThemeData` tập trung; màu và kích thước được dùng trực tiếp trong từng màn hình.

## 2. Thương hiệu
- Logo: `assets/icons/app_logo_hero_2k.png` qua `RecipeHubLogo` (icon `Icons.coffee_rounded` làm dự phòng).
- Thanh trên: logo, tên thương hiệu, chuông thông báo. Thanh dưới: 4 tab trong `MainAppShell` (Tra cứu, Việc học hoặc Đào tạo, Phản hồi, Tài khoản) dùng icon PNG `nav_*` và `nav_*_active`.

## 3. Cấu trúc mã nguồn
```
lib/main.dart                       Khởi chạy; máy chủ automation cổng 8888 (dev) để chụp màn hình theo ?name=
lib/core/models/app_models.dart     UserRole {viewer, admin}, recipe, SOP, task, feedback, practice, quiz
lib/core/services/mock_data_service.dart   Dữ liệu mock trong bộ nhớ (singleton)
lib/core/theme/nomad_kit.dart       Token màu
lib/core/widgets/                   recipe_hub_logo.dart, screen_frame.dart
lib/features/
  auth/login_page.dart              M-01
  shell/main_app_shell.dart         Khung 4 tab, chuông thông báo
  lookup/                           M-02 M-03 M-04
  sop/                              M-05 M-06
  learning/                         M-07 M-08 M-09 M-10
  feedback/                         M-11 M-12
  account/                          M-13
  practice/                         M-14 M-15 M-16 M-17
  admin_training/                   Tab Đào tạo của Admin
  system/                           Loading, Error recovery
```
Màn hình đổi giữa Viewer và Admin qua `MockDataService.instance.switchRole`.

## 4. Asset đang dùng (có tham chiếu trong `lib/`)
- `assets/icons/app_logo_hero_2k.png`
- `assets/icons/icon_alert_triangle.png`
- `assets/icons/icon_beaker_ratio.png`
- `assets/icons/icon_check_circle.png`
- `assets/icons/icon_evaluation_rubric.png`
- `assets/icons/icon_feedback_pencil.png`
- `assets/icons/icon_quiz_exam.png`
- `assets/icons/icon_recipe_book.png`
- `assets/icons/icon_search.png`
- `assets/icons/icon_sop_protocol.png`
- `assets/icons/icon_sparkle_ai.png`
- `assets/icons/icon_store_branch.png`
- `assets/icons/icon_thermometer_cold.png`
- `assets/icons/icon_timer_brew.png`
- `assets/icons/icon_user_profile.png`
- `assets/icons/icon_video_guide.png`
- `assets/icons/nav_account.png`
- `assets/icons/nav_account_active.png`
- `assets/icons/nav_bell.png`
- `assets/icons/nav_bell_active.png`
- `assets/icons/nav_feedback.png`
- `assets/icons/nav_feedback_active.png`
- `assets/icons/nav_home.png`
- `assets/icons/nav_home_active.png`
- `assets/icons/nav_learning.png`
- `assets/icons/nav_learning_active.png`
- `assets/icons/nav_training.png`
- `assets/icons/nav_training_active.png`
- `assets/illustrations/empty_search_2k.png`
- `assets/illustrations/mastery_badge_2k.png`
- `assets/illustrations/offline_recovery_2k.png`

Quy tắc: thêm ảnh thì phải có tham chiếu trong code; ảnh không còn tham chiếu thì xóa. `pubspec.yaml` khai báo `assets/icons/` và `assets/illustrations/`.

## 5. Firebase
Console đã cấu hình xong (Auth Google + Anonymous, Storage + rules, FCM V1, Remote Config với `enable_ai_assist`, `max_lookup_results`), `google-services.json` đã nằm ở `android/app/`. Phần code SDK chưa tích hợp: cần thêm `provider`, `firebase_core/auth/storage/messaging/analytics/crashlytics/remote_config`, `google_sign_in`, plugin Gradle `google-services` và Crashlytics, quyền `INTERNET` và `POST_NOTIFICATIONS`. Kiến trúc đích: View, ViewModel (Provider), Service Interface, rồi Firebase hoặc Mock; View không gọi SDK trực tiếp. Chi tiết: `docs/plans/261104-lab3-firebase-integration/plan.md`.

## 6. Chụp màn hình và Figma
- Chạy app trên emulator, máy chủ automation nhận `http://<thiết bị>:8888/?name=m01_login` (các tên: `m01_login` đến `m17_practical_evaluation`, `admin_store_training`, `28_system_loading_transition`, `29_system_error_recovery`).
- Plugin Figma nối prototype nằm ở `tools/figma-prototype-plugin/` (ngoài repo mobile), xem README của plugin.
