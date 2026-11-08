# Theo dõi CodeRabbit PR #3–#7

Đối chiếu tại worktree `fix/lab3-coderabbit-findings`, ngày 08/11/2026. Đề bài không phân bổ từng phát hiện cho PR cụ thể, nên cột PR giữ phạm vi #3–#6, không đoán số PR. Dòng là vị trí hiện tại sau sửa; nội dung review chỉ được dùng làm dữ liệu đối chiếu. Không commit/push, không cài dependency hoặc truy cập mạng.

Bổ sung ngày 09/11/2026: đối chiếu 9 mục trong tóm tắt PR #7; các dòng mới ghi PR = #7. Không có bản comment PR #7 đầy đủ trong repo.

| PR | File@dòng | Phát hiện | Quyết định (Đã sửa / Bỏ qua) | Lý do |
| --- | --- | --- | --- | --- |
| #3–#6 | `tools/seed/shuffle_quizzes.py@11` | Đáp án lặp chu kỳ 0,1,2,3 | Đã sửa | Sắp xếp theo SHA-256 của quiz id + câu id + nội dung đáp án, cập nhật correctIndex; chạy lại giữ nguyên thứ tự. 63 câu giữ đáp án đúng; ngoại lệ thay nội dung q9 được ghi riêng. |
| #3–#6 | `tools/seed/quizzes.json@263` | QZ-SUCTRA q9 dẫn SOP-TSLANH | Đã sửa | Thay bằng thao tác dựng thẳng cốc ở 30°C, đúng SOP-SUCTRA bước 3; tránh lặp câu nhiệt độ dừng ở q8. |
| #3–#6 | `tools/seed/quizzes.json@290` | Câu gần dòng 383 dẫn SOP khác | Bỏ qua | QZ-REFILL có tiêu đề “Re-fill nguyên vật liệu và bảo quản trong ca”, là bộ tổng hợp vận hành. q7 về HHSD khớp SOP-THIEUNVL bước 4; q8 về D+5 khớp SOP-BAOQUAN bước 1. reviewSection dẫn đúng dữ kiện; không sửa chỉ vì khác targetCode. |
| #3–#6 | `tools/video/make_videos.py@27` | Font hard-code Windows | Đã sửa | Đọc RH_FONT/RH_FONT_BOLD; fallback Windows/macOS/Linux DejaVu; lỗi có tên biến cần đặt. |
| #3–#6 | `tools/video/make_videos.py@132` | durationSeconds thiếu hoặc ≤0 | Đã sửa | RecipeMapper dùng 10 giây khi duration ≤0; áp dụng cùng mặc định. |
| #3–#6 | `tools/video/make_videos.py@46` | wrap thêm dòng rỗng | Đã sửa | Chỉ append cur khi có nội dung; giữ nguyên từ quá dài. |
| #3–#6 | `tools/video/make_videos.py@155` | Thiếu tham số hoặc mã món không tồn tại | Đã sửa | Usage khi thiếu đối số; kiểm toàn bộ code trước tạo thư mục/build; kiểm font trước build. |
| #3–#6 | `e2e_test/conftest.py@32` | Biến môi trường rỗng | Đã sửa | Đã kiểm value.strip nhưng trước đây skip; đổi sang pytest.fail và chỉ rõ tên biến thiếu/rỗng. |
| #3–#6 | `e2e_test/conftest.py@228` | ADB text không escape shell | Đã sửa | Khoảng trắng → %s; shlex.quote cho shell Android; _type_field dùng helper. Chưa kiểm trên thiết bị. |
| #3–#6 | `e2e_test/conftest.py@110` | Marker phiên còn sau đổi tài khoản/logout | Đã sửa | Invalidate trước TC-19/20/24, kể cả khi thao tác thất bại giữa chừng. fresh_app đã xóa marker từ trước. |
| #3–#6 | `e2e_test/test_search.py@9` | TC-07 dùng món không có trong seed | Đã sửa | Tìm long; yêu cầu thấy Bòng Bưởi - Ô Long Bưởi Nha Đam, assert target_found; không giả định số lượng. |
| #3–#6 | `e2e_test/test_detail.py@14` | TC-11/13 dùng món không tồn tại | Đã sửa | TC-11 dùng Latte Đá; TC-13 dùng Americano Nóng. Cập nhật instruction, JSON, assertion và test-plan. |
| #3–#6 | `e2e_test/test_detail.py@26` | TC-12 cũng dùng món không tồn tại, cần video | Đã sửa | Latte Đá có trong seed và thuộc 3 món có video theo thông tin người dùng. |
| #3–#6 | `e2e_test/test_auth.py@70` | TC-24 dùng tài khoản Viewer chung | Đã sửa | Dùng RH_PASSWORD_TEST_EMAIL/PASSWORD, fresh_app và đăng nhập riêng; cập nhật .env.example và tài liệu. |
| #3–#6 | `e2e_test/test_auth.py@81` | TC-24 thiếu xác nhận mật khẩu | Bỏ qua | Code hiện tại đã nhập cả ô Nhập lại mật khẩu mới; giữ lại. |
| #3–#6 | `e2e_test/test_auth.py@87` | TC-24 phục hồi mật khẩu trong teardown | Đã sửa | Đã có recovery fallback; chuyển phục hồi gốc vào finally cho mọi kết quả, nhập đủ current/new/confirmation, xác nhận đăng nhập mật khẩu gốc rồi logout. |
| #3–#6 | `e2e_test/test_search.py@35` | TC-09 pm clear rồi mở offline để đo lỗi tải | Bỏ qua | pm clear xóa cả Auth; AuthGate chỉ tải công thức sau authenticated. Mở offline sạch sẽ dừng tại Login. Không thể áp dụng đúng kỳ vọng lỗi recipe bằng UI hiện có. Đã thay ca cũ bằng manual/skip rõ lý do; cần setup phiên Auth hợp lệ không kèm cache trước khi tự động hóa. |
| #3–#6 | `e2e_test/test_profile_remote_config.py@9` | TC-21 giả định giá trị config gốc | Đã sửa | Mỗi vòng operator ghi giá trị thực vào baseline-done; chọn target khác gốc; finally handshake khôi phục đúng giá trị. Không suy config từ số card. |
| #3–#6 | `e2e_test/test_practice_export.py@24` | TC-15 giả định nhiệm vụ chưa hoàn thành | Đã sửa | Chọn nhiệm vụ Chưa học; fail rõ nếu không có, không phụ thuộc vòng trước. Tài liệu yêu cầu chuẩn bị nhiệm vụ mỗi vòng. |
| #3–#6 | `e2e_test/test_auth.py@46` | TC-04 yêu cầu UI xin Admin | Đã sửa | Login không có control này. Đánh manual/skip; fallback claim Viewer có Flutter test tại test/admin_link_test.dart, không suy thành E2E pass. |
| #3–#6 | `e2e_test/README.md@85` | Thiếu ADB_LOGIN/E2E_REUSE_SESSION | Đã sửa | Ghi toạ độ Redmi 7 720×1520, phạm vi reuse và invalidate; đồng bộ tài khoản riêng, tên món, TC-09 và handshake TC-21. |
| #3–#6 | `docs/test-plan.md@132` | Lệnh pytest sai sau cd e2e_test | Đã sửa | Dùng test_*.py tương đối; run_suite.ps1 không hỗ trợ -Rounds/-OutputFile nên bỏ tham số sai. |
| #3–#6 | `docs/test-plan.md@5` | Diễn đạt ARTEMIS như kết quả đã chạy | Đã sửa | Ghi rõ kế hoạch chưa chạy, manual/skip và kết quả mong đợi mới. Giữ bảng Chưa chạy và TODO. |
| #3–#6 | `docs/test-plan.md@221` | Danh sách ảnh FCM sai tên | Đã sửa | Đối chiếu 6 file JPG thật trong evidence/lab3/06-firebase-console/. |
| #3–#6 | `docs/design-traceability.md@4` | Mã Flutter và ARTEMIS trùng TC | Đã sửa | FT-xx là alias tài liệu cho nhãn TC cũ trong Flutter; TC-xx dành suite ARTEMIS mới; ART-xx giữ mã runner adb lịch sử để không đổi nghĩa các liên kết cũ. |
| #3–#6 | `docs/design-traceability.md@47` | Khẳng định kiểm bằng DebugView | Đã sửa | Thay bằng logcat FA-SVC + Events GA4; README/report ghi log được nhắc nhưng chưa có trong checkout. |
| #3–#6 | `docs/analytics-plan.md@36` | Sai kiểu within_tolerance/has_attachment | Đã sửa | AnalyticsEvent.sanitize trong session_models.dart chuyển bool thành chuỗi true/false; tài liệu ghi kiểu sau sanitize. |
| #3–#6 | `docs/architecture.md@240` | Sequence chờ Firestore khi lưu tự luyện | Đã sửa | View gọi add không await; VM cập nhật bộ nhớ rồi lưu. Sơ đồ dùng mũi tên bất đồng bộ và chú thích UI không chờ xác nhận. |
| #3–#6 | `docs/architecture.md@281` | Sai id tài liệu device | Đã sửa | Id là 32 ký tự đầu SHA-256 token; token nằm trong field token. |
| #3–#6 | `docs/architecture.md@52` | Mock dùng cho E2E | Đã sửa | AppServices.mock() dùng unit/widget Flutter; ARTEMIS dùng Firebase thật. |
| #3–#6 | `docs/mobile-backend-api-gaps.md@5` | Khẳng định đã bỏ toàn bộ Gateway | Đã sửa | AppServices.firebase() mặc định firestore, vẫn chọn Gateway cho công thức qua RECIPE_SOURCE=gateway; phần lịch sử được ghi rõ. |
| #3–#6 | `README.md@38` | Thiếu SHA-1, client id, nguồn vai trò | Đã sửa | Thêm signingReport cho debug/release, placeholder Web client ID đầy đủ; mô tả claim role và fallback users/{uid}.role đúng FirebaseUserProfileService/AuthViewModel. |
| #3–#6 | `README.md@9` | Deliverable và kiểm tra đã/chưa làm | Đã sửa | Test-plan/report/slides và docs/code-review.md đã có (19 phát hiện, 15 đã sửa); report/slides đã xuất PDF; slides hiện là slides/Lab03_SE183201_slides.pptx + .pdf, bản HTML đã bỏ. ARTEMIS chưa chạy; log Analytics chưa có trong checkout. |
| #3–#6 | `report/Lab03_SE183201.md@268` | Suy hành vi người dùng từ Analytics kiểm thử | Đã sửa | Phần caveat đã có từ trước; bỏ các suy luận về flow, đối chiếu crash từng event và hành vi tại quầy còn sót. |
| #3–#6 | `slides/Lab03_SE183201_slides.html@618` | Nhãn login/logout suy tỷ lệ thoát ca | Đã sửa | Đổi sang dữ liệu kiểm thử; đồng bộ các nhãn thống kê khác, nêu không suy hành vi tại quầy. |
| #3–#6 | `report/Lab03_SE183201.md@375` | Khẳng định mọi thay đổi đã kiểm đầy đủ | Đã sửa | Giới hạn theo ảnh/bằng chứng có trong checkout; Flutter chưa xác nhận lại, ARTEMIS giữ TODO. Report/slides đã xuất PDF; slide nguồn hiện là PPTX. |
| #7 | `docs/coderabbit-followup.md` | Trạng thái deliverable lỗi thời | Đã sửa | Đối chiếu docs/code-review.md: 19 phát hiện, 15 đã sửa; có report PDF và slides PPTX/PDF, không còn slide HTML. Cập nhật cả ghi chú PDF còn sót. |
| #7 | `docs/test-plan.md@45` | TC-11 thiếu tìm Latte Đá trước khi mở thẻ | Đã sửa | Thêm bước tìm ở Tra cứu, khớp test_detail.py. |
| #7 | `docs/test-plan.md@49`, `e2e_test/test_practice_export.py` | TC-15 thiếu chọn tab Chưa học | Đã sửa | MyLearningPage mặc định tab Đang học; thêm chọn Chưa học trước chọn nhiệm vụ trong cả tài liệu và script. |
| #7 | `e2e_test/conftest.py`, `e2e_test/README.md` | Giới hạn ký tự mật khẩu ADB_LOGIN=1 chưa rõ | Đã sửa | Ghi ASCII in được trừ %, từ chối Unicode/control/% trước khi xóa app hoặc nhập credential; fail không chứa mật khẩu. |
| #7 | `e2e_test/test_auth.py` | TC-24 lỗi finally che lỗi chính | Đã sửa | Giữ lỗi thân test; nếu phục hồi cũng lỗi thì báo cả hai bằng BaseExceptionGroup, gồm cả pytest.fail. |
| #7 | `e2e_test/test_profile_remote_config.py` | TC-21 mất baseline khi khôi phục timeout | Đã sửa | Lưu giá trị gốc qua RUN_ID/process, chỉ xóa sau xác nhận restore; vòng sau restore trước baseline mới. Chấp nhận gốc 1 hoặc 2; giữ RH_RC_OPERATOR=1. |
| #7 | `tools/video/make_videos.py` | Nhãn duration khác thời lượng hiệu lực | Đã sửa | Chip dùng total được build truyền từ step_duration, kể cả fallback 10 giây khi thiếu/không dương. |
| #7 | `slides/Lab03_SE183201_slides.html` | Review slide HTML cũ | Bỏ qua: file đã thay thế | HTML không còn; đã thay bằng slides/Lab03_SE183201_slides.pptx và .pdf. |
| #7 | Không xác định | Phát hiện còn lại bị cắt khỏi tóm tắt | Không đủ thông tin | Tìm trong repo chỉ thấy review PR #2 và bảng follow-up trước; không có comment PR #7 đầy đủ để đối chiếu. Sandbox không mạng; không đoán nội dung. |

