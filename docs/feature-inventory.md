# Kiểm kê tính năng RecipeHub Mobile

**Ngày đối chiếu:** 12/11/2026
**Phạm vi:** ứng dụng Flutter trong repository này, cấu hình Firebase được khai báo tại `firebase/`, và các dịch vụ ngoài mà mobile gọi. Không tính giao diện web Admin như một màn hình mobile.
**Nguồn đối chiếu:** mã trong `lib/`, Firestore/Storage rules, Remote Config template, cấu hình Firebase, cùng các báo cáo kiểm thử hiện hành. Khi tài liệu cũ khác mã nguồn, báo cáo này ưu tiên hành vi trong mã nguồn và kết quả kiểm tra ngày 12/11/2026 (xem [bản cập nhật](releases/2026-11-12.md)).

## 1. Tóm tắt phạm vi và thống kê

| Hạng mục | Thống kê | Cách đếm / ghi chú |
| --- | ---: | --- |
| Nhóm tính năng trong `lib/features` | 11 | `account`, `admin_training`, `auth`, `feedback`, `learning`, `lookup`, `practice`, `shell`, `sop`, `sop_book`, `system` |
| Tệp giao diện tên `*_page.dart` | 22 | Đếm theo tên tệp trong `lib/features`; một số là trang phụ điều hướng từ tab |
| Trang vỏ điều hướng | 1 | `MainAppShell` nằm trong `main_app_shell.dart`, không có hậu tố `_page.dart` |
| `ChangeNotifier` ViewModel | 13 | Đếm theo lớp: 2 training, 2 feedback và 9 lớp còn lại |
| Service interface | 15 | Các interface `I...` trong `lib/core/services/interfaces` |
| Adapter Firebase | 14 | Bao gồm Auth, Firestore, Storage, Analytics, Crashlytics, FCM, Remote Config và Firebase AI Logic |
| Vai trò trải nghiệm | 2 | Barista/Viewer và Store Admin; quyền thực tế lấy từ custom claim/profile máy chủ |
| Tab chính | 4 mỗi vai trò | Tra cứu, Học việc/Đào tạo, Phản hồi, Tài khoản |
| Root collection Firestore được rules khai báo | 12 | `users`, `incidents`, `notifications`, `stats`, `recipes`, `sops`, `learningTasks`, `evaluationCriteria`, `quizzes`, `quizAttempts`, `evaluations`, `feedback` |
| Loại subcollection được dùng | 5 | `devices`, `taskProgress`, `practiceRecords`, `answerKey`, `replies` |
| Analytics event có interface | 8 | Danh sách chi tiết ở mục 8 |

Các con số màn hình đếm tệp giao diện, không phải số route độc lập: có màn được mở từ nhiều nơi, có trang chi tiết, trang dialog/trạng thái và các view nội bộ trong sổ tay. `RecipeBookPage` và `_PaperPage` là view trong sổ tay, không phải route độc lập.

## 2. Vai trò, điều hướng và nguyên tắc quyền

### Barista (Viewer)

Barista xem công thức/SOP, tự học nhiệm vụ, làm quiz, tự luyện công thức, xem kết quả đánh giá của mình, gửi phản hồi và trao đổi với Admin, quản lý tài khoản, xem thông báo.

Tab chính: **Tra cứu → Việc học → Phản hồi → Tài khoản**.

### Store Admin

Admin dùng mobile để tra cứu nội dung, xem tiến độ đội ngũ, xem/tương tác phản hồi, thực hiện đánh giá tay nghề và quản lý tài khoản/thiết bị của mình. Phát hành nội dung đào tạo, công thức, gửi thông báo diện rộng và quản lý sự cố thuộc các dịch vụ/web Admin bên ngoài mobile; mobile không cung cấp màn hình CRUD cho các danh mục này.

Tab chính: **Tra cứu → Đào tạo → Phản hồi → Tài khoản**.

### Quyền xác thực

- `role=admin` trên Firebase ID token và hồ sơ `users/{uid}` là căn cứ quyền. Client không tự cấp/nâng quyền.
- Admin có thể chuyển chế độ hiển thị sang Viewer để xem trải nghiệm Barista. Chế độ này chỉ đổi điều hướng/UI; quyền máy chủ vẫn là Admin. Vì vậy các luồng Admin vẫn được bảo vệ theo `serverRole`/AdminGuard.
- Nếu hồ sơ báo tài khoản bị vô hiệu hóa, phiên bị đăng xuất. Rules kiểm tra cả claim lẫn hồ sơ đang hoạt động ở các thao tác quản trị quan trọng.
- Guest dùng Firebase Anonymous Auth và được dùng các luồng Barista được rules cho phép; không có màn hình đăng ký tài khoản riêng trong mobile hiện tại.

## 3. Kiến trúc và cấu hình chạy

### Kiến trúc ứng dụng

- Flutter tổ chức theo MVVM + Provider. Widget gọi ViewModel; ViewModel dùng interface service/repository; `AppServices` là composition root để chọn Firebase adapter hoặc adapter test/mock.
- Các màn tải dữ liệu biểu diễn trạng thái tải, rỗng/thành công và lỗi; luồng có retry tại chỗ ở những khu vực hỗ trợ.
- Nguồn công thức mặc định là Firestore. Có thể chọn API .NET Gateway bằng `RECIPE_SOURCE=gateway`. Không bật mock data trong app production; test truyền fake source tường minh.
- Firebase bootstrap thất bại thì app có thể chuyển qua cấu hình mock để chạy demo UI. Điều này không đồng nghĩa có bộ dữ liệu công thức giả đi kèm app: `AppServices.mock` bắt buộc bên gọi truyền `IRecipeSource`.
- Theme/token giao diện tập trung tại `lib/core/theme/nomad_kit.dart` (NomadKit); không phải mọi giá trị cũ trong widget đã được chuyển token. Đây là điểm audit hiện trạng, không phải khẳng định mọi màn hình chỉ dùng token.

### Biến build / runtime

| Biến | Mặc định / cách dùng | Tác động |
| --- | --- | --- |
| `RECIPE_SOURCE` | `firestore`; đặt `gateway` để đổi nguồn | Chọn nguồn công thức Firestore hoặc YARP/.NET Gateway |
| `API_BASE_URL` | Emulator Android dùng `http://10.0.2.2:5000`; nền tảng desktop/web dùng `localhost:5000` | Ghi đè địa chỉ Gateway, ví dụ IP LAN của máy chủ khi chạy trên thiết bị thật |
| `GOOGLE_SERVER_CLIENT_ID` | Rỗng; có thể đọc Web Client ID từ cấu hình Firebase Android | Override client ID cho Google Sign-In khi cấu hình mặc định không cấp được ID token |
| `APP_CHECK_DEBUG_TOKEN` | Rỗng nếu không truyền | Tùy chọn compile-time cho Android debug provider; không ghi token thật vào repository/log |
| `AI_DEMO_ENABLED` | Mặc định `false` | Bật luồng demo AI trong build; đây là cờ build riêng, có thể mở tính năng demo khi Remote Config toàn cục vẫn tắt |
| `AI_MODEL` | `gemini-3.5-flash-lite` | Chọn model Firebase AI Logic sử dụng; không phải API key |

Không ghi API key, debug token, keystore hay nội dung `google-services.json` vào tài liệu/repository. Firebase AI Logic xác thực qua Firebase App Check; ứng dụng không nhúng Gemini API key trực tiếp.

