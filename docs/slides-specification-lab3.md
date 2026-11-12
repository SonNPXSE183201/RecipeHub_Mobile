# ĐẶC TẢ BỘ SLIDE BÁO CÁO LAB 3 – RECIPEHUB MOBILE
## Bố cục Chuẩn Thầy Mai (What/Why – How – Where) & Phong cách Group 5
**Dự án:** RecipeHub Mobile (PRM393 – FPT University)  
**File tham chiếu:** `EXE Team Matching - Lab3 Firebase & MVVM - Group 5.pptx`  
**Cập nhật:** 12/11/2026

---

## MỤC LỤC BỘ SLIDE (TỔNG HỢP 22 CÔNG NGHỆ & CÔNG CỤ)

### PHẦN MỞ ĐẦU
- **Slide 01:** Trang bìa (Title Slide)
- **Slide 02:** Tổng quan dự án RecipeHub Mobile & Hai vai trò (Barista vs Store Admin)

---

### NHÓM 1: KIẾN TRÚC & QUẢN LÝ TRẠNG THÁI
1. **Mô hình kiến trúc MVVM (Model - View - ViewModel)**
2. **Thư viện Quản lý trạng thái Provider**

---

### NHÓM 2: HỆ SINH THÁI FIREBASE & XÁC THỰC
3. **Firebase Authentication**
4. **Google Sign-In (OAuth 2.0 Client Type 3)**
5. **Cloud Firestore (Real-time NoSQL)**
6. **Firebase Cloud Storage**
7. **Firebase Cloud Messaging (FCM)**
8. **Google Analytics for Firebase (GA4)**
9. **Firebase Crashlytics**
10. **Firebase Remote Config**
11. **Cloud Functions for Firebase**
12. **Firebase App Check**
13. **Firebase AI Logic (Gemini 3.5 Flash-Lite)**

---

### NHÓM 3: PLUGINS VÀ TÍNH NĂNG THIẾT BỊ NATIVE
14. **Image Picker (`image_picker`)**
15. **Video Player (`video_player`)**

---

### NHÓM 4: KIỂM THỬ, TỰ ĐỘNG HÓA & CÔNG CỤ HỖ TRỢ
16. **Flutter Test (Unit & Widget Tests)**
17. **Firebase Mocks (`fake_cloud_firestore`, `firebase_auth_mocks`)**
18. **Python, Pytest & UV (E2E Test Runner)**
19. **Google ARTEMIS (AI Agent E2E Testing)**
20. **ADB (Android Debug Bridge)**
21. **Firebase Emulator Suite**
22. **Pillow & FFmpeg (Bộ công cụ dựng video mốc bước)**

---

### PHẦN KẾT LUẬN
- **Slide Tổng kết:** Bảng nghiệm thu tính năng & Kế hoạch Final Assignment

---

# CHI TIẾT NỘI DUNG TỪNG CÔNG NGHỆ (CHUẨN 3 SLIDE: WHAT/WHY – HOW – WHERE)

---

## 1. MÔ HÌNH KIẾN TRÚC MVVM

### Slide 1.1: What & Why (Kiến trúc MVVM)
- **What (Nó là gì?):**
  - Mô hình kiến trúc phân tách mã nguồn thành 3 tầng độc lập:
    - **Model:** Định nghĩa thực thể dữ liệu nghiệp vụ (`RecipeItem`, `SopItem`, `FeedbackItemModel`).
    - **View:** Giao diện người dùng Flutter thuần túy (`lib/features/*`), hoàn toàn không gọi trực tiếp SDK Firebase.
    - **ViewModel:** Lớp trung gian kế thừa `ChangeNotifier`, nắm giữ trạng thái màn hình và điều phối nghiệp vụ.
- **Why (Tại sao sử dụng?):**
  - Ngăn ngừa tình trạng spaghetti code khi widget bị phụ thuộc chặt vào Firebase SDK.
  - Tách biệt UI khỏi data source giúp dễ dàng chuyển đổi giữa Cloud Firestore và Gateway API (.NET 8) chỉ bằng một cờ cấu hình `RECIPE_SOURCE`.
  - Cho phép viết Unit Test / Widget Test độc lập hoàn toàn mà không cần mạng hay thiết bị thật.

### Slide 1.2: How (Cơ chế hoạt động của MVVM)
- **Cơ chế hoạt động:**
  - `View` lắng nghe trạng thái từ `ViewModel` qua cơ chế Observer Pattern.
  - Khi có tương tác người dùng (ví dụ: bấm nút tra cứu hoặc bấm giờ), `View` gọi hàm trong `ViewModel`.
  - `ViewModel` gọi `Service Interface` để lấy hoặc ghi dữ liệu.
  - Sau khi xử lý xong, `ViewModel` cập nhật biến trạng thái (`ViewState.ready / error / empty`) và phát tín hiệu thông báo.
- **Xử lý 4 trạng thái bắt buộc cho mọi màn tải dữ liệu:**
  - `Loading` (Đang tải) $\rightarrow$ `Ready` (Có dữ liệu) $\rightarrow$ `Empty` (Danh sách rỗng) $\rightarrow$ `Error` (Lỗi kèm nút thử lại Retry).

### Slide 1.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - ViewModels: `lib/core/viewmodels/` (13 ViewModel: `RecipeViewModel`, `TrainingViewModel`, `AuthViewModel`, v.v.).
  - Service Interfaces: `lib/core/services/interfaces/` (15 abstract interfaces).
  - Views: 23 màn hình tại `lib/features/`.