## Kiểm tra và việc còn lại của lượt PR #3–#6

- `git diff --check`: đạt. Kiểm tra offline bằng Node: 61 món; 63 câu quiz giữ tập đáp án, đáp án đúng, explanation/reviewSection sau shuffle; thứ tự SHA-256 ổn định khi chạy lại; đủ 24 mã E2E duy nhất. QZ-SUCTRA q9 là ngoại lệ nội dung được sửa theo SOP như bảng.
- Đã thêm `tools/test_review_helpers.py` (unittest chuẩn, không cần Pillow/ARTEMIS) cho wrap, duration, font, CLI, quoting ADB, biến rỗng và shuffle. Chưa chạy được: Python trên PATH là uv trampoline báo permission denied; Python của venv cũng không khởi chạy được. Chưa có bằng chứng RED/GREEN runtime.
- `tools/seed/shuffle_quizzes.py` đã viết nhưng chưa thực thi được bằng Python. File seed được tạo bằng cùng thuật toán SHA-256 trong Node và kiểm tra bảo toàn dữ liệu; cần chạy lại `python tools/seed/shuffle_quizzes.py` và unittest khi có Python khả dụng. Đây chưa phải xác nhận runtime của script Python.
- Đã thử `flutter analyze --no-pub` và `flutter test --no-pub`; không có output/kết quả, đã dừng tiến trình. Checkout chưa có `.dart_tool`; không chạy pub get theo yêu cầu. Không khẳng định analyze 0 issue hoặc test pass cho lượt này.
- ARTEMIS/ADB/Firebase không chạy trong sandbox offline. TC-04 manual/skip vì thiếu UI; TC-09 manual/skip vì mở app sau pm clear offline mất Auth. Cần giải quyết setup Auth không có cache trước khi kiểm tải/retry thật.
- Report/slides đã xuất PDF; slide nguồn hiện là `slides/Lab03_SE183201_slides.pptx` và PDF tương ứng, bản HTML đã bỏ. Lượt PR #7 chỉ kiểm sự tồn tại của artifact, không xác nhận lại render/nội dung PDF. TODO kết quả ARTEMIS được giữ nguyên.