### Firebase khởi động và môi trường

1. `FirebaseBootstrap.initialize()` gọi Firebase Core.
2. Trên Android bật App Check: debug build dùng Android Debug Provider; release dùng Play Integrity. Lỗi App Check được cô lập để phần còn lại của app vẫn khởi động, nhưng AI có thể không gọi được.
3. Gắn Crashlytics cho lỗi Flutter, lỗi async/platform và custom key `build_mode`; đăng ký handler FCM chạy nền.
4. Sau khi tạo service graph, incident reporter nhận các lỗi đã lưu cục bộ để gửi lại sau khi người dùng đăng nhập.
5. `AppServices.firebase()` cung cấp adapter Firebase thật; `AppServices.mock(recipes: ...)` dành cho test/demo có fake được truyền vào.

`firebase/firebase.json` khai báo Firestore rules/indexes, Storage rules, Remote Config template và emulator: Auth `9099`, Firestore `8080`, Storage `9199`, UI `4000`, `singleProjectMode=true`. Cấu hình trong repository này không khai báo Functions/Hosting. Các callable/trigger được mobile phụ thuộc (ví dụ đồng bộ profile, cấp claim, gửi FCM, ghi thống kê) phải tồn tại ở Firebase project hoặc repository/backend triển khai riêng.

### Remote Config

| Khóa | Giá trị mặc định trong mã/template | Ý nghĩa và giới hạn |
| --- | --- | --- |
| `enable_ai_assist` | `false` | Cờ bật ôn tập AI; template đang để tắt. Build demo còn có `AI_DEMO_ENABLED` độc lập |
| `max_lookup_results` | `50` | Giới hạn số món tra cứu; giá trị không hợp lệ hoặc ≤ 0 quay về 50, giá trị hợp lệ bị giới hạn trong 1–200 |
| `show_crash_demo` | `true` | Hiển thị khu vực kiểm thử lỗi trên Tài khoản |

Remote Config fetch timeout 10 giây. Debug fetch mỗi lần (minimum interval 0); release cache tối thiểu 1 giờ. Có defaults/cache nếu fetch lỗi, lắng nghe cấu hình real-time và có thể refresh thủ công. Không thể suy từ template rằng tất cả giá trị production trên Console hiện giống template.

## 4. Danh mục màn hình mobile

| Nhóm | Tệp màn hình / vai trò chính | Nội dung |
| --- | --- | --- |
| Xác thực | `features/auth/login_page.dart` — chưa đăng nhập | Đăng nhập email/mật khẩu, Google, guest; gửi email đặt lại mật khẩu |
| Vào app | `features/auth/auth_gate.dart` — điều phối | Chờ trạng thái phiên, đồng bộ profile/role, tải dữ liệu ban đầu, chuyển Login/Shell; không phải Page riêng |
| Khung app | `features/shell/main_app_shell.dart` — cả hai vai trò | AppBar, chuông thông báo và 4 tab theo role |
| Tra cứu | `features/lookup/counter_recipe_lookup_page.dart` — cả hai | Tìm/lọc danh sách công thức; mở chi tiết và bắt đầu tự luyện |
| Chi tiết món | `features/lookup/recipe_detail_size_page.dart` — cả hai | Công thức, size/định lượng, lưu ý, liên kết phản hồi/SOP và video nếu có |
| Video | `features/lookup/step_video_guide_page.dart` — cả hai | Video hướng dẫn và timeline từng bước; có xem toàn màn hình ngang |
| SOP | `features/sop/sop_detail_page.dart` — cả hai | Chi tiết SOP đã phát hành; thư viện nằm ở tab SOP trong Tra cứu |
| Sổ tay số | `features/sop_book/sop_book_page.dart` — cả hai | Lật trang, nội dung, điều hướng trang và xuất sổ tay PDF |
| Học việc | `features/learning/my_learning_page.dart`, `learning_task_detail_page.dart`, `personal_progress_page.dart` — Barista | Danh sách nhiệm vụ, nội dung/checkbox theo phần, tiến độ cá nhân và trạng thái cần học lại |
| Quiz | `features/practice/quiz_exam_page.dart` — Barista | Trả lời câu hỏi, nộp bài, xem điểm/đáp án/giải thích sau khi nộp |
| Tự luyện | `features/practice/self_practice_timer_page.dart` — Barista | Chọn món, bấm giờ thực hành, ghi chú; tùy cấu hình có thẻ hỏi ôn AI/câu mẫu |
| Lịch sử | `features/practice/practice_history_page.dart` — Barista | Thống kê buổi tập cá nhân và xuất báo cáo PDF |
| Đánh giá tay nghề | `features/practice/practical_evaluation_page.dart` — Admin chấm, Barista xem kết quả của mình | Checklist tiêu chí theo món, nhận xét, kết luận đạt/chưa đạt và kế hoạch học lại |
| Đào tạo cửa hàng | `features/admin_training/admin_store_training_page.dart` — Admin | Nhân viên, tiến độ, nhiệm vụ trễ, kết quả đánh giá; mở luồng đánh giá thực hành |
| Phản hồi | `features/feedback/my_feedback_list_page.dart`, `create_feedback_page.dart`, `feedback_detail_page.dart` — Barista/Admin | Tạo/yêu cầu, danh sách theo quyền, hội thoại hai chiều, trạng thái và file ảnh đính kèm |
| Tài khoản | `features/account/account_profile_page.dart` — cả hai | Hồ sơ/role, chuyển chế độ xem Viewer, đổi mật khẩu nếu đăng nhập password, thông báo, đăng xuất, demo Crashlytics |
| Đổi mật khẩu | `features/account/change_password_page.dart` — tài khoản password | Đổi mật khẩu; không áp dụng với guest/Google |
| Chuyển trạng thái | `features/system/loading_transition_page.dart`, `error_recovery_page.dart` — dùng chung | Loading/khôi phục lỗi và thao tác điều hướng quay lại/thử lại |

## 5. Mô tả luồng từng tính năng

### 5.1. Đăng nhập, khởi tạo phiên và vai trò

**Luồng:** mở app → AuthGate chờ `authStateChanges` → Login nếu chưa đăng nhập → chọn email/mật khẩu, Google hoặc tiếp tục với guest → Firebase Auth xác thực → đồng bộ hồ sơ/vai trò từ server → gắn role vào Analytics/Crashlytics → đăng ký FCM token → vào shell. Người dùng có thể gửi email reset mật khẩu. Đăng xuất chạy hook dọn token thiết bị trước (mỗi hook có timeout tối đa 3 giây) rồi xóa trạng thái theo phiên.

**Quy tắc:** không có đăng ký tự phục vụ trong mobile. Tài khoản Admin do hệ thống/server cấp; chọn nhãn Admin ở client không làm tăng quyền. Admin có thể chuyển UI sang Viewer nhưng server role giữ nguyên. Tài khoản bị khóa bị sign out khi nhận trạng thái disabled.

**Lỗi/khôi phục:** sai thông tin, hủy Google, mất mạng, cấu hình Google thiếu ID token, lỗi đồng bộ hồ sơ và tài khoản disabled có thông báo riêng; lỗi bất thường ghi Crashlytics. Auth gate giữ trạng thái khởi tạo thay vì hiện dữ liệu người dùng trước khi xác định xong phiên.

### 5.2. Tra cứu, lọc và xem công thức