- **Hình ảnh minh chứng:**
  - Sơ đồ lớp Mermaid trong `docs/architecture.md`.
  - Ảnh màn hình 4 trạng thái: `evidence/lab3/02-seed-real-data/m01-tra-cuu.png` và `evidence/lab3/04-round3-ui/m04-chua-co-video.png`.

---

## 2. THƯ VIỆN QUẢN LÝ TRẠNG THÁI PROVIDER

### Slide 2.1: What & Why (Provider)
- **What (Nó là gì?):**
  - Thư viện quản lý trạng thái chính thức được Google khuyến nghị cho Flutter (`provider ^6.1.2`), đóng vai trò là Dependency Injection (DI) container và State Bus.
- **Why (Tại sao sử dụng?):**
  - Nhẹ nhàng, không cồng kềnh như Bloc/Redux nhưng mạnh mẽ hơn `setState` cục bộ.
  - Dễ dàng inject các Service Interface vào ViewModel thông qua Composition Root (`AppServices`).
  - Tự động giải phóng bộ nhớ (`dispose`) khi màn hình bị đóng.

### Slide 2.2: How (Cơ chế hoạt động của Provider)
- **Cơ chế hoạt động:**
  - ViewModel kế thừa `ChangeNotifier`.
  - Khi state thay đổi, gọi hàm `notifyListeners()`.
  - Widget sử dụng `context.watch<T>()` để tự động rebuild khi state thay đổi.
  - Widget sử dụng `context.read<T>()` để gọi action mà không gây rebuild widget thừa thãi.
  - `ChangeNotifierProxyProvider` hoặc `MultiProvider` tại `lib/app.dart` tiêm các dịch vụ vào cây widget.

### Slide 2.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Cấu hình Injection toàn cục: `lib/app.dart` và `lib/core/di/app_services.dart`.
  - Điểm sử dụng: Tất cả 23 màn hình trong `lib/features/`.
- **Hình ảnh minh chứng:**
  - Đoạn mã `MultiProvider` tại `lib/app.dart` và `LoadStateView` tự động cập nhật khi ViewModel phát `notifyListeners()`.

---

## 3. FIREBASE AUTHENTICATION

### Slide 3.1: What & Why (Firebase Auth)
- **What (Nó là gì?):**
  - Dịch vụ quản lý danh tính và phiên đăng nhập bảo mật của Google dành cho thiết bị di động.
- **Why (Tại sao sử dụng?):**
  - Hỗ trợ đa dạng phương thức: Email & Mật khẩu (cho nhân viên nội bộ), Google Sign-In (cho Quản lý), và Tài khoản Khách (Anonymous cho demo).
  - Tự động quản lý Access Token, Refresh Token, mã hóa thông tin đăng nhập và duy trì phiên làm việc an toàn.

### Slide 3.2: How (Cơ chế hoạt động của Firebase Auth)
- **Cơ chế hoạt động:**
  - Luồng xác thực: Người dùng nhập thông tin $\rightarrow$ `FirebaseAuth.instance.signInWithEmailAndPassword` $\rightarrow$ Nhận Firebase User & ID Token.
  - Custom Claims: Cloud Function `ensureProfile` kiểm tra email trong danh sách `ADMIN_EMAILS`, tự động cấp claim `role=admin` vào ID Token.
  - Client lắng nghe luồng `authStateChanges()`: Khi phiên đăng nhập thay đổi hoặc tài khoản bị vô hiệu hóa (`disabled: true`), tự động điều hướng sang màn Login hoặc đăng xuất ngay lập tức.