## Kiểm tra lượt PR #7 (09/11/2026)

- `git diff --check`: đạt.
- Bổ sung regression test vào `tools/test_review_helpers.py`: credential ADB bị từ chối trước khi xóa app; TC-24 giữ cả hai lỗi (bao gồm pytest.fail); TC-21 giữ baseline qua timeout/vòng sau và chỉ ghi baseline mới sau restore, với giá trị gốc 1, 2, 20; nhãn duration dùng thời lượng hiệu lực. Dữ liệu giả chỉ ở test.
- Đã thử `python -m unittest discover -s tools -p test_review_helpers.py` và `python -m py_compile` cho 6 file Python đã sửa: không chạy được vì `python` không có trên PATH; thử interpreter của venv cũng báo `uv trampoline failed to spawn Python child process: permission denied (os error 5)`. Chưa có bằng chứng RED/GREEN hoặc coverage runtime; chỉ rà soát code offline.
- Đã thử `flutter analyze --no-pub` và `flutter test --no-pub`: không ra kết quả, đã dừng tiến trình. Chạy lại cả hai qua Flutter snapshot có sẵn báo không thể đọc/ghi `C:\Users\nguyen.son\AppData\Roaming\.flutter_tool_state` ngoài workspace. Chưa xác nhận analyze 0 issue/test pass; không tải dependency hoặc dùng mạng.
- Chưa chạy ARTEMIS/ADB/Firebase hay publish Remote Config. Không commit/push.
