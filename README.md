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
| `e2e_test/` (ARTEMIS pytest) | `e2e_test/` | 24 ca; đã chạy 3 vòng trên Redmi 7: 18/19 ca tự động PASS ≥ 1 vòng, 49/55 lượt-ca PASS |
| `docs/design-traceability.md`, `architecture.md`, `analytics-plan.md` | `docs/` | Có |
| `docs/test-plan.md`, `docs/code-review.md` | `docs/` | `test-plan.md` có kết quả ARTEMIS (mục 5.1); `code-review.md` đã có (19 phát hiện, 15 đã sửa) và `coderabbit-followup.md` cho PR #3–#6. `artemis-test-plan.md` là runner adb cũ |
| `evidence/` | `evidence/lab3/` | Có (ảnh Redmi 7, xem `evidence/README.md`) |
| `report/Lab03_SE183201.pdf`, `slides/Lab03_SE183201_slides.pdf` | `report/`, `slides/` | Có nguồn Markdown/PPTX và PDF, đã gồm kết quả ARTEMIS (báo cáo mục 8.2, slide 13) |
| Video demo | mục cuối | Đã dựng (16:9 và 9:16, ~6 phút 22 giây); chờ upload và gắn link |
| Đặc tả Lab 2 | `docs/lab2/` (`DESIGN.md`, `flutter-handoff.md`, `ux/`) | Có |

## Chạy app

Yêu cầu: Flutter **3.47.2** (Dart 3.13.2), Android SDK, thiết bị Android 10+.

```bash
flutter pub get
# Thay toàn bộ placeholder bằng Web OAuth client ID đầy đủ, gồm .apps.googleusercontent.com
# GOOGLE_SERVER_CLIENT_ID = OAuth client loại Web (client_type 3) trong google-services.json
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID="<WEB_CLIENT_ID_FULL_WITH_APPS_GOOGLEUSERCONTENT_COM>"
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID="<WEB_CLIENT_ID_FULL_WITH_APPS_GOOGLEUSERCONTENT_COM>"
```

Đăng nhập bằng email/mật khẩu do Admin cấp, hoặc Google. Vai trò (`viewer` = Barista, `admin` = quản lý) lấy từ custom claim `role` trong ID token sau `ensureProfile`. App theo dõi `users/{uid}` để xử lý khóa tài khoản và thay đổi claim; nếu refresh token lỗi thì dùng `users/{uid}.role` vừa nhận từ server.

Google Sign-In trên Android cần đăng ký SHA-1 của chứng chỉ debug/release tương ứng tại Firebase Console → Project settings → Android app. Chạy từ repo root:

```bash
cd android && ./gradlew signingReport
```

PowerShell: `cd android; .\gradlew.bat signingReport`. Sau đó trở về repo root trước khi chạy Flutter.

## Kiểm thử

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Kết quả 09/11/2026: `flutter analyze` 0 issue; `flutter test` 286/286 pass.

ARTEMIS (Google, commit ghim `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`, model Gemini 3.5/3.1 Flash-Lite): cách chạy ở `e2e_test/README.md`, kết quả 3 vòng ở `docs/test-plan.md` mục 5.1. FCM thủ công có ảnh trong `docs/test-plan.md` §6. Analytics có ảnh `evidence/lab3/06-firebase-console/01-analytics-events.jpg` (GA4 Events); repo không có file log logcat Analytics.

Security Rules được ghi nhận đã kiểm bằng Firebase Emulator (57 ca allow/deny) trong repo nhóm; sẽ chuyển vào `firebase/tests/` ở Final.

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
- **CodeRabbit** và **Codex CLI review**: review PR (`docs/code-review.md`).
- **Google ARTEMIS** (Gemini Flash-Lite): kiểm thử E2E trên thiết bị.
- Chỉ ghi nhận các kiểm tra có bằng chứng tương ứng; ca chưa đạt hoặc thủ công được nêu riêng tại `docs/test-plan.md`.

## Video demo

_Link sẽ cập nhật sau khi upload._
