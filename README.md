# RecipeHub Mobile – PRM393 Lab 3 (SE183201)

Ứng dụng Flutter cho Barista và quản lý cửa hàng chuỗi đồ uống: tra cứu công thức chuẩn, sổ tay SOP, việc học + quiz, chấm thực hành tại quầy, phản hồi có ảnh với quản lý (real-time). Dữ liệu thật trên **Cloud Firestore** (dự án Firebase `recipehub-mobile`); nội dung công thức lấy từ *Bộ công thức Phê La* (61 món, 25 SOP) đã chuẩn hóa.

Thiết kế Figma (Lab 2): https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub

> Repo nộp Lab 3 theo cấu trúc §9 của đề. Final Assignment sẽ tiếp tục chính repo này (đổi tên `PRM393_Final_SE183201`, dời app vào `mobile/`).

## Bản đồ deliverable

| Đề yêu cầu | Trong repo | Trạng thái |
| :-- | :-- | :-- |
| `lib/` (MVVM) | `lib/core/{models,services,viewmodels,widgets,theme}`, `lib/features/*` | Có |
| `android/` (kèm `google-services.json`) | `android/` | `google-services.json` **không commit**: tải từ Firebase Console → Project settings → app `com.recipehub.mobile`, đặt vào `android/app/` |
| `firebase/storage.rules`, `firebase/remote-config-defaults.json` | `firebase/` (+ `firestore.rules`, `firestore.indexes.json`, `remoteconfig.template.json`) | Có |
| `e2e_test/` (ARTEMIS pytest) | `e2e_test/` | **Đang làm** |
| `docs/design-traceability.md`, `architecture.md`, `analytics-plan.md` | `docs/` | Có |
| `docs/test-plan.md`, `docs/code-review.md` | `docs/` | **Đang làm** (`docs/artemis-test-plan.md` là bản cũ dùng runner adb) |
| `evidence/` | `evidence/lab3/` | Có (ảnh Redmi 7, xem `evidence/README.md`) |
| `report/Lab03_SE183201.pdf`, `slides/Lab03_SE183201_slides.pdf` | `report/`, `slides/` | **Đang làm** |
| Video demo | mục cuối | **Đang làm** |
| Đặc tả Lab 2 | `docs/lab2/` (`DESIGN.md`, `flutter-handoff.md`, `ux/`) | Có |

## Chạy app

Yêu cầu: Flutter **3.47.2** (Dart 3.13.2), Android SDK, thiết bị Android 10+.

```bash
flutter pub get
# GOOGLE_SERVER_CLIENT_ID = OAuth client loại Web (client_type 3) trong google-services.json
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
```

Đăng nhập bằng email/mật khẩu do Admin cấp, hoặc Google. Vai trò (`viewer` = Barista, `admin` = quản lý) đọc từ hồ sơ `users/{uid}`.

## Kiểm thử

```bash
flutter analyze        # 0 issue
flutter test           # 161 test (unit + widget)
```

Security Rules được kiểm bằng Firebase Emulator (57 ca allow/deny) trong repo nhóm; sẽ chuyển vào `firebase/tests/` ở Final.

## Dữ liệu và công cụ

- `tools/seed/*.json`: dữ liệu chuẩn hóa từ Bộ công thức Phê La (công thức theo size, SOP, quiz, nhiệm vụ học, tiêu chí chấm). Nạp bằng nút "Nạp bộ công thức Phê La" trên web Admin (Admin ghi qua Security Rules).
- `tools/video/make_videos.py`: dựng video minh hoạ từng bước từ dữ liệu công thức (Python + Pillow + ffmpeg); mỗi đoạn dài đúng thời lượng bước để khớp mốc video trong app.

## Phiên bản chính

`provider ^6.1.2`, `firebase_core ^4.2.0`, `firebase_auth ^6.1.0`, `cloud_firestore ^6.10.2`, `firebase_storage ^13.0.3`, `firebase_messaging ^16.0.3`, `firebase_analytics ^12.0.3`, `firebase_crashlytics ^5.0.3`, `firebase_remote_config ^6.1.0`, `google_sign_in ^7.2.0`, `video_player ^2.11.0` (khóa chính xác trong `pubspec.lock`).

## Công cụ AI đã dùng

- **Claude Code**:
  - Opus 5.5: điều phối, review, tích hợp, kiểm thử trên thiết bị.
  - Sonnet 5.5: từng nhóm màn hình, trích xuất dữ liệu.
- **Codex CLI** (`gpt-6.1-sol`, effort medium): đăng nhập email, lưu PDF, sổ tay PDF, tinh chỉnh UI mobile.
- **Antigravity CLI** (Gemini 4 Argon, Gemini 3.8 Flash): web Admin (design system, form món, video).
- Mọi thay đổi đều được chạy `flutter analyze` + `flutter test` và kiểm trên Redmi 7 trước khi commit.

## Video demo

_Chưa có._