### Slide 3.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Service: `lib/core/services/firebase/firebase_auth_service.dart` (hiện thực `IAuthService`).
  - ViewModel: `lib/core/viewmodels/auth_viewmodel.dart`.
  - Giao diện: `lib/features/auth/login_page.dart`, `lib/features/auth/auth_gate.dart`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/06-firebase-console/08-auth-providers.jpg` (Các provider đã bật: Email/Password, Google, Anonymous).
  - `evidence/lab3/06-firebase-console/07-auth-users-blurred.jpg` (Danh sách người dùng trên Firebase Console).

---

## 4. GOOGLE SIGN-IN

### Slide 4.1: What & Why (Google Sign-In)
- **What (Nó là gì?):**
  - Giao thức xác thực OAuth 2.0 cho phép người dùng đăng nhập bằng tài khoản Google (`google_sign_in ^7.2.0`).
- **Why (Tại sao sử dụng?):**
  - Trải nghiệm đăng nhập 1 chạm mượt mà, không cần nhớ mật khẩu.
  - Cần thiết cho vai trò Store Manager / Admin đăng nhập nhanh bằng Gmail công việc.

### Slide 4.2: How (Cơ chế hoạt động của Google Sign-In)
- **Cơ chế hoạt động:**
  - Người dùng bấm "Đăng nhập với Google" $\rightarrow$ SDK mở hộp thoại chọn tài khoản Google trên Android.
  - Đăng ký dấu vân tay SHA-1 của máy build lên Firebase Console.
  - Lấy `GoogleSignInAuthentication` (gồm `idToken` và `accessToken`) $\rightarrow$ Tạo `OAuthCredential` $\rightarrow$ Đưa vào `FirebaseAuth.instance.signInWithCredential()`.
  - Truyền tham số `--dart-define=GOOGLE_SERVER_CLIENT_ID` (Web Client ID type 3) để đảm bảo Google trả về ID Token hợp lệ.

### Slide 4.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Hiện thực tại `lib/core/services/firebase/firebase_auth_service.dart` (hàm `signInWithGoogle()`).
  - Giao diện nút bấm: `lib/features/auth/login_page.dart`.
- **Hình ảnh minh chứng:**
  - Cấu hình SHA-1 và Client Type 3 trong `android/app/google-services.json`.
  - Ảnh đăng nhập Google trên điện thoại thật Redmi 7 trong `docs/test-plan.md` (ca kiểm thử TC-01).

---

## 5. CLOUD FIRESTORE

### Slide 5.1: What & Why (Cloud Firestore)
- **What (Nó là gì?):**
  - Cơ sở dữ liệu NoSQL dạng tài liệu (Document-based) thời gian thực và có khả năng scale tự động (`cloud_firestore ^6.10.2`).
- **Why (Tại sao sử dụng?):**
  - Dữ liệu công thức có cấu trúc phân cấp linh hoạt (món $\rightarrow$ size $\rightarrow$ nguyên liệu $\rightarrow$ bước).
  - Khả năng đồng bộ hai chiều (Real-time sync) giúp quản lý và barista cập nhật thông tin ngay lập tức.
  - Có sẵn bộ nhớ đệm ngoại tuyến (Offline Persistence) cho phép tra cứu công thức ngay cả khi mất sóng Wi-Fi tại quầy.

### Slide 5.2: How (Cơ chế hoạt động của Cloud Firestore)
- **Cơ chế hoạt động:**
  - Sử dụng WebSocket lắng nghe luồng dữ liệu thời gian thực: `collection.snapshots()`.
  - Tổ chức 12 root collections: `recipes` (61 món), `sops` (25 quy trình), `learningTasks`, `quizzes`, `evaluations`, `feedback`, v.v.
  - Bảo mật bằng **Firestore Security Rules**: Phân quyền theo role, kiểm tra `request.auth.uid`, cấm xóa dữ liệu lịch sử hoặc sửa bài quiz sau khi nộp.

### Slide 5.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Repositories: `lib/core/services/firebase/firestore_recipe_source.dart`, `firestore_training_repository.dart`, `firestore_feedback_repository.dart`.
  - File cấu hình Rules: `firebase/firestore.rules`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/06-firebase-console/10-firestore-feedback.jpg` (Dữ liệu collection trên Firebase Console).
  - `evidence/lab3/02-seed-real-data/m01-tra-cuu.png` (Hiển thị 61 công thức Phê La trên mobile).

---

## 6. FIREBASE CLOUD STORAGE

### Slide 6.1: What & Why (Cloud Storage)
- **What (Nó là gì?):**
  - Dịch vụ lưu trữ đám mây cho các tệp tin nhị phân lớn như hình ảnh, PDF và video (`firebase_storage ^13.0.3`).
- **Why (Tại sao sử dụng?):**
  - Lưu ảnh phản hồi sự cố từ Barista (ảnh lỗi nguyên liệu, sai quy cách ly).
  - Lưu bản sao tệp PDF báo cáo tự luyện để quản lý có thể tải về từ xa.
  - Phân tách dữ liệu tệp nhị phân ra khỏi Firestore để tối ưu chi phí và tốc độ truy vấn.

### Slide 6.2: How (Cơ chế hoạt động của Cloud Storage)
- **Cơ chế hoạt động:**
  - Client chọn ảnh/tạo PDF $\rightarrow$ Tạo `Reference` tới đường dẫn:
    - Ảnh phản hồi: `feedback/{uid}/{timestamp}.jpg`
    - Báo cáo PDF: `reports/{uid}/{timestamp}.pdf`
  - Upload dữ liệu qua `UploadTask` $\rightarrow$ Nhận `DownloadURL` và lưu URL này vào document Firestore tương ứng.
  - **Storage Security Rules**: Kiểm tra định dạng (chỉ cho phép ảnh PNG/JPEG/WEBP hoặc PDF), giới hạn dung lượng $\le 5$MB, cấm file thực thi SVG.

