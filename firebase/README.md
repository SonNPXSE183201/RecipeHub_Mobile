# Firebase – gốc cấu hình chung

Cấu hình Firebase của project `recipehub-mobile`, dùng chung cho app mobile (`src/mobile`), web Admin (`src/admin_web`) và Cloud Functions. Kế hoạch: `docs/plans/261105-admin-web-firebase/`.

```
src/firebase/
  firebase.json               firestore, storage, remoteconfig, functions, hosting, emulators
  .firebaserc                 project mặc định: recipehub-mobile
  firestore.rules             Firestore security rules
  firestore.indexes.json      composite indexes
  storage.rules               Storage rules (feedback/{uid}, reports/{uid}; ảnh ≤ 5 MB)
  remoteconfig.template.json  enable_ai_assist, max_lookup_results, show_crash_demo
  functions/                  Cloud Functions (TypeScript, Node 22; dữ liệu món mẫu ở functions/src/data)
```

## Yêu cầu

- Node.js 22, Java 17 (cho Emulator Firestore/Storage).
- Firebase CLI: `npx -y firebase-tools@13.29.1` (không cần cài global).
- Đăng nhập một lần: `npx -y firebase-tools@13.29.1 login`.

## Tham số Functions (không commit)

Tạo `functions/.env.recipehub-mobile` từ `functions/.env.example`:

```
ADMIN_EMAILS=email1@example.com,email2@example.com
```

User đăng nhập lần đầu có email trong danh sách sẽ được cấp custom claim `role=admin`.

## Emulator

```bash
cd src/firebase
npx -y firebase-tools@13.29.1 emulators:start --only auth,firestore,storage,functions
# UI: http://localhost:4000 · Hosting: 5050 (tránh trùng Gateway 5000)
```

## Deploy

Chạy trong `src/firebase`:

```bash
npx -y firebase-tools@13.29.1 deploy --only firestore        # rules + indexes
npx -y firebase-tools@13.29.1 deploy --only storage
npx -y firebase-tools@13.29.1 deploy --only remoteconfig
npx -y firebase-tools@13.29.1 deploy --only functions
npx -y firebase-tools@13.29.1 deploy --only hosting          # cần build src/admin_web vào src/firebase/hosting trước
```

Build web Admin: xem `src/admin_web/README.md` (`flutter build web --release --dart-define-from-file=env/firebase_web.json -o <đường dẫn tuyệt đối>/src/firebase/hosting` — thiếu `--dart-define-from-file` thì web chỉ hiện "Thiếu cấu hình Firebase web").

## Cloud Functions

| Function | Loại | Việc làm |
| :-- | :-- | :-- |
| `ensureProfile` | callable | Gọi sau đăng nhập (mobile + web): tạo `users/{uid}` nếu thiếu, đặt claim `role` (admin nếu email thuộc `ADMIN_EMAILS`), cập nhật `lastSeenAt` |
| `onUserCreated`, `onUserDeleted` | Auth trigger (v1) | Tạo / xóa hồ sơ, cập nhật `stats/summary` |
| `setUserRole`, `setUserDisabled` | callable (admin) | Đổi claim vai trò; khóa / mở khóa Auth + thu hồi token + hủy topic |
| `backfillUsers` | callable (admin) | Tạo hồ sơ cho user có từ trước |
| `sendNotification` | callable (admin) | FCM HTTP v1 qua Admin SDK: topic `all_staff` hoặc token trong `users/{uid}/devices`; xóa token chết; ghi `notifications/` |
| `onDeviceWritten` | Firestore trigger | Đếm lại `users/{uid}.deviceCount` |
| `onIncidentCreated`, `onIncidentUpdated` | Firestore trigger | Thống kê `stats/incidents/days/{yyyy-MM-dd}`, `openIncidents` |
| `onCrashlyticsNewFatal` | Crashlytics alert | Issue fatal mới → `incidents/` loại `crashlytics_issue` |
| `seedRecipes` | callable (admin) | Nạp 6 món mẫu (`functions/src/data/recipes.seed.json`) |

Kiểm thử trên Emulator: `cd functions && npm test` (rules + handler, FCM thay bằng bản giả vì không có emulator).

## Lưu ý khi deploy

- Runtime Node.js 22 (Node 20 đã ngừng từ 31/10/2026).
- CLI có thể cảnh báo "Unhandled error cleaning up build images": ảnh build cũ còn trong Artifact Registry (`gcf-artifacts`, region asia-southeast1). Xóa tay trên Google Cloud Console hoặc đặt cleanup policy để tránh phí lưu trữ nhỏ.

Lần đầu deploy Functions, CLI tự bật Cloud Functions, Cloud Build, Artifact Registry, Eventarc, Cloud Run API. Nếu báo lỗi quyền Eventarc, chờ 1–2 phút rồi deploy lại.

**Lưu ý Remote Config:** deploy template sẽ ghi đè giá trị đang chạy trên server bằng giá trị trong file. Đổi giá trị để demo thì sửa trên Console hoặc sửa file rồi deploy.