**Luồng:** AuthGate nạp danh sách công thức → tab Tra cứu áp dụng từ khóa không dấu/danh mục và giới hạn kết quả → mở chi tiết món → chọn size nếu món có nhiều định lượng → xem nguyên liệu/thứ tự thao tác/lưu ý → đi tới video, SOP, gửi phản hồi hoặc bắt đầu Tự luyện.

**Nguồn và quyền:** `FirestoreRecipeSource` là mặc định; Viewer chỉ đọc công thức `published`, Admin có thể đọc cả nội dung ẩn theo rules. Gateway chỉ dùng nếu `RECIPE_SOURCE=gateway`; base URL có thể đặt bằng `API_BASE_URL`. Không có mock fallback cho danh sách công thức production.

**Cấu hình:** kết quả tối đa mặc định 50, Remote Config clamp 1–200. Khi tăng ngưỡng, ViewModel nạp thêm dữ liệu; trạng thái có loading/empty/error và retry.

**Dữ liệu:** sự kiện `view_recipe` gửi phân loại món/size/source cùng mã công thức nội bộ cho Analytics. Mã kỹ thuật không phải nội dung hiển thị cho người dùng.

### 5.3. Video hướng dẫn từng bước

**Luồng:** mở món có `videoUrl` → phát video và timeline theo danh sách bước → chọn bước để tìm vị trí tương ứng → mở toàn màn hình ngang/quay lại màn dọc.

Video được stream từ URL gắn với recipe. Storage rules cho phép người đăng nhập đọc `recipe-videos/{code}/{file}`; chỉ Admin được tải lên/cập nhật/xóa MP4 có kích thước dưới 100 MB. Nếu video không có URL, mạng lỗi hoặc plugin không khởi tạo được, màn hiện lỗi/không khả dụng thay vì giả lập video.

### 5.4. SOP và sổ tay

**Tab SOP trong Tra cứu/chi tiết:** đọc `sops` đã published; trình bày mã phiên bản, ngày phát hành, tóm tắt, bước, ghi chú và các món liên kết. Lỗi tải có thể thử lại. App không cho sửa nội dung SOP.

**Sổ tay:** ghép nội dung SOP thành trang sách có lật/trang mục lục; trang hiện tại có trạng thái dùng trong phiên; có thể xuất toàn bộ sổ tay thành PDF về thiết bị (`Download/RecipeHub`). Nếu có file SOP PDF trên Storage thì app lấy URL `sop/{code}.pdf`; người đăng nhập chỉ có quyền đọc.

### 5.5. Việc học, tiến độ và cần học lại

**Luồng Barista:** mở tab Việc học → xem nhiệm vụ đang active và trạng thái → mở task → đọc nội dung theo từng phần → đánh dấu hoàn thành phần → tiến độ được lưu → xem trang tiến độ cá nhân và đánh giá tay nghề. Task có hạn hoàn thành/trạng thái trễ; kết quả đánh giá chưa đạt hoặc có yêu cầu học lại được thể hiện lại cho nhân viên.

**Đồng bộ:** `TrainingViewModel` theo dõi realtime SOP, `learningTasks`, tiến độ, quiz, bài làm và kết quả đánh giá cá nhân. Tiến độ lưu ở `users/{uid}/taskProgress/{taskId}` với trạng thái `notStarted`, `inProgress`, `completed`, danh sách phần hoàn thành và tỷ lệ 0–1. Người dùng chỉ ghi được tiến độ của chính mình; Admin được đọc theo rules.

**Giới hạn:** Admin mobile theo dõi tiến độ và đánh giá, không có màn tạo/sửa nhiệm vụ học; nội dung được quản lý ở web/backend ngoài app.

### 5.6. Quiz kiến thức

**Luồng:** chọn quiz → nhận danh sách câu hỏi không chứa đáp án → chọn đáp án → nộp lần làm → bài nộp được ghi bất biến → sau lần nộp đầu client mới đọc answer key để chấm → hiện kết quả và đáp án/giải thích → có thể làm lần tiếp theo nếu dữ liệu quiz cho phép.

**Quy tắc:** câu hỏi tại `quizzes/{quizId}`; đáp án tại `quizzes/{quizId}/answerKey`. `quizAttempts` lưu người làm, lựa chọn, điểm/tổng và thời điểm nộp; ID lần đầu gắn với uid/quiz/attempt number. Bài nộp không được sửa/xóa qua rules. Answer key chỉ đọc được sau khi tồn tại lần nộp đầu của chính tài khoản (Admin có quyền đọc).

**Lỗi:** bài nộp trùng, quyền bị từ chối, mất mạng hoặc quiz đã bị gỡ trả thông báo thân thiện; trang dữ liệu có trạng thái tải/rỗng/lỗi.

### 5.7. Tự luyện có bấm giờ

**Luồng:** Barista vào từ món hoặc nút Tự luyện → chọn món, không bắt buộc chọn size → bắt đầu đồng hồ đếm thời gian đã luyện → có thể tạm dừng/tiếp tục → hoàn tất và nhập ghi chú → ghi bản luyện vào lịch sử cá nhân. Tự luyện không bắt buộc chấm điểm.

**Lịch sử:** cache máy theo UID và đồng bộ Firestore `users/{uid}/practiceRecords`, giới hạn tải gần nhất 200 bản ghi; bản ghi tạo offline được giữ ở cache để đẩy lại khi có mạng. Ghi trên server chỉ thêm, không sửa; chủ tài khoản có thể xóa theo rule. Admin có quyền đọc theo rules nhưng màn mobile hiện tại không hiển thị một trang lịch sử nhân viên riêng.

**Chỉ số lịch sử:** số buổi và thời gian trung bình. Tỷ lệ nằm trong sai số chỉ tính buổi có `targetSeconds > 0`; đạt nếu độ lệch tuyệt đối ≤ 5 giây. Khi không có buổi có target, tỷ lệ không hiển thị.

### 5.8. AI hỏi ôn trong lúc thực hành

**Mục tiêu và ranh giới:** AI đặt câu hỏi giúp nhớ nguyên liệu, định lượng, thứ tự pha và SOP của đúng món đang luyện. Đây là hỗ trợ ghi nhớ, không chấm điểm, không đẩy câu trả lời cho Admin và không lưu transcript/lịch sử chat. Không phải chatbot tự do.

**Luồng:** chọn món → bật ôn → bấm giờ → câu đầu sau 3 giây → câu kế tiếp sau 5 giây tính từ lúc tiếp tục/bỏ qua (đặt ở self_practice_timer_page để demo nhanh; mặc định ViewModel 10/20 giây) → mỗi lần chỉ một câu, tối đa 5 câu/bộ. Đồng hồ vẫn chạy khi trả lời. Người dùng chọn một đáp án; UI phản hồi, giải thích và nguồn/phiên bản. Có gợi ý, bỏ qua, thu gọn/tắt AI, tạm dừng. Khi app xuống nền thì tự pause. Đổi món/thoát khi phiên còn hoạt động yêu cầu xác nhận; reset dùng lại bộ câu đã xác minh thay vì gọi model lại.

**Nguồn sự thật:** `RecipeRecallBuilder` sinh candidate từ dữ liệu recipe, nguyên liệu, thứ tự bước và SOP liên kết đã phát hành. Câu/đáp án đúng/giải thích lấy từ nguồn; không suy diễn thông số chưa có, không trộn các size khác định lượng (món nhiều size chỉ lấy phần chung đã xác định). Gemini chỉ chọn thứ tự/ref trong danh sách candidate; schema và validator loại ref lạ/trùng/không hợp lệ. Vì vậy model không tự tạo đáp án hoặc kiến thức pha chế.