### Slide 6.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Service: `lib/core/services/firebase/firebase_storage_service.dart` (`IStorageService`).
  - ViewModel: `lib/core/viewmodels/storage_viewmodel.dart`.
  - Màn hình: `CreateFeedbackPage`, `PracticeHistoryPage`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/06-firebase-console/05-storage-feedback-upload.jpg` (Ảnh tải lên thư mục `feedback/`).
  - `evidence/lab3/06-firebase-console/06-storage-reports-upload.jpg` (Tệp PDF báo cáo tải lên `reports/`).

---

## 7. FIREBASE CLOUD MESSAGING (FCM)

### Slide 7.1: What & Why (Firebase Cloud Messaging)
- **What (Nó là gì?):**
  - Nền tảng gửi thông báo đẩy (Push Notification) miễn phí và tối ưu pin từ Google (`firebase_messaging ^16.0.3`).
- **Why (Tại sao sử dụng?):**
  - Gửi thông báo tức thì đến Barista khi công thức được cập nhật, có thông báo phân ca, hoặc quản lý đã giải quyết xong phản hồi.
  - Hỗ trợ deep link giúp người dùng bấm vào thông báo mở thẳng đến đúng công thức hoặc SOP cần đọc.

### Slide 7.2: How (Cơ chế hoạt động của FCM)
- **Cơ chế hoạt động:**
  - Thiết bị khởi động $\rightarrow$ Xin quyền thông báo $\rightarrow$ Lấy `FCM Token` $\rightarrow$ Băm SHA-256 lưu vào Firestore `users/{uid}/devices/{hash}`.
  - Server gửi thông báo qua FCM HTTP v1 API.
  - Xử lý 3 trạng thái của ứng dụng:
    1. **Foreground (Đang mở):** Bắt qua stream `onMessage` $\rightarrow$ Hiển thị In-app Banner/SnackBar.
    2. **Background (Chạy nền):** Hiện thông báo trên thanh trạng thái hệ thống Android.
    3. **Terminated (Đã tắt):** Chạm vào thông báo $\rightarrow$ Mở app và chuyển hướng sâu (Deep Link).

### Slide 7.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Service: `lib/core/services/firebase/firebase_notification_service.dart`.
  - Registry: `lib/core/services/firebase/firestore_device_registry.dart`.
  - Màn hình: `lib/features/learning/notifications_page.dart`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/06-firebase-console/11-fcm-foreground.jpg` (Thông báo foreground trên máy).
  - `evidence/lab3/06-firebase-console/12-fcm-background.jpg` (Thông báo trên khay hệ thống).
  - `evidence/lab3/06-firebase-console/13-fcm-tap-opens-inbox.jpg` (Chạm thông báo mở màn chi tiết).

---

## 8. GOOGLE ANALYTICS FOR FIREBASE

### Slide 8.1: What & Why (Google Analytics)
- **What (Nó là gì?):**
  - Dịch vụ thu thập và phân tích dữ liệu hành vi người dùng trong ứng dụng di động (`firebase_analytics ^12.0.3`).
- **Why (Tại sao sử dụng?):**
  - Giúp quản lý cửa hàng biết món nào được tra cứu nhiều nhất, thời gian luyện tập pha chế trung bình, tỷ lệ hoàn thành SOP.
  - Đo lường mức độ tương tác và phát hiện điểm nghẽn trong quy trình pha chế.

### Slide 8.2: How (Cơ chế hoạt động của Analytics)
- **Cơ chế hoạt động:**
  - Khởi tạo `FirebaseAnalytics.instance`.
  - Ghi nhận 8 sự kiện chuẩn hóa (`snake_case`):
    `login`, `logout`, `view_recipe`, `start_brew_timer`, `complete_brew_timer`, `submit_feedback`, `export_report_pdf`, `trigger_test_crash`.
  - Hàm `AnalyticsEvent.sanitize` tự động lọc bỏ thông tin nhạy cảm (PII - email, tên) trước khi gửi.
  - Gán User Properties: `user_role`, `auth_mode`, `store_code`.

### Slide 8.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Service: `lib/core/services/firebase/firebase_analytics_service.dart` (`IAnalyticsService`).
  - Tích hợp tại: `AuthViewModel`, `RecipeDetailSizePage`, `SelfPracticeTimerPage`, `StorageViewModel`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/06-firebase-console/01-analytics-events.jpg` (Báo cáo Events và số lượt kích hoạt trên Google Analytics Console).

---

## 9. FIREBASE CRASHLYTICS

### Slide 9.1: What & Why (Firebase Crashlytics)
- **What (Nó là gì?):**
  - Công cụ giám sát sự cố, phân tích crash report và bắt lỗi thời gian thực (`firebase_crashlytics ^5.0.3`).
- **Why (Tại sao sử dụng?):**
  - Phát hiện ngay lập tức các lỗi crash hoặc lỗi ngoại lệ không mong muốn xảy ra trên máy nhân viên tại quầy.
  - Cung cấp Stack Trace đầy đủ, thông số thiết bị (Android version, model) và ngữ cảnh người dùng để sửa lỗi nhanh chóng.

### Slide 9.2: How (Cơ chế hoạt động của Crashlytics)
- **Cơ chế hoạt động:**
  - Bắt lỗi toàn cục trong `lib/core/bootstrap/firebase_bootstrap.dart`:
    - `FlutterError.onError`: Ghi nhận lỗi framework Flutter (non-fatal, ví dụ overflow).
    - `PlatformDispatcher.instance.onError`: Bắt lỗi bất đồng bộ nền tảng (fatal crash).
  - Tích hợp tính năng Báo sự cố: Mỗi lỗi được gom thành `IncidentReport` lưu tạm vào bộ nhớ máy, sau đó đồng bộ lên Firestore `incidents/` cho web Admin.

### Slide 9.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Khởi tạo: `lib/core/bootstrap/firebase_bootstrap.dart`.
  - Reporter: `lib/core/services/firebase/firebase_crash_reporter.dart`.
  - Nút kiểm thử: Nút "Kiểm thử sự cố" tại `lib/features/account/account_profile_page.dart`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/06-firebase-console/02-crashlytics-dashboard.jpg` (Bảng điều khiển Crashlytics).
  - `evidence/lab3/06-firebase-console/03-crashlytics-issues.jpg` (Danh sách issue và stack trace).

---

## 10. FIREBASE REMOTE CONFIG

