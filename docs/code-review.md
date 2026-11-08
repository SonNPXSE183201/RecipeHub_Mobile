# Code review – Lab 3 (PR #2 `feat/lab3-firestore-realtime-ui` → `dev`)

Phạm vi: toàn bộ thay đổi của PR #2 (dữ liệu Firestore real-time, sổ tay SOP, video, PDF, phản hồi có ảnh, thông báo).

Nguồn phát hiện:

| Nguồn | Cách chạy | Số phát hiện |
| :-- | :-- | :-- |
| CodeRabbit (GitHub App) | `@coderabbitai review` trên PR #2, comment theo dòng | 12 |
| Codex CLI `codex review` (`gpt-6.1-sol`) | `codex review --base origin/dev` trong worktree của nhánh PR | 4 |
| Kiểm thử thủ công trên Redmi 7 (FCM + quay video demo) | FCM test message từ Firebase Console ở foreground / background / terminated (ngày 08/11/2026) | 4 |

Tổng cộng 20 phát hiện (19 mục sau khi gộp trùng), trong đó 1 phát hiện trùng giữa hai nguồn (CodeRabbit #8 = Codex CR-01). Mỗi phát hiện được tự đọc lại code để xác nhận trước khi quyết định.

## Bảng phát hiện và quyết định

Loại: **bug**, **security**, **architecture**, **performance**, **test gap**, **maintainability**.

| Mã | Nguồn | File | Loại | Mức | Phát hiện | Quyết định | Lý do | Commit |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- | :-- |
| CR-01 | Codex P1, CodeRabbit #8 | `auth_gate.dart`, `training_viewmodel.dart` | bug, security | Cao | `AdminTrainingViewModel` không được reset khi đăng xuất, nên giữ subscription, dữ liệu nhân viên và cờ `_started`. Phiên Admin sau bị kẹt ở trạng thái lỗi, còn dữ liệu đặc quyền vẫn nằm trong bộ nhớ. | Accepted | Rò dữ liệu nhân viên giữa các phiên. Admin đăng nhập lại thì màn Theo dõi đào tạo hỏng. | `386446d` |
| CR-02 | Codex P2 | `training_viewmodel.dart` | bug | Trung bình | Tiến độ nhân viên chỉ đọc một lần, nên Barista hoàn thành mục học mà dashboard Admin không cập nhật. | Accepted | Đi ngược mục tiêu real-time của Lab 3. Sửa bằng `watchProgress` cho từng nhân viên, có quản lý subscription. | `84f7695` |
| CR-03 | Codex P2 | `counter_recipe_lookup_page.dart`, `recipe_viewmodel.dart` | bug | Trung bình | Kết quả tìm trên server chỉ lọc theo từ đầu tiên, nên tìm nhiều từ ra món không liên quan. | Accepted | Sai kết quả tra cứu tại quầy. Logic lọc được chuyển vào ViewModel và có unit test. | `3f27b51` |
| CR-04 | Codex P2 | `learning_task_detail_page.dart` | bug | Trung bình | Nhiệm vụ học trỏ tới món nằm ngoài `max_lookup_results` thì báo "không có". | Accepted | Remote Config giới hạn 50 món trong khi bộ dữ liệu có 61 món, nên lỗi xảy ra thật. Sửa bằng `findForDeepLink`, có trạng thái loading và chặn mở lặp. | `c0117b8`, `5513474` |
| CR-05 | CodeRabbit #11 (Major) | `step_video_guide_page.dart` | bug | Cao | Dụng cụ và tiêu chí hoàn thành của từng bước là text hard-code của một món Cold Brew cam, hiện ra cho mọi món thật. | Accepted | Hiện sai nội dung chuẩn cho Barista. Lỗi này còn sót lại từ dữ liệu mock. | `a2a5c83` |
| CR-06 | CodeRabbit #3 (Major) | `firebase_notification_service.dart` | bug | Trung bình | Khi hàng đợi chờ đầy 100 mục, mọi thông báo mới hơn bị bỏ. | Accepted | Mất thông báo mới nhất, vốn quan trọng nhất. Đã đổi thành giữ 100 mục mới nhất. | `bfd4928` |
| CR-07 | CodeRabbit #9 | `create_feedback_page.dart` | bug | Thấp | Nội dung trên 2000 ký tự bị rule Firestore từ chối, nhưng app báo nhầm là "không có quyền". | Accepted | Thông báo lỗi gây hiểu nhầm. Đã thêm `maxLength` có bộ đếm và kiểm tra trước khi gửi. | `c55a859` |
| CR-08 | CodeRabbit #10 | `recipe_detail_size_page.dart` | bug | Thấp | Mốc video hard-code tiền tố `00:`, nên bước bắt đầu ở giây 75 hiện `00:75`. | Accepted | Sai định dạng thời gian. Màn chi tiết và màn video giờ dùng chung một hàm `mm:ss`. | `5e2a2fd`, `5956250` |
| CR-09 | CodeRabbit #5 | `auth_viewmodel.dart` | maintainability | Thấp | Sai mật khẩu, quá số lần thử và tài khoản bị khóa đều bị ghi lên Crashlytics như lỗi bất thường. | Accepted | Làm nhiễu Crashlytics (lỗi thao tác người dùng không phải crash), che các sự cố thật. | `3fa7dbc` |
| CR-10 | Thủ công (Redmi 7) | `notification_viewmodel.dart`, `auth_gate.dart` | bug | Thấp | Android 10 không có quyền thông báo runtime và FCM vẫn nhận được, nhưng mở lạnh app vẫn hiện hộp "Bật thông báo?". | Accepted | Hỏi quyền thừa, gây khó chịu. Ảnh `evidence/lab3/06-firebase-console/15-fcm-terminated-tap-open.jpg`. | `1c29bb4` |
| CR-11 | Thủ công (Redmi 7) | `notification_viewmodel.dart` | bug | Thấp | Chạm thông báo trên khay mở đúng màn Thông báo nhưng vẫn hiện thêm SnackBar trùng nội dung. | Accepted | Trùng lặp thông tin. SnackBar chỉ dành cho tin đến khi app đang mở. Ảnh `13-fcm-tap-opens-inbox.jpg`. | `3318c15` |
| CR-12 | CodeRabbit #2 | `session_models.dart` | maintainability | Thấp | Thông báo `passwordNotApplicable` nói "đăng nhập bằng Google" và thiếu dấu chấm, trong khi mã này cũng trả về cho khách ẩn danh (nút "Đổi mật khẩu tài khoản" hiện cho mọi người). | Accepted | Ban đầu định Rejected vì nghĩ khách không thấy nút. Khi đọc lại `account_profile_page.dart` thì thấy nút hiện cho mọi người, nên phát hiện đúng. | `b1f3186` |
| CR-13 | CodeRabbit #7 | `training_viewmodel.dart`, `firestore_training_repository.dart` | bug, test gap | Trung bình | Stream tiến độ và lượt làm bài không có trạng thái ready/lỗi. Repository ghi đè toàn bộ `completedSections`, nên tick một mục khi snapshot chưa về có thể xóa các mục đã học. | Accepted | Mất dữ liệu học tập. Ghi bị chặn cho tới khi stream sẵn sàng, kèm thông báo tiếng Việt và test chứng minh không ghi đè. | `7a11cd2` |
| CR-14 | CodeRabbit #4 (Major) | `firestore_training_repository.dart`, `firestore.rules` | bug, architecture | Trung bình | Lượt quiz đầu không lưu `score`, vì đáp án chỉ đọc được sau lượt 1 và rule cấm update, nên tiến độ coi như chưa làm. | Modified (hoãn sang Final) | Sửa đúng cần đổi thiết kế chấm điểm và Security Rules đang chạy production. Đề Final cấm Cloud Functions, nên cơ chế chấm phía client và rule sẽ được thiết kế lại trong Final. Báo cáo Lab 3 ghi nhận giới hạn này. | – |
| CR-15 | CodeRabbit #1 | `MainActivity.kt` | bug | Thấp | Xuất PDF hai lần trong cùng phút thì Android tự đổi tên file (`(1)`), nhưng app trả về tên cũ. | Modified (hoãn) | Chỉ sai tên hiển thị trong SnackBar, vì file vẫn được lưu và mở đúng qua URI. Ưu tiên thấp hơn các lỗi dữ liệu. | – |
| CR-16 | CodeRabbit #6 | `recipe_viewmodel.dart` | bug | Thấp | Listener công thức lỗi sau khi đăng xuất thì lần đăng nhập sau không đăng ký lại real-time. | Modified (hoãn) | Chưa tái hiện được trên Redmi 7. Sẽ sửa cùng phần dọn vòng đời subscription ở Final. | – |
| CR-17 | CodeRabbit #12 | `practical_evaluation_page.dart` | bug | Thấp | Món được chọn trong form chấm không đồng bộ khi danh sách món đổi real-time. | Modified (hoãn) | Chỉ Admin dùng, và món hiếm khi đổi trong lúc đang chấm. Ghi nhận cho Final. | – |
| CR-18 | Quay video demo (Redmi 7) | `sop_book_views.dart`, `practice_history_page.dart` | maintainability | Thấp | Sổ tay SOP và lịch sử tự luyện (kể cả PDF) vẫn hiện mã món như `CF-PHELANN`, trái yêu cầu ẩn mã trên mobile. | Accepted | Mã món là mã kỹ thuật; người dùng tại quầy chỉ cần tên món. | `62c03e5` |
| CR-19 | Quay video demo (Redmi 7) | `main_app_shell.dart`, `practice_history_page.dart` | bug | Thấp | SnackBar "Đã lưu…" bám theo khi đổi tab và che nút "Gửi phản hồi". | Accepted | Che nút chính của màn khác. SnackBar nay ngắn hơn và được ẩn khi rời màn/đổi tab. | `69c2067` |

Thống kê: 15 Accepted (đã sửa, mỗi mục có commit `fix(mobile): CR-xx …`), 4 Modified (hoãn có lý do), 0 Rejected. Các loại gồm bug, security, architecture, test gap và maintainability. Bài học: CR-12 suýt bị Rejected dựa trên giả định sai, nên mọi quyết định đều phải kiểm lại code.

## Kiểm chứng sau sửa

- `flutter analyze`: 0 issue.
- `flutter test`: tăng từ 161 lên 286 test, tất cả pass. Mỗi fix có test riêng, ví dụ `test/admin_training_session_test.dart`, `test/core/viewmodels/recipe_search_test.dart`, `test/auth_crash_reporting_test.dart`, `test/core/utils/video_time_test.dart`.
- CR-04 và CR-08: test do Codex sinh ra ban đầu fail vì dùng `pageBack()` trên trang không có nút back mặc định, vì SnackBar che nút, và vì layout tràn với font test. Đã đọc lỗi và sửa test bằng commit riêng (`5513474`, `5956250`), không nới lỏng assert.

## Công cụ AI đã dùng (disclosure)

| Công cụ | Model | Dùng cho |
| :-- | :-- | :-- |
| Claude Code | Opus 5.5 | Điều phối, đọc và xác nhận từng phát hiện, ra quyết định Accept/Modify/Reject, sửa test hỏng, kiểm thử FCM trên thiết bị |
| Codex CLI | `gpt-6.1-sol`, effort medium | `codex review`, viết bản sửa và test cho CR-01…CR-13 (sandbox `workspace-write`) |
| CodeRabbit | GitHub App | Review theo dòng trên PR #2 |
| Antigravity CLI | Gemini 3.8 Flash | Soạn nháp `docs/test-plan.md` (đã kiểm đường dẫn và nhãn với code) |

Mọi quyết định và lý do do chủ dự án duyệt. Không chấp nhận phát hiện nào khi chưa đọc lại code.