**Cấu hình:** Firebase AI Logic gọi Gemini qua Firebase; mặc định model compile-time `AI_MODEL=gemini-3.5-flash-lite`. Temperature `0.2`, tối đa `1024` output tokens, timeout `15` giây, JSON schema `refs` từ 1–5 ID đã cung cấp. Tối đa 3 lần thử trong một phiên. App Check token được lấy trước lời gọi. Cờ Remote Config `enable_ai_assist` mặc định false; build demo có thể bật `AI_DEMO_ENABLED=true` mà không cần bật toàn cục.

**Fallback và bảo vệ nội dung:** khi AI lỗi mạng, App Check, billing, quota hoặc model, người dùng có thể thử lại hoặc chuyển sang câu mẫu theo luật từ cùng nguồn Firestore; câu mẫu được gắn nhãn rõ và không báo là AI đã thành công. Nếu nguồn đổi/thu hồi/không xác thực được, bộ AI bị đóng; timer vẫn chạy. Câu đang chờ cũ bị hủy khi đổi món/reset để không hiện lẫn nguồn.

**Xác minh gần nhất:** snapshot audit gồm 61 công thức, 25 SOP và 1.151 candidate hợp lệ về cấu trúc; kiểm tra model API 61/61 HTTP 200, 75.697 tokens tổng và độ trễ lớn nhất 2.086 ms trong lượt audit. Trên Redmi 7 đã kiểm tra luồng với Americano Nóng, Gấm và LangBiang; không khẳng định đã kiểm tra thủ công mọi tổ hợp mọi món trên thiết bị.

### 5.9. Đánh giá tay nghề tại quầy

**Luồng:** Admin vào Đào tạo hoặc chọn nhân viên → chọn món → app nạp checklist mẫu theo recipe code → chấm từng tiêu chí (đạt/chưa đạt, tiêu chí trọng yếu, ghi chú) → nhập nhận xét tổng/kế hoạch học lại → lưu kết quả bất biến → Barista xem đánh giá của mình và hành động học lại nếu cần.

**Dữ liệu/quyền:** tiêu chí đọc từ `evaluationCriteria`; kết quả lưu `evaluations` gồm trainee/evaluator, recipe/version, checklist, kết luận và thời điểm. Chỉ Admin tạo; Admin và đúng Barista được đọc. Không sửa/xóa đánh giá sau khi tạo.

### 5.10. Bảng Đào tạo Admin

AdminTrainingViewModel chỉ bắt đầu các subscription khi phiên có `serverRole=admin`. Theo dõi nhân viên active, nhiệm vụ, đánh giá, tiêu chí và tiến độ từng người; tổng hợp tỷ lệ hoàn thành, việc trễ và đánh giá mới nhất. Lỗi realtime có retry. Tab không đồng nghĩa mobile quản lý nội dung: phát hành SOP/task/quiz và quản lý tài khoản vẫn thuộc công cụ quản trị phía server/web.

### 5.11. Phản hồi và hội thoại Barista ↔ Admin

**Luồng Barista:** tạo phản hồi dạng hỏi (`inquiry`), lỗi (`issue`) hoặc đề xuất (`suggestion`) → chọn món/SOP đích, nhập nội dung và có thể thêm ảnh → ảnh tải Storage trước, bản phản hồi ghi Firestore với `newFeedback` → theo dõi trạng thái/hội thoại realtime → trả lời bổ sung khi Admin yêu cầu.

**Luồng Admin:** danh sách realtime tất cả phản hồi (tối đa 200) → lọc tình trạng → mở chi tiết/ảnh → trả lời và có thể đổi status cùng transaction batch → Barista nhận phản hồi trong cùng thread. Status: `newFeedback`, `inProgress`, `waitingInfo`, `resolved`, `closed`. Chỉ Admin cập nhật status; Barista xem phản hồi của mình. Tin nhắn không sửa/xóa.

**Đính kèm:** ảnh PNG/JPEG/JPG/WEBP/HEIC/HEIF dưới 5 MiB, thuộc `feedback/{uid}/...`; owner/Admin đọc, owner ghi/xóa. Nội dung Firestore giới hạn 2.000 ký tự; dữ liệu hình ảnh chỉ là file đính kèm, không gửi đến AI.

### 5.12. Thông báo đẩy

**Luồng:** sau đăng nhập, app xin quyền khi cần → lấy FCM token → lưu dưới `users/{uid}/devices/{sha256(token)[0..32]}` kèm platform/model/version → lắng nghe foreground/background/tap → ghi lịch sử cục bộ tách theo UID → chuông mở trang Thông báo. Trước sign-out, app xóa token thiết bị (có timeout để đăng xuất không treo nếu offline). Khi đổi token, registry được cập nhật.

Foreground có banner/tap action; background/terminated hiển thị notification tray và mở app theo payload nếu còn thuộc phiên hiện tại. Lịch sử/hàng đợi local giới hạn tối đa 100 thông báo pending. Gửi broadcast/target là chức năng Admin/backend ngoài mobile; collection `notifications` và `stats` chỉ server ghi theo rules.

### 5.13. Tài khoản và mật khẩu

Trang Tài khoản hiện thông tin hiển thị, role, các lối tắt tới lịch sử/tiến độ phù hợp, lựa chọn Admin xem như Barista, đồng bộ cấu hình khi có action, điều khiển/demo thông báo và đăng xuất. Đổi mật khẩu chỉ áp dụng tài khoản dùng email/password; Google/guest không đi qua luồng này. Thông tin role không lấy từ công tắc client để cấp quyền.

### 5.14. Xuất PDF và tài liệu

- Lịch sử tự luyện tạo PDF gồm dữ liệu buổi tập, có thể lưu ở `Download/RecipeHub` và tải lên `reports/{uid}/...`; UI báo riêng kết quả lưu máy và upload để người dùng giữ được bản local khi mạng lỗi.
- Sổ tay SOP tạo PDF và lưu thiết bị; file SOP có thể đọc từ `sop/{code}.pdf`.
- Cloud Storage báo tiến độ upload/cancel; file report chỉ owner đọc/xóa/ghi, PDF tối đa 5 MiB theo rules.

### 5.15. Báo lỗi, Crashlytics và khôi phục

- Firebase Crashlytics nhận lỗi Flutter là non-fatal, lỗi async/platform là fatal; gắn `build_mode`, user ID và role khi đăng nhập. Lỗi trùng loại/nội dung chỉ được tạo incident một lần trong phiên.
- Incident được stash local trước, gửi Firestore khi có thể; khởi chạy phiên sau có thể flush bản sự cố cũ. Người dùng phải đăng nhập (kể cả guest) để tạo incident; Admin đọc/cập nhật trạng thái xử lý. Không xóa incident qua mobile.
- Nút “Gây crash”/“Ghi non-fatal” là demo chẩn đoán, phụ thuộc `show_crash_demo`; không phải thao tác nghiệp vụ thường ngày.
- Luồng dữ liệu có loading/empty/error và retry ở các trang hỗ trợ. Mất mạng, thiếu quyền, tài liệu bị gỡ và dịch vụ AI/Storage lỗi được đổi thành thông báo người dùng; một số dữ liệu lịch sử có cache offline.