### Slide 10.1: What & Why (Remote Config)
- **What (Nó là gì?):**
  - Dịch vụ cấu hình từ xa cho phép thay đổi giao diện và hành vi ứng dụng từ đám mây mà không cần build lại APK (`firebase_remote_config ^6.1.0`).
- **Why (Tại sao sử dụng?):**
  - Điều chỉnh linh hoạt số món hiển thị tại quầy theo cấu hình từng máy (`max_lookup_results`).
  - Bật/tắt tính năng trợ lý AI (`enable_ai_assist`) hoặc hiển thị nút chẩn đoán sự cố (`show_crash_demo`).

### Slide 10.2: How (Cơ chế hoạt động của Remote Config)
- **Cơ chế hoạt động:**
  - Khai báo giá trị mặc định cục bộ trong `firebase/remote-config-defaults.json`.
  - Ứng dụng khởi động $\rightarrow$ Gọi `fetchAndActivate()`:
    - Chế độ Debug: Cập nhật tức thì (cache interval 0s).
    - Chế độ Release: Lưu cache 1 giờ để tiết kiệm tài nguyên mạng.
  - Lắng nghe cấu hình thời gian thực qua `onConfigUpdated` stream.

### Slide 10.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Service: `lib/core/services/firebase/firebase_remote_config_service.dart`.
  - ViewModel: `lib/core/viewmodels/app_config_viewmodel.dart`.
  - Tích hợp tại: `CounterRecipeLookupPage` (giới hạn số món), `AccountProfilePage` (ẩn/hiện mục kiểm thử lỗi).
- **Hình ảnh minh chứng:**
  - `evidence/lab3/06-firebase-console/04-remote-config-params.jpg` (Tham số `max_lookup_results`, `enable_ai_assist` trên Console).

---

## 11. CLOUD FUNCTIONS FOR FIREBASE

### Slide 11.1: What & Why (Cloud Functions)
- **What (Nó là gì?):**
  - Nền tảng Serverless cho phép chạy mã backend (TypeScript / Node.js 22) tự động khi có sự kiện từ Firebase (`cloud_functions ^6.5.1`).
- **Why (Tại sao sử dụng?):**
  - Thực hiện các tác vụ quản trị bảo mật mà client không được phép làm (cấp claim Admin, vô hiệu hóa tài khoản, gửi thông báo FCM hàng loạt).
  - Đảm bảo tính toán toàn vẹn dữ liệu (đếm số thiết bị, thống kê số lượng nhân viên).

### Slide 11.2: How (Cơ chế hoạt động của Cloud Functions)
- **Cơ chế hoạt động:**
  - **Callable Functions:** Client gọi trực tiếp qua HTTPS:
    - `ensureProfile`: Gán custom claim `role` và tạo document `users/{uid}`.
    - `setUserRole`, `setUserDisabled`: Quản lý cấp quyền và khóa tài khoản.
    - `sendNotification`: Gửi tin nhắn FCM qua Firebase Admin SDK.
  - **Triggers:** Tự động kích hoạt khi có sự kiện (Auth trigger `onUserCreated`, Firestore trigger `onDeviceWritten`).

### Slide 11.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Thư mục backend: `firebase/functions/src/`.
  - Client gọi: `lib/core/services/firebase/firebase_user_profile_service.dart`.
- **Hình ảnh minh chứng:**
  - Mã nguồn Cloud Functions trong `firebase/README.md`.
  - Hoạt động cấp quyền Admin và tự động đăng xuất tại `docs/test-plan.md` (ca kiểm thử TC-13, TC-15).

---

## 12. FIREBASE APP CHECK

### Slide 12.1: What & Why (App Check)
- **What (Nó là gì?):**
  - Lớp bảo vệ bổ sung giúp ngăn chặn hành vi lạm dụng, giả mạo ứng dụng hoặc tấn công trái phép vào tài nguyên Firebase backend.
- **Why (Tại sao sử dụng?):**
  - Đảm bảo các yêu cầu gửi đến Cloud Functions và dịch vụ AI thực sự bắt nguồn từ ứng dụng RecipeHub chính chủ đang cài trên thiết bị thật, không phải từ Postman hay script bot.

### Slide 12.2: How (Cơ chế hoạt động của App Check)
- **Cơ chế hoạt động:**
  - Môi trường Debug: Sử dụng **Android Debug Provider** kèm `APP_CHECK_DEBUG_TOKEN`.
  - Môi trường Production: Sử dụng **Play Integrity API** của Google Play Services để chứng thực tính toàn vẹn của tệp APK và thiết bị.
  - Mỗi request gửi kèm App Check token $\rightarrow$ Firebase backend kiểm tra token trước khi xử lý logic.

### Slide 12.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Khởi tạo tại `lib/core/bootstrap/firebase_bootstrap.dart`.
  - Xác thực trước lời gọi AI trong `lib/core/services/firebase/firebase_ai_practice_service.dart`.
- **Hình ảnh minh chứng:**
  - Kết quả kiểm chứng App Check thành công (HTTP 200 Attestation Check) ghi nhận trong `docs/feature-inventory.md` mục 9.

---

## 13. FIREBASE AI LOGIC (GEMINI 3.5 FLASH-LITE)

### Slide 13.1: What & Why (Firebase AI Logic)
- **What (Nó là gì?):**
  - Tính năng tích hợp mô hình ngôn ngữ lớn (LLM - Gemini 3.5 Flash-Lite) thông qua Firebase AI Logic SDK để hỗ trợ đào tạo nghiệp vụ pha chế.
