# Kiến trúc mobile (MVVM + Provider)

```
View (features/*)  →  ViewModel (core/viewmodels/*, ChangeNotifier)  →  Service Interface (core/services/interfaces/*)
                                                                        ├─ Firebase impl (core/services/firebase/*)
                                                                        └─ Mock impl (core/services/mock/*)  ← chỉ dùng cho test / máy chưa cấu hình Firebase
```

- View không import Firebase SDK; chỉ đọc ViewModel qua `context.watch/read` hoặc gọi `AppServices` cho sự kiện analytics.
- `AppServices` (core/di) là composition root: `AppServices.firebase()` cho production, `AppServices.mock(recipes: …)` cho test.
- Công thức luôn đi qua `IRecipeSource` → `GatewayRecipeSource` → `RecipeService` (Dio, Gateway thật). Test truyền fake source.
- `AuthGate` điều phối phiên: Loading → Login | tải công thức → Shell; xử lý banner FCM, deep link, primer quyền thông báo.
- Dữ liệu chưa có API backend (SOP, nhiệm vụ, quiz, phản hồi…) nằm trong `MockDataService` (cục bộ); xem `docs/mobile-backend-api-gaps.md`.

## 6 dịch vụ Firebase

| Dịch vụ | Interface | Điểm dùng |
| :--- | :--- | :--- |
| Authentication | `IAuthService` | Google Sign-In, Anonymous; `AuthViewModel` |
| Cloud Storage | `IStorageService` | `feedback/{uid}/…` ảnh, `reports/{uid}/…` PDF; `StorageViewModel`; rules ở `src/firebase/storage.rules` |
| Cloud Messaging | `INotificationService` | Foreground/background/terminated, deep link `data.type` + `data.target_id`; `NotificationViewModel` |
| Analytics | `IAnalyticsService` | 7 sự kiện, xem `docs/analytics-plan.md` |
| Crashlytics | `ICrashReporter` | `FlutterError.onError`, `PlatformDispatcher.onError`, non-fatal, user id, custom keys; crash demo ẩn (Admin, nhấn giữ "CÀI ĐẶT ỨNG DỤNG") |
| Remote Config | `IRemoteConfigService` | `enable_ai_assist` (false), `max_lookup_results` (50); `AppConfigViewModel` |

Bảo mật: `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` nằm trong `.gitignore`. Client ID cho Google Sign-In và URL Gateway truyền qua `--dart-define` (`GOOGLE_SERVER_CLIENT_ID`, `API_BASE_URL`), không ghi vào mã nguồn.

## Cấu hình Firebase phía server

Cấu hình Firebase dùng chung cho mobile, web Admin và Cloud Functions nằm ở `src/firebase/` (`firebase.json`, `.firebaserc`, project `recipehub-mobile`). Deploy chạy trong thư mục đó:

```
cd src/firebase
npx -y firebase-tools@13.29.1 deploy --only storage        # storage.rules
npx -y firebase-tools@13.29.1 deploy --only remoteconfig   # remoteconfig.template.json
```

Chi tiết: `src/firebase/README.md`.

## Nối với web Admin (Firebase)

App và web Admin (`src/admin_web`) dùng chung project Firebase; "code server" là Cloud Functions trong `src/firebase/functions`.

| Service mới (interface → Firebase / Mock) | Việc làm | Dữ liệu |
| :-- | :-- | :-- |
| `IUserProfileService` → `FirebaseUserProfileService` | Gọi callable `ensureProfile` sau đăng nhập; đọc vai trò từ custom claim `role`; nghe `users/{uid}` (bị khóa → đăng xuất, `claimsUpdatedAt` đổi → làm mới token) | `users/{uid}` |
| `IDeviceRegistry` → `FirestoreDeviceRegistry` | Lưu FCM token khi đăng nhập / `onTokenRefresh`; xóa trước khi đăng xuất | `users/{uid}/devices/{sha256(token)}` |
| `IIncidentReporter` → `FirestoreIncidentReporter` | Báo sự cố cho web Admin (song song Crashlytics): nút Gây crash, lỗi fatal trong handler, crash lần chạy trước | `incidents/` |
| `IRecipeSource` → `FirestoreRecipeSource` (mặc định) / `GatewayRecipeSource` | Món do Admin quản lý trên web; chọn bằng `--dart-define=RECIPE_SOURCE=gateway` để quay về API .NET | `recipes/{code}` |

Luồng chính:

```
Đăng nhập → ensureProfile (Function) → claim role → AuthViewModel.role
          → NotificationViewModel.start(uid) → getToken → devices/{id} + subscribe all_staff
Web "Gửi" → sendNotification (Function, Admin SDK) → FCM → onMessage / khay → DeepLinkRouter
Nút "Gây crash" → incidents.add (await) → markCrashAlreadyReported → Crashlytics.crash()
          → web nghe incidents (real-time) → banner + âm báo; Crashlytics Console sau vài phút
Admin khóa → setUserDisabled (Auth disabled + users.disabled) → app nghe users/{uid} → đăng xuất
```

Vai trò không còn chọn tự do ở màn đăng nhập: claim do server cấp quyết định; Admin vẫn chuyển sang "xem như Barista" ở màn Tài khoản. Snapshot từ cache offline bị bỏ qua để không đăng xuất nhầm.

## Chạy trên máy thật với Gateway local

Chỉ cần khi `RECIPE_SOURCE=gateway`; mặc định món lấy từ Firestore.

```
adb reverse tcp:5000 tcp:5000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5000 --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>
```

## Lệch kiến trúc đã biết

- `features/feedback/create_feedback_page.dart` gọi `AppServices.analytics` trực tiếp từ View để log `submit_feedback`. Vẫn đi qua interface `IAnalyticsService`, không gọi Firebase SDK; nên chuyển vào `StorageViewModel` hoặc một `FeedbackViewModel` khi refactor.
- Đã sửa: `counter_recipe_lookup_page.dart` trước đây đọc danh sách từ `MockDataService.recipes`; nay `watch` `RecipeViewModel.items` để tự rebuild khi Remote Config tăng `max_lookup_results` và danh sách được tải lại ngầm.
- Truy vết đầy đủ yêu cầu → màn hình → ViewModel → service → ca kiểm thử: `docs/design-traceability.md`.