## 6. Firebase collections, quyền và lưu trữ

### Firestore

| Đường dẫn | Tác dụng chính trong mobile | Quyền khái quát theo rules |
| --- | --- | --- |
| `users/{uid}` | Hồ sơ, role/status do server quản lý, `lastSeenAt` | Owner/Admin đọc; client chỉ cập nhật `lastSeenAt`; không tự tạo/xóa hồ sơ |
| `users/{uid}/devices/{deviceId}` | FCM token và metadata thiết bị | Owner/Admin đọc; owner ghi/xóa token hợp lệ |
| `recipes/{code}` | Công thức, size, bước, media/version | User đăng nhập đọc published; Admin đọc hidden và ghi theo schema; xóa bị cấm |
| `sops/{code}` | SOP, bước, phiên bản, món liên quan | User đăng nhập đọc published; Admin ghi; xóa bị cấm |
| `learningTasks/{id}` | Việc học và section | User đọc active; Admin ghi; xóa bị cấm |
| `users/{uid}/taskProgress/{taskId}` | Checklist và tiến độ của nhân viên | Owner tạo/cập nhật; Admin đọc; không xóa |
| `quizzes/{quizId}` | Câu hỏi quiz, không kèm answer key | User đăng nhập đọc; Admin tạo/cập nhật; xóa bị cấm |
| `quizzes/{quizId}/answerKey/{doc}` | Đáp án đúng | Admin đọc; người dùng chỉ đọc sau khi có lần nộp đầu của chính mình; Admin ghi |
| `quizAttempts/{attemptId}` | Bài nộp và điểm | Owner/Admin đọc; user tạo bài đúng uid/attempt; bất biến sau tạo |
| `evaluationCriteria/{group}` | Template checklist thực hành | User đọc; Admin ghi |
| `evaluations/{id}` | Đánh giá tay nghề | Barista đọc đánh giá của mình; Admin đọc/tạo; bất biến |
| `users/{uid}/practiceRecords/{id}` | Lịch sử tự luyện | Owner/Admin đọc; owner tạo/xóa; không sửa |
| `feedback/{id}` | Phản hồi, metadata và status | Owner đọc phản hồi của mình; Admin đọc tất cả/đổi status; không xóa |
| `feedback/{id}/replies/{rid}` | Hội thoại Barista/Admin | Owner/Admin đọc; người tham gia tạo tin; không sửa/xóa |
| `incidents/{id}` | Báo cáo lỗi mobile để Admin xử lý | Auth tạo theo schema; Admin đọc/cập nhật status/ghi chú; không xóa |
| `notifications/{id}`, `stats/{...}` | Bản tin hệ thống/thống kê server | Admin đọc; client không ghi |

Các rules kiểm tra claim `role`, hồ sơ hiện tại, `disabled`, schema/độ dài và timestamp server ở các thao tác quan trọng. Bảng trên tóm tắt quyền; `firebase/firestore.rules` là nguồn có tính quyết định.

### Cloud Storage

| Đường dẫn | Mục đích | Giới hạn/quyền |
| --- | --- | --- |
| `feedback/{uid}/{file}` | Ảnh phản hồi | Owner ghi/xóa, Owner/Admin đọc; hình ảnh hỗ trợ PNG/JPEG/JPG/WEBP/HEIC/HEIF, <5 MiB |
| `reports/{uid}/{file}` | PDF báo cáo tự luyện | Owner ghi/đọc/xóa; `application/pdf`, <5 MiB |
| `sop/{file}` | Tài liệu SOP PDF | Tài khoản đăng nhập đọc; app không ghi |
| `recipe-videos/{code}/{file}` | Video pha chế | Tài khoản đăng nhập đọc; Admin ghi/xóa MP4 <100 MiB |
| Mọi path khác | — | Mặc định từ chối đọc/ghi |

## 7. Trạng thái dữ liệu và lỗi theo luồng

| Tình huống | Hành vi được triển khai |
| --- | --- |
| Chưa xác định Auth | AuthGate chờ trạng thái phiên; chưa mở tab có dữ liệu cá nhân |
| Chưa có kết quả tra cứu/task/feedback | Trạng thái rỗng thay cho danh sách giả |
| Firestore/Gateway lỗi | Error text và retry nơi có hỗ trợ; recipes không chuyển sang mock data |
| Mất mạng khi đọc lịch sử tự luyện | Trả cache local theo UID; ghi offline được giữ để sync lại |
| Mất mạng khi upload report | Hiển thị trạng thái lưu máy riêng với upload; có thể giữ/mở file đã lưu local |
| AI quota/billing/App Check/model/network lỗi | Thông báo phân loại và chuyển ôn câu mẫu cùng nguồn; không dừng đồng hồ luyện |
| AI source đổi/withdrawn | Hủy/khóa bộ câu dựa trên source cũ; không hiển thị kết quả muộn |
| Tài khoản bị disable | Thu hồi phiên/sign out và báo nguyên nhân |
| Không có quyền | Rules chặn ở server; repository/UI chuyển lỗi quyền thành thông báo |
| Notification cũ sau đăng xuất | Payload được đối chiếu thời điểm đăng nhập phiên hiện tại; lịch sử tách scope theo UID |

## 8. Analytics và chỉ số vận hành

`FirebaseAnalyticsService` định nghĩa 8 event: `login`, `logout`, `view_recipe`, `start_brew_timer`, `complete_brew_timer`, `submit_feedback`, `export_report_pdf`, `trigger_test_crash`. Tham số đi qua `AnalyticsEvent.sanitize`; user property gồm `user_role`, `auth_mode`, `store_code`. Cần hiểu Analytics như telemetry sản phẩm, không phải chấm điểm đào tạo.

Crashlytics/incident là kênh lỗi riêng, không thay thế phản hồi nghiệp vụ. Incident có trạng thái xử lý `open`, `acknowledged`, `resolved`, `dismissed`. Phần quản lý sự cố chi tiết và dashboard thống kê thuộc Admin/backend; mobile chủ yếu ghi nhận/surface lỗi.

## 9. Kiểm chứng hiện trạng và giới hạn

Báo cáo xác minh AI/thiết bị trong repository ghi nhận tại ngày 11/11/2026:

- `flutter analyze`: 0 issue.
- `flutter test`: 319 test pass.
- Coverage lõi AI: 96,9% (340/351 dòng) cho builder/context/ViewModel; không đại diện coverage toàn ứng dụng hay SDK cloud.
- Audit recipe/SOP và model: 61 món, 25 SOP, 1.151 candidate hợp lệ; 61/61 request audit trả HTTP 200; 75.697 tokens; latency lớn nhất 2.086 ms trong snapshot đó.
- AI đã được chạy trên Redmi 7 với ba món nêu tại mục 5.8; chưa kiểm tra thủ công từng món và mọi trạng thái trên thiết bị.
- Đã có test giao diện/trạng thái cho kích thước thiết bị nêu trong báo cáo AI; kết quả đó không thay cho kiểm thử đầy đủ mọi thiết bị, role và cấu hình production.

Kiểm tra lại trong phiên lập báo cáo ngày 12/11/2026 trên worktree hiện có: `flutter analyze` không có issue; `flutter test` pass **321 test**. Số test cao hơn snapshot 319 ở báo cáo ngày 11/11 do worktree hiện tại có thêm test. Các lệnh chạy trên toàn bộ worktree hiện tại, không chỉ trên file tài liệu mới.