- **Why (Tại sao sử dụng?):**
  - Tự động sinh câu hỏi trắc nghiệm tương tác giúp Barista ôn tập nguyên liệu, thứ tự các bước và lưu ý SOP ngay trong lúc bấm giờ thực hành.
  - Rút ngắn thời gian đào tạo học việc cho nhân viên mới.

### Slide 13.2: How (Cơ chế hoạt động của AI Recall)
- **Cơ chế hoạt động:**
  - `RecipeRecallBuilder` đọc dữ liệu công thức và SOP ban hành $\rightarrow$ Trích xuất candidates chuẩn.
  - Gọi Gemini model với cấu hình: Temperature 0.2, tối đa 1024 tokens, timeout 15s.
  - Gemini chỉ chọn thứ tự câu hỏi và tham chiếu từ danh sách candidate (không tự bịa kiến thức hay thông số).
  - Khi mất mạng hoặc lỗi quota: Tự động fallback sang ngân hàng câu hỏi mẫu theo luật (Rule-based) mà không làm gián đoạn đồng hồ bấm giờ.

### Slide 13.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Builder: `lib/core/services/ai/recipe_recall_builder.dart`.
  - Service: `lib/core/services/firebase/firebase_ai_practice_service.dart`.
  - ViewModel: `lib/core/viewmodels/ai_practice_viewmodel.dart`.
  - Màn hình: `lib/features/practice/self_practice_timer_page.dart`.
- **Hình ảnh minh chứng:**
  - `evidence/ai-practice-implementation-20261111/25-device-live-ai-question.png` (Câu hỏi AI hiển thị trên điện thoại Redmi 7).
  - `evidence/ai-practice-implementation-20261111/28-device-live-ai-correct.png` (Phản hồi đúng và giải thích nguồn SOP).

---

## 14. IMAGE PICKER (`image_picker`)

### Slide 14.1: What & Why (Image Picker)
- **What (Nó là gì?):**
  - Plugin chính thức của Flutter (`image_picker ^1.1.2`) cho phép truy cập Camera và Thư viện ảnh của thiết bị Android/iOS.
- **Why (Tại sao sử dụng?):**
  - Cần thiết cho chức năng gửi phản hồi: Barista chụp ảnh trực tiếp tại quầy hoặc chọn ảnh lỗi nguyên liệu để gửi cho Quản lý.

### Slide 14.2: How (Cơ chế hoạt động của Image Picker)
- **Cơ chế hoạt động:**
  - Giao tiếp qua MethodChannel gọi Intent native của Android (`MediaStore.ACTION_IMAGE_CAPTURE` hoặc `ACTION_GET_CONTENT`).
  - Hỗ trợ nén ảnh, giới hạn kích thước tối đa và chuyển đổi thành `XFile`.
  - `ImagePickerMediaService` bao bọc plugin qua interface `IMediaPickerService` để dễ viết mock test.

