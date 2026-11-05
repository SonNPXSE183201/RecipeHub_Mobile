# RecipeHub Mobile

Ứng dụng Flutter (`recipehub_mobile`) cho barista và quản lý cửa hàng: tra cứu công thức tại quầy, học và thực hành theo SOP, gửi phản hồi chất lượng. Môn PRM393.

Thiết kế Figma: https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub (key `FycUpbP0PtH6Q4sg6IvZr6`).

## Phạm vi
- 2 vai trò: **Barista (Viewer)** và **Quản lý cửa hàng (Admin)**. Soạn công thức, duyệt, xuất PDF, quản lý người dùng nằm ở web (R&D), không có trên mobile.
- 20 màn hình: `M-01` đến `M-17`, `AdminStoreTrainingPage` (tab Đào tạo của Admin) và 2 màn hình hệ thống (Loading, Error recovery). Chi tiết: `ux/user-flow.md`.
- Dữ liệu hiện là mock trong bộ nhớ (`lib/core/services/mock_data_service.dart`), chưa gọi API backend.

## Cấu trúc
```
lib/
  main.dart                      Khởi chạy app; có máy chủ automation cổng 8888 để chụp màn hình (dev)
  core/models/                   app_models.dart (đang dùng), content_models.dart, recipe_models.dart
  core/services/mock_data_service.dart
  core/theme/nomad_kit.dart      Token NomadKit
  core/widgets/                  recipe_hub_logo.dart, screen_frame.dart
  features/                      auth, shell, lookup, sop, learning, feedback, practice, account, admin_training, system
assets/icons, assets/illustrations   PNG đang được code tham chiếu (không giữ ảnh thừa)
ux/                              persona.md, user-flow.md
DESIGN.md, design-decisions.md, flutter-handoff.md
```

## Firebase (Lab 3)

**Đã cấu hình trên Console:** project `recipehub-mobile` (Blaze); app Android `com.recipehub.mobile` với SHA-1 và SHA-256; Authentication bật Google Sign-In và Anonymous; Cloud Storage đã publish `storage.rules` (giới hạn 5 MB, kiểm MIME ảnh); FCM API (V1) bật; Remote Config có `enable_ai_assist` (bool, mặc định `false`) và `max_lookup_results` (số, mặc định `50`).
**Trong repo (đã tích hợp):** `google-services.json` được `.gitignore` (không commit); plugin Gradle `google-services` + Crashlytics; `provider` và 6 gói `firebase_*` trong `pubspec.yaml`; kiến trúc MVVM (`lib/core/viewmodels`, `lib/core/services/{interfaces,firebase,mock}`, `lib/core/di/app_services.dart`); `firebase/storage.rules`; `docs/analytics-plan.md`, `docs/architecture.md`.
**Dữ liệu:** công thức lấy từ Gateway thật (không còn mock fallback); phần chưa có API backend nằm trong `docs/mobile-backend-api-gaps.md`.
**Test:** `test/artemis_e2e_test.dart` (10 ca) và `test/widget_test.dart`.

## Chạy
```
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://<ip-may-chay-Gateway>:5000   # bỏ define khi dùng Android emulator (tự dùng 10.0.2.2:5000)
```
Cần chạy backend (Gateway `:5000`) và có ít nhất một công thức ở trạng thái Approved.

## Tài liệu
- `DESIGN.md`: token và thành phần NomadKit.
- `flutter-handoff.md`: ánh xạ token sang `ThemeData`, cấu trúc mã nguồn, danh sách asset.
- `design-decisions.md`: quyết định thiết kế và đánh giá UX/WCAG.
- `ai-design-log.md`: nhật ký AI của vòng thiết kế Lab 2 (tài liệu lịch sử, mô tả bản 3 vai trò cũ).
- `ux/persona.md`, `ux/user-flow.md`: persona, luồng, danh mục màn hình.