Các số liệu là snapshot theo tài liệu `docs/ai-full-verification-20261111.md`; số liệu cloud, danh mục dữ liệu và test có thể thay đổi sau ngày audit. Tài liệu này không tuyên bố rằng app đã có đăng ký tài khoản, chatbot tự do, chấm điểm AI, CRUD đào tạo trên mobile hay quyền Admin được cấp bởi lựa chọn trên giao diện.

## 10. Tài liệu/mã tham chiếu

- [Kiến trúc](architecture.md)
- [Khoảng trống backend/API](mobile-backend-api-gaps.md)
- [AI question builder](../lib/core/services/ai/recipe_recall_builder.dart)
- [AI practice ViewModel](../lib/core/viewmodels/ai_practice_viewmodel.dart)
- [Firebase AI Logic adapter](../lib/core/services/firebase/firebase_ai_practice_service.dart)
- [Firebase README](../firebase/README.md)
- [Firestore rules](../firebase/firestore.rules)
- [Storage rules](../firebase/storage.rules)
- [Remote Config template](../firebase/remoteconfig.template.json)

## 11. Đối chiếu Figma redesign với hệ thống hiện tại

### 11.1. Phạm vi Figma đã kiểm tra

- File: [Redesign RecipeHub Mobile](https://www.figma.com/design/XwsHKm5aLZULEg5VTGLrjZ/Redesign-RecipeHub-Mobile?node-id=51-2).
- Ngày đối chiếu: 12/11/2026.
- Các page đã đọc: `00 · Tổng quan`, `01 · User journey & flow`, `02 · Wireframe`, `03 · Hi-fi`, `04 · Final UI`, `05 · Components`, `06 · States & patterns`, `07 · Design system`, `08 · Assets`, `09 · Prototype`.
- `04 · Final UI` hiện có **40 frame màn hình/trạng thái**, kích thước chuẩn `430 × 932`.
- Việc đối chiếu dùng cấu trúc layer, tên component/action, prototype flow và ảnh render của các màn đại diện. Đây là audit chức năng và khả năng tích hợp; không phải xác nhận pixel-perfect hoặc prototype đã nối đủ mọi interaction.

### 11.2. Kiến trúc thông tin của UI mới

UI mới giữ mô hình 4 tab theo vai trò:

- Barista: **Tra cứu → Việc học → Phản hồi → Tài khoản**.
- Quản lý: **Tra cứu → Đào tạo → Phản hồi → Tài khoản**.

Các luồng được thể hiện rõ trong Final UI gồm:

- Tra cứu công thức/SOP, xem chi tiết và gửi góp ý theo bước.
- Sổ tay: đọc tiếp, mục lục, tìm kiếm, tạo/mở/tải/chia sẻ PDF.
- Việc học: đọc công thức → làm quiz → tự luyện.
- Quiz: trả lời từng câu và xem kết quả/giải thích.
- Tự luyện: sẵn sàng, đang chạy, tạm dừng, kết thúc, ghi nhận.
- Phản hồi: tạo phản hồi có ảnh, xem chi tiết, Admin trả lời, trạng thái gửi thành công.
- Đào tạo: danh sách nhân viên cần xử lý, chấm rubric, xem kết quả đã đánh giá.
- Trạng thái/pattern dùng chung: loading, empty, offline, validation, quiz, timer, feedback, exit guard và PDF.

UI mới có ngôn ngữ thị giác nhất quán, phân cấp nội dung rõ và đã tách luồng Barista/Quản lý. Tuy nhiên, các frame hiện tại mới đại diện cho happy path và một số trạng thái mẫu; chưa đủ làm danh sách route hoàn chỉnh để thay toàn bộ UI production.

### 11.3. Ma trận giữ tính năng khi thay UI

| Nhóm chức năng hiện tại | Mức bao phủ trong Figma mới | Kết luận tích hợp | Việc phải làm trước khi cắt UI cũ |
| --- | --- | --- | --- |
| Đăng nhập email/Google/guest, quên mật khẩu, tài khoản bị khóa | **Thiếu** | Không thể bỏ `AuthGate`/`AuthViewModel` | Bổ sung Login, reset password, auth loading/error, disabled-account và Google-cancel state |
| Shell 4 tab theo role | **Có, nhưng thiếu trạng thái quyền** | Có thể bind lại `AuthViewModel` và role guard | Khóa tab theo `serverRole`; không dùng chip UI để nâng quyền |
| Thông báo FCM, badge, lịch sử, deep link | **Thiếu** | Backend/service đã có nhưng không có điểm vào UI | Bổ sung chuông/badge, trang lịch sử, permission state và deep-link destination |
| Tra cứu/lọc công thức và SOP | **Có một phần** | Tái dùng `RecipeViewModel`, `TrainingViewModel`, Remote Config | Bổ sung loading/empty/error/retry, giới hạn kết quả động và dữ liệu danh mục thật |
| Chi tiết công thức theo size, ghi chú, yêu cầu đặc biệt | **Có một phần** | Model/backend hiện có phần lớn dữ liệu | Bổ sung size selector, warning/note, special request, metadata phiên bản và trạng thái thiếu dữ liệu |
| Video hướng dẫn theo timeline bước | **Thiếu**; Figma ghi video chưa có trong prototype | `StepVideoViewModel` và `videoUrl` vẫn phải giữ | Thiết kế màn video, loading/error, fullscreen và thao tác nhảy tới bước |
| SOP catalog/chi tiết | **Có** | Tái dùng `ITrainingRepository.watchSops()` | Bổ sung version/published date, linked recipe và loading/empty/error |
| Sổ tay, tìm kiếm và PDF | **Có tốt** | Tái dùng `SopBookViewModel`, report/file service | Làm rõ tải/mở/chia sẻ; giữ lỗi tạo/lưu/mở PDF và quyền thiết bị |
| Nhiệm vụ học, checklist section, hạn, tiến độ, học lại | **Thiếu phần lớn** | Figma mới chỉ biểu diễn một learning focus tuyến tính | Bổ sung danh sách task, task detail/checklist, due/overdue, progress và relearn |
| Quiz và kết quả | **Có happy path** | Tái dùng submit bất biến và answer-key guard | Bổ sung loading/error, submit guard, retry, attempt number và quiz bị gỡ |
| Tự luyện/bấm giờ | **Có luồng chính** | Tái dùng timer và `IPracticeHistoryStore` | Bổ sung chọn size/target nếu có, app lifecycle, exit guard, save lỗi/retry và offline sync |
| AI hỏi ôn trong phiên luyện | **Có đủ 6 trạng thái Final UI** | Giữ `AiPracticeViewModel`/Firebase AI Logic | Đã map sẵn sàng/chuẩn bị/câu hỏi/phản hồi/lỗi/hoàn tất, fallback câu mẫu và nguồn câu hỏi |
| Lịch sử tự luyện, thống kê, PDF báo cáo | **Thiếu** | Backend/cache/report hiện có nhưng không có UI mới | Bổ sung history, empty/error, chỉ số, xóa theo quyền, tạo/lưu/upload/mở PDF |
| Đánh giá thực hành | **Có một phần** | Có thể bind `AdminTrainingViewModel` và criteria thật | Không hardcode 3 tiêu chí; bổ sung chọn nhân viên/món/template, validation, nhận xét, lịch sử và Barista xem kết quả |
| Phản hồi hai chiều + ảnh + status | **Có một phần** | Firestore/Storage hiện đủ cho luồng chính | Bổ sung loại phản hồi, preview/xóa/upload ảnh, thread nhiều reply, Barista trả lời bổ sung, status/filter đầy đủ và lỗi upload |
| Tài khoản, đổi mật khẩu, đăng xuất | **Thiếu một phần lớn** | Profile có trong Figma; thao tác tài khoản chưa có | Bổ sung đổi mật khẩu theo provider, đăng xuất, auth-mode, notification permission và lỗi profile |
| Crash/incident/recovery | **Chỉ có pattern lỗi chung** | Giữ reporting ngầm; demo crash không cần hiện production | Bổ sung recovery theo màn; để công cụ chẩn đoán sau debug/admin guard |
| Analytics 8 event hiện có | **Không thể hiện trong Figma** | Không phải UI nhưng phải giữ khi thay route/action | Map lại event tại đúng action mới và giữ schema tham số hiện tại |

### 11.4. Trạng thái triển khai UI Final ngày 12/11/2026

- Đã ánh xạ đủ **40/40 frame** thành route hoặc trạng thái động trong Flutter; các frame ready/loading/question/feedback/error/success dùng chung ViewModel thay vì tạo màn dữ liệu giả.
- Đã thay shell 4 tab, tra cứu/recipe, SOP catalog/detail, learning/quiz, practice/AI, feedback, handbook/PDF, assessment, account Viewer/Admin và settings bằng token Be Vietnam Pro trong `NomadKit`.
- Các thao tác dữ liệu tiếp tục dùng repository/ViewModel hiện có: recipe/SOP/task/quiz/evaluation/feedback/reply/practice/PDF/AI; không thêm mock vào `lib/`.
- Exit guard phản hồi, picker món, trạng thái gửi thành công, quiz result, practice pause/end/recorded, assessment success và 6 trạng thái AI đã được nối vào luồng thật.
- Nút bookmark trong Figma được render ở trạng thái disabled vì chưa có contract favorites; không giả lập lưu thành công. Đây là gap backend/product P2, không làm mất tính năng cũ vì app cũ chưa có favorites.
- Network simulation chỉ có thể xuất hiện trong debug; bản release không cho người dùng production can thiệp kết nối.

## 12. Thiếu hụt cần bổ sung vào Figma

### P0 — bắt buộc để không giảm tính năng production

1. **Auth:** Login email/password, Google, guest, quên mật khẩu, đang khởi tạo phiên, lỗi cấu hình Google, tài khoản bị khóa và đăng xuất cưỡng bức.
2. **Thông báo:** badge/entry point, xin quyền, danh sách lịch sử, empty/error và các đích deep link hợp lệ.
3. **Video công thức:** phát video, timeline bước, buffering/error, retry và fullscreen.
4. **Learning đầy đủ:** danh sách nhiệm vụ, chi tiết/checklist section, hạn hoàn thành, quá hạn, tiến độ cá nhân và yêu cầu học lại.
5. **Practice đầy đủ:** AI ôn tập, lịch sử luyện, thống kê, báo cáo PDF, offline/save retry và exit guard gắn vào màn thật.
6. **Feedback đầy đủ:** chọn `inquiry/issue/suggestion`, thread nhiều tin, Barista bổ sung thông tin, Admin đổi đủ 5 status, filter và trạng thái upload ảnh.
7. **Account:** đổi mật khẩu, đăng xuất, trạng thái theo auth provider và lỗi tải profile.
8. **Role security:** chip `Barista/Quản lý` chỉ được phép là chế độ xem của tài khoản có `serverRole=admin`. Với Barista thật, phải ẩn hoặc disable lựa chọn Quản lý.
9. **Data states theo màn:** loading, empty, error, retry, permission denied và offline phải có cho từng màn dữ liệu, không chỉ tồn tại dưới dạng card tham khảo ở page `States & patterns`.

### P1 — cần để ánh xạ đủ dữ liệu hiện có

- Size/định lượng, note/warning, special request và liên kết SOP trong chi tiết công thức.
- Version, ngày ban hành, nội dung liên kết và trạng thái tài liệu bị gỡ/đổi phiên bản.
- Quiz submit-in-progress, submit trùng, attempt kế tiếp và kết quả khi answer key lỗi.
- Danh sách/lịch sử đánh giá của Barista và lịch sử nhân viên cho Admin.
- Feedback attachment preview, hủy ảnh, upload progress/cancel và retry không làm mất nội dung.
- Draft/exit confirmation cho form phản hồi, quiz, đánh giá và phiên luyện.
- Trạng thái tạo/lưu/mở PDF thất bại; phân biệt lưu local thành công với upload cloud thất bại.

### P2 — chức năng mới trong Figma cần chốt phạm vi

- Bookmark công thức ở danh sách/chi tiết và bộ lọc Đã lưu đã có qua `RecipeBookmarkViewModel`/`IRecipeBookmarkStore`, lưu local theo tài khoản; chưa đồng bộ đa thiết bị hoặc hỗ trợ bookmark SOP.
- Ảnh Tra cứu đã nối `recipes.imageUrl` qua Firestore adapter/DTO/mapper/`RecipeItem` tới `RecipeThumb`; Storage path và quyền đã có. Hero chi tiết vẫn cần đối chiếu riêng với Figma.
- Màn `Cài đặt trải nghiệm` riêng đã được xóa; hiệu ứng dùng cài đặt giảm chuyển động của hệ điều hành. Không đưa mô phỏng mạng của prototype vào production.
- `Chia sẻ PDF` đã có qua capability thiết bị của file service; lỗi native được giữ ở UI và đã có test.
- Tìm kiếm trong sổ tay có thể làm local trên dữ liệu đã tải; không cần backend nếu dữ liệu vẫn nhỏ như hiện tại.

## 13. Tác động backend/API của UI mới

### 13.1. Không cần backend mới nếu tái sử dụng đúng contract hiện tại

Các luồng sau đã có repository/service thật: Auth/profile/role, recipe, SOP, learning task/progress, quiz/answer key/attempt, practice history, evaluation, feedback/replies/status, Storage upload, FCM, Remote Config, Analytics, Crashlytics/incident và Firebase AI Logic. Flutter mới phải gọi qua ViewModel/interface hiện có; widget không gọi Firebase SDK, Dio hoặc Storage trực tiếp.

### 13.2. Các yêu cầu backend/data mới hoặc cần quyết định

| Nhu cầu UI mới | Hiện trạng | Đề xuất |
| --- | --- | --- |
| Bookmark/yêu thích công thức và SOP | Công thức đã có interface/store local theo tài khoản; chưa có sync cloud hoặc bookmark SOP | Chỉ thêm repository/Firestore/rules nếu cần đồng bộ đa thiết bị hoặc mở rộng sang SOP |
| Ảnh recipe dùng ở list/detail | `imageUrl` đã xuyên suốt Firestore adapter/DTO/mapper/UI model; Tra cứu tải ảnh qua `RecipeThumb`, có fallback | Cần Internet; hero chi tiết đối chiếu riêng. Script upload/rules ở `tools/seed/` và `firebase/storage.rules` |
| Đồng bộ accessibility giữa thiết bị | Chưa có user preference contract | Mặc định lưu local. Chỉ thêm `users/{uid}/preferences` và rules nếu product yêu cầu sync đa thiết bị |
| Chia sẻ PDF | Đã có `sharePdf` qua native content URI và MIME PDF | Không cần backend; giữ fallback mở file/tải xuống nếu share sheet lỗi |
| Draft phản hồi tồn tại qua lần mở app sau | Figma hiện ghi draft chỉ tồn tại trong phiên | Nếu cần lưu bền: ưu tiên local encrypted/preferences; chỉ thêm backend draft nếu cần đa thiết bị |
| Ảnh chụp trực tiếp trong feedback | `image_picker`/Storage đã có | Xác nhận source camera/gallery và permission UX; thường không cần backend mới |

Mọi thay đổi schema Firestore phải đi cùng rules, index, emulator tests và migration dữ liệu tiến; không sửa/xóa lịch sử migration hoặc dữ liệu production. Nếu bật lại nguồn `.NET Gateway`, phải mở rộng DTO/endpoint tương ứng thay vì để hai nguồn trả model khác nhau.

## 14. Kế hoạch triển khai Flutter redesign

### Giai đoạn 0 — khóa phạm vi và contract

- Chốt các mục P2: bookmark, ảnh recipe, persistence của accessibility, share PDF và draft.
- Bổ sung các frame P0/P1 vào Figma hoặc ghi acceptance criteria đủ rõ cho màn chưa thiết kế.
- Lập bảng `route → ViewModel → interface → Firestore/API → analytics event` cho từng màn.
- Viết characterization test cho ViewModel/service hiện tại trước khi thay widget; không đổi backend và UI cùng một lần nếu không bắt buộc.

### Giai đoạn 1 — nền tảng giao diện mới

- Chuyển token Figma vào `lib/core/theme/nomad_kit.dart`; không hardcode màu, typography, spacing mới trong page.
- Xây component dùng chung: app header, bottom navigation, flow header, button, chip, field, list row, state view, confirmation/exit guard và PDF state.
- Component chỉ nhận state/callback; không biết Firebase, repository hoặc DTO.
- Chuẩn hóa responsive cho chiều rộng nhỏ hơn/lớn hơn 430 và text scale tới 200%.

### Giai đoạn 2 — app shell, Auth và navigation

- Giữ `AuthGate` làm root; thay presentation của Login/Shell nhưng không bỏ bootstrap/profile/device-token hooks.
- Route/tab lấy từ `displayRole`, quyền mutation lấy từ `serverRole`.
- Khôi phục notification entry/deep link trước khi chuyển shell mới thành mặc định.
- Có thể dùng feature flag nội bộ để chạy song song UI cũ/mới trong thời gian migration; không nhân đôi service graph.

### Giai đoạn 3 — tra cứu, recipe, SOP và sổ tay

- Bind Home/SOP tab vào `RecipeViewModel` và `TrainingViewModel`; giữ Remote Config `max_lookup_results`.
- Bind detail vào dữ liệu size, notes, steps, linked SOP và video thật.
- Tích hợp `StepVideoViewModel` thành route riêng.
- Bind handbook/search/PDF vào `SopBookViewModel` và `IFileSaveService`; thêm share client-side nếu được duyệt.

### Giai đoạn 4 — learning, quiz và practice

- Map learning focus trong Figma thành projection của task/progress thật, không hardcode `Caramel Latte` hoặc 3 bước cố định.
- Giữ submit quiz bất biến và answer-key guard; UI kết quả chỉ hiện sau response đã chấm.
- Tách timer UI khỏi lifecycle/persistence logic; giữ cache theo UID và đồng bộ Firestore.
- Bổ sung AI recall, practice history và report PDF trước khi bỏ các page cũ.

### Giai đoạn 5 — feedback và đào tạo Admin

- Bind form feedback vào `FeedbackViewModel`/`StorageViewModel`; upload ảnh xong mới tạo record hoặc có rollback rõ ràng.
- Detail phải stream parent + replies; hỗ trợ Barista/Admin reply theo quyền và Admin đổi status.
- Danh sách Admin dùng `watchAll`, Barista dùng `watchMine`; không lọc quyền chỉ ở client.
- Rubric/nhân viên/món lấy từ repository thật; không dùng dữ liệu mẫu trong frame Figma.

### Giai đoạn 6 — account, notification và recovery

- Hoàn thiện profile, đổi mật khẩu, logout, notification permission/history và admin view-mode.
- Gắn loading/empty/error/offline/retry vào từng route.
- Giữ Analytics, Crashlytics, incident flush và FCM token lifecycle khi thay navigation.
- Cài đặt test như mô phỏng mạng/crash phải nằm sau debug flag hoặc admin diagnostics guard.

### Giai đoạn 7 — cắt chuyển và loại UI cũ

- Chỉ xóa page/widget cũ sau khi ma trận parity có test và route mới đã thay thế.
- Chạy test theo cả Barista/Admin, email/Google/guest, online/offline và account disabled.
- Kiểm tra deep link notification, app resume trong timer, upload ảnh/PDF, role switch và quyền Firestore trên thiết bị thật.
- Trước khi báo hoàn tất: `flutter analyze` 0 issue và `flutter test` pass; sau đó chạy bộ E2E trọng yếu trên Android thật.

## 15. Quy tắc tích hợp để bạn code UI không làm gãy backend

1. Page/widget chỉ đọc state và gọi action trên ViewModel; không gọi SDK trực tiếp.
2. Giữ các interface trong `AppServices` làm ranh giới. Nếu UI cần capability mới, mở rộng interface trước rồi mới viết adapter Firebase/device.
3. Không truyền raw Firestore document/DTO vào widget; map sang model/view state ổn định.
4. Mọi màn tải dữ liệu phải có `loading/empty/error/data`; action ghi phải có `idle/submitting/success/failure` và chống submit lặp.
5. Không hiển thị ID/code kỹ thuật; route dùng ID nội bộ nhưng tiêu đề/UI dùng tên nghiệp vụ.
6. Không hardcode dữ liệu mẫu từ Figma (`Caramel Latte`, `Ngọc Linh`, số lượng 6 món/3 SOP, 3 rubric item).
7. Giữ real-time stream cho feedback, training/progress, profile disable và Remote Config; không đổi thành fetch một lần chỉ vì mockup tĩnh.
8. Mọi role/action quan trọng phải được backend/rules xác thực; UI ẩn nút không phải cơ chế phân quyền.
9. Giữ analytics event tại action nghiệp vụ, không gắn vào `build()` hoặc render lại widget.
10. Không thêm mock data vào `lib/`; fake chỉ được inject trong test.

## 16. Definition of Done cho redesign

- Tất cả hàng trong ma trận mục 11.3 đạt parity hoặc có quyết định product bằng văn bản.
- Không còn action nhìn như hoạt động nhưng chưa có callback/backend contract, đặc biệt bookmark, role switch, upload ảnh và share PDF.
- Hai role truy cập đúng tab, dữ liệu và mutation; Barista không thể tự chuyển thành Admin.
- Auth, notification/deep link, offline, permission, loading/empty/error và app lifecycle có test.
- Dữ liệu production đến từ Firestore/Gateway thật; không lấy text/data mẫu từ Figma làm nguồn.
- Theme mới dùng token tập trung và đạt text scale 200%, màn 430 × 932 và thiết bị Android nhỏ đang dùng để E2E.
- `flutter analyze` 0 issue, `flutter test` pass và các ca E2E trọng yếu pass trên thiết bị thật trước khi xóa UI cũ.