### Slide 14.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Service: `lib/core/services/device/image_picker_media_service.dart`.
  - Màn hình: `lib/features/feedback/create_feedback_page.dart`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/01-feedback-realtime/01-mobile-chon-anh.png` (Hộp thoại chọn ảnh từ thư viện trên máy).

---

## 15. VIDEO PLAYER (`video_player`)

### Slide 15.1: What & Why (Video Player)
- **What (Nó là gì?):**
  - Plugin native phát video chất lượng cao trên Flutter (`video_player ^2.11.0`).
- **Why (Tại sao sử dụng?):**
  - Phát video kỹ thuật chuẩn (video streaming từ Cloud Storage URL) cho từng món đồ uống.
  - Đồng bộ mốc thời gian (timestamp) giữa video và các bước pha chế tương ứng.

### Slide 15.2: How (Cơ chế hoạt động của Video Player)
- **Cơ chế hoạt động:**
  - Sử dụng `VideoPlayerController.networkUrl` để stream video trực tiếp từ máy chủ.
  - Lắng nghe vị trí phát `controller.position` $\rightarrow$ Tự động highlight bước pha chế đang diễn ra trên timeline.
  - Cho phép người dùng chạm vào một bước bất kỳ để tua (seek) video đến đúng mốc thời gian bắt đầu của bước đó.
  - Hỗ trợ xoay toàn màn hình ngang (Landscape mode) và tự phục hồi khi thoát.

### Slide 15.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - ViewModel: `lib/core/viewmodels/step_video_viewmodel.dart`.
  - Màn hình: `lib/features/lookup/step_video_guide_page.dart`.
- **Hình ảnh minh chứng:**
  - `evidence/lab3/04-round3-ui/m05-video.png` (Màn hình phát video và timeline bước).
  - `evidence/lab3/04-round3-ui/m06-video-toan-man-hinh.png` (Chế độ xem video xoay ngang toàn màn hình).

---

## 16. FLUTTER TEST (UNIT & WIDGET TESTS)

### Slide 16.1: What & Why (Flutter Test)
- **What (Nó là gì?):**
  - Khung kiểm thử tự động chính thức tích hợp sẵn trong Flutter SDK (`flutter_test`).
- **Why (Tại sao sử dụng?):**
  - Đảm bảo chất lượng mã nguồn, bắt lỗi hồi quy (regression) trước khi đóng gói APK.
  - Đạt tiêu chuẩn chất lượng nghiêm ngặt của đồ án: 321 tests pass 100%, 0 lỗi analyze.

### Slide 16.2: How (Cơ chế hoạt động của Flutter Test)
- **Cơ chế hoạt động:**
  - Chạy môi trường headless Dart VM không cần máy ảo hay thiết bị thật.
  - **Unit Test:** Kiểm tra logic tính toán thời gian, chuẩn hóa tìm kiếm không dấu, parsing model.
  - **Widget Test:** Dùng `WidgetTester` mô phỏng hành vi chạm, cuộn, nhập liệu và kiểm tra sự xuất hiện của các component trên cây widget.

### Slide 16.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Thư mục kiểm thử: `test/` (25+ file test, bao phủ toàn bộ các màn hình và ViewModel).
  - Lệnh thực thi: `flutter test --no-pub`.
- **Hình ảnh minh chứng:**
  - Kết quả chạy terminal: `321 passed! All tests passed!` ghi nhận trong `docs/test-plan.md`.

---

## 17. FIREBASE MOCKS (`fake_cloud_firestore`, `firebase_auth_mocks`)

### Slide 17.1: What & Why (Firebase Mocks)
- **What (Nó là gì?):**
  - Bộ thư viện giả lập môi trường Firebase in-memory cho Flutter (`fake_cloud_firestore ^4.4.0`, `firebase_auth_mocks ^0.15.2`).
- **Why (Tại sao sử dụng?):**
  - Cho phép chạy toàn bộ kiểm thử Unit & Widget test mà không cần kết nối mạng tới Firebase thật.
  - Tránh phát sinh chi phí read/write trên Cloud Firestore và giữ dữ liệu test độc lập.

### Slide 17.2: How (Cơ chế hoạt động của Mocks)
- **Cơ chế hoạt động:**
  - `FakeFirebaseFirestore` lưu trữ collection và document trong bộ nhớ RAM, mô phỏng đầy đủ hành vi query, snapshot stream và batch write.
  - `MockFirebaseAuth` mô phỏng người dùng đăng nhập, cấp ID token giả lập.
  - Composition Root `AppServices.mock()` nhận các mock service này để tiêm vào ứng dụng khi chạy test hoặc khi app tự động fallback.

### Slide 17.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Mock Services: `lib/core/services/mock/` (11 mock classes).
  - Tích hợp tại: `test/support/` và các file test trong `test/`.
- **Hình ảnh minh chứng:**
  - Đoạn mã cấu hình `AppServices.mock()` trong `lib/core/di/app_services.dart`.

---

## 18. PYTHON, PYTEST & UV (E2E TEST HARNESS)

### Slide 18.1: What & Why (Python & Pytest & UV)
- **What (Nó là gì?):**
  - Hệ sinh thái kiểm thử tự động đầu cuối (End-to-End) viết bằng Python 3.12, quản lý gói siêu tốc bằng `uv` và thực thi qua framework `pytest`.
- **Why (Tại sao sử dụng?):**
  - Tự động hóa việc điều khiển điện thoại thật từ máy tính: cài đặt APK, gửi lệnh ADB, chụp màn hình và xác nhận kết quả kiểm thử.
  - `uv` giúp cài đặt dependencies nhanh gấp 10 lần `pip` thông thường.

### Slide 18.2: How (Cơ chế hoạt động của Pytest Harness)
- **Cơ chế hoạt động:**
  - Cấu hình môi trường trong `e2e_test/.env` (Serial thiết bị, tài khoản Barista test, Gmail Admin).
  - `conftest.py` khởi tạo session kiểm thử, kiểm tra kết nối ADB với thiết bị thật.
  - Chạy lệnh: `uv run pytest -v -m "not manual"` $\rightarrow$ Tự động thực thi từng ca kiểm thử từ TC-01 đến TC-24.

### Slide 18.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Thư mục kiểm thử: `e2e_test/`.
  - Cấu hình: `e2e_test/pyproject.toml`, `e2e_test/conftest.py`.
- **Hình ảnh minh chứng:**
  - Bảng tổng hợp kết quả 3 vòng chạy E2E tại `docs/test-plan.md` mục 5.1.

---

## 19. GOOGLE ARTEMIS (AI AGENT E2E TESTING)

### Slide 19.1: What & Why (Google ARTEMIS)
- **What (Nó là gì?):**
  - Khung kiểm thử tự động thế hệ mới dựa trên AI Agent do Google phát triển (ghim commit `351ca842`, mô hình Gemini Flash-Lite).
- **Why (Tại sao sử dụng?):**
  - Cho phép AI Agent tự nhìn màn hình điện thoại (thông qua ảnh chụp màn hình liên tục) và tự ra quyết định click, vuốt, gõ phím giống như người dùng thật.
  - Phát hiện các lỗi giao diện và trải nghiệm mà script kiểm thử truyền thống bỏ sót.

### Slide 19.2: How (Cơ chế hoạt động của ARTEMIS)
- **Cơ chế hoạt động:**
  - ARTEMIS Server nhận nhiệm vụ kiểm thử (Goal) $\rightarrow$ Gửi prompt kèm ảnh màn hình hiện tại lên Gemini AI.
  - Gemini phân tích giao diện và trả về tọa độ hành động: `tap(x, y)`, `input_text()`, `swipe()`.
  - ARTEMIS thực thi hành động trên điện thoại thật thông qua ADB và kiểm tra trạng thái hoàn thành.
  - Kết quả ghi nhận tại 3 vòng chạy trên điện thoại Redmi 7: **18/19 ca tự động PASS $\ge 1$ vòng, 49/55 lượt ca PASS**.

### Slide 19.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Tài liệu & kịch bản: `docs/artemis-test-plan.md` và `e2e_test/`.
- **Hình ảnh minh chứng:**
  - Ảnh minh họa kiểm thử ARTEMIS trong Slide 13 của bài thuyết trình.
  - Log kết quả kiểm chứng chi tiết tại `docs/test-plan.md` mục 5.1.

---

## 20. ADB (ANDROID DEBUG BRIDGE)

### Slide 20.1: What & Why (ADB)
- **What (Nó là gì?):**
  - Công cụ dòng lệnh giao tiếp trực tiếp với hệ điều hành Android nằm trong bộ Android SDK Platform-Tools.
- **Why (Tại sao sử dụng?):**
  - Cầu nối bắt buộc để nạp và cài đặt APK lên điện thoại thật, chụp ảnh màn hình làm minh chứng, đọc logcat và phục vụ các bài test tự động.

### Slide 20.2: How (Cơ chế hoạt động của ADB)
- **Cơ chế hoạt động:**
  - Hoạt động theo mô hình Client - Server qua cổng socket `127.0.0.1:5037`.
  - Lệnh thường dùng trong dự án:
    - Cài đặt APK: `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
    - Chụp ảnh màn hình: `adb exec-out screencap -p > screenshot.png`.
    - Đảo ngược cổng mạng kết nối backend: `adb reverse tcp:5000 tcp:5000`.

### Slide 20.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Công cụ hệ thống: `C:\Users\tu_core\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
  - Tích hợp trong kịch bản kiểm thử: `e2e_test/conftest.py`.
- **Hình ảnh minh chứng:**
  - Kết quả lệnh `adb devices` nhận diện thiết bị thật Pixel 3a / Redmi 7.

---

## 21. FIREBASE EMULATOR SUITE

### Slide 21.1: What & Why (Firebase Emulator)
- **What (Nó là gì?):**
  - Bộ công cụ cục bộ cho phép giả lập toàn bộ môi trường backend Firebase ngay trên máy tính của lập trình viên (`firebase-tools`).
- **Why (Tại sao sử dụng?):**
  - Giúp kiểm thử bộ quy tắc bảo mật (Security Rules) với 57 ca kiểm tra allow/deny mà không ảnh hưởng tới dữ liệu production trên đám mây.
  - Hỗ trợ làm việc ngoại tuyến hoàn toàn khi không có kết nối internet.

### Slide 21.2: How (Cơ chế hoạt động của Emulator)
- **Cơ chế hoạt động:**
  - Khởi chạy các dịch vụ trên các cổng cục bộ:
    - Auth: `9099`, Firestore: `8080`, Storage: `9199`, UI Dashboard: `4000`.
  - Chạy lệnh khởi động: `npx -y firebase-tools emulators:start --only auth,firestore,storage,functions`.
  - Bộ test Node.js / Jest thực thi các kịch bản kiểm tra quyền đọc/ghi rules.

### Slide 21.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Cấu hình: `firebase/firebase.json` (mục `emulators`).
  - Hướng dẫn chạy: `firebase/README.md`.
- **Hình ảnh minh chứng:**
  - Bảng cấu hình cổng Emulator trong `firebase/firebase.json`.

---

## 22. PILLOW & FFMPEG (BỘ CÔNG CỤ DỰNG VIDEO BƯỚC)

### Slide 22.1: What & Why (Pillow & FFmpeg)
- **What (Nó là gì?):**
  - Thư viện xử lý đồ họa ảnh Python (`Pillow`) kết hợp công cụ xử lý đa phương tiện mã nguồn mở hàng đầu thế giới (`FFmpeg`).
- **Why (Tại sao sử dụng?):**
  - Tự động hóa quy trình sản xuất 61 video kỹ thuật chuẩn cho toàn bộ danh mục món Phê La; đảm bảo độ dài từng phân đoạn video khớp chính xác với mốc giây của từng bước trong cơ sở dữ liệu.

### Slide 22.2: How (Cơ chế hoạt động của Script dựng video)
- **Cơ chế hoạt động:**
  - Kịch bản `tools/video/make_videos.py` đọc tệp dữ liệu công thức `tools/seed/recipes.json`.
  - Dùng `Pillow` vẽ từng khung hình (Frame) chứa tên món, số thứ tự bước, hình minh họa và thời gian thực hiện.
  - Sử dụng `FFmpeg` ghép các khung hình thành luồng video MP4 (H.264), mã hóa với đúng thời lượng của từng bước (`step.durationSeconds`).
  - Tự động tải video thành phẩm lên Cloud Storage tại đường dẫn `recipe-videos/{code}/{code}.mp4`.

### Slide 22.3: Where & Integration (Vị trí & Tích hợp)
- **Vị trí mã nguồn:**
  - Kịch bản: `tools/video/make_videos.py`.
  - Dữ liệu đầu vào: `tools/seed/recipes.json`.
- **Hình ảnh minh chứng:**
  - Video phát thực tế trong ứng dụng: `evidence/lab3/04-round3-ui/m05-video.png` và `m06-video-toan-man-hinh.png`.
