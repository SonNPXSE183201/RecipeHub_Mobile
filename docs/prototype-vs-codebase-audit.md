# Báo cáo Đối chiếu Tính năng & Giao diện: Prototype vs Flutter Codebase
**RecipeHub Mobile – PRM393**  
*Cập nhật: 12/11/2026*  
*Tài liệu dành cho Developer & AI Agent để tra cứu và rà soát nhanh tính năng hệ thống.*

---

## 1. Nguồn dữ liệu & Phạm vi đối chiếu

Báo cáo này phân tích và đối chiếu chéo giữa 3 nguồn sự thật trong dự án:
1. **Bản mẫu UX Reference Prototype** (React / Tailwind / Lovable):  
   Thư mục: [`docs/4943d36c-2283-4a4a-8e2e-d8538c5696c8/`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/docs/4943d36c-2283-4a4a-8e2e-d8538c5696c8)  
   *(Bản mẫu thiết kế tương tác giao diện, mockup dữ liệu in-memory, mô phỏng network test và ebooklet).*
2. **Tài liệu kiểm kê & truy vết thiết kế**:  
   - [`docs/feature-inventory.md`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/docs/feature-inventory.md) *(Kiểm kê 11 module, 23 page, Firestore & Storage rules).*  
   - [`docs/design-traceability.md`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/docs/design-traceability.md) *(Các điểm lệch thiết kế có chủ đích đã được chủ dự án phê duyệt).*
3. **Mã nguồn ứng dụng Flutter thực tế**:  
   Thư mục: [`lib/features/`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/features) & [`lib/core/`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/core)  
   *(Triển khai production: Flutter MVVM + Provider + Cloud Firestore real-time).*

---

## 2. Bảng ma trận đối chiếu từng màn hình & Nút bấm

Ký hiệu trạng thái:
- ✅ **Đầy đủ / Vượt trội**: Flutter đã có và tích hợp backend/cloud thật vượt trội hơn prototype.
- ℹ️ **Điều chỉnh có chủ đích**: Đã được ghi nhận trong `design-traceability.md` theo yêu cầu chủ dự án.
- ⚠️ **Điểm khuyết (UI Gap)**: Prototype có nút/hành vi UI nhưng Flutter codebase chưa hiện thực hoặc chưa kết nối.

| # | Màn hình | Tính năng / Nút bấm trên Prototype (`4943d...`) | Hiện trạng trên Flutter Codebase (`lib/`) | Trạng thái | Ghi chú kỹ thuật & File liên quan |
| :-: | :--- | :--- | :--- | :-: | :--- |
| **1** | **Tra cứu món**<br>`features/lookup/` | • Ô tìm kiếm từ khóa real-time<br>• Sub-tab chuyển `Công thức` / `SOP`<br>• Nút Bookmark trên từng card món<br>• Bộ lọc ngang: `Tất cả`, `Cà phê`, ..., `Đã lưu`<br>• 2 Banner lớn vào `Sổ tay SOP` & `Mục lục PDF`<br>• Nút xóa từ khóa & Empty state | • Ô tìm kiếm debounce 400ms + server search<br>• Chỉ hiển thị công thức đồ uống<br>• Chưa có nút Bookmark trên card<br>• Lọc theo danh mục Firestore: `Tất cả`, `Cà phê`...<br>• Không có banner SOP trên Tra cứu<br>• Empty state hình vẽ chuẩn `NomadKit` | ℹ️ Sub-tab SOP bỏ có chủ đích (DT-4)<br>⚠️ **Khuyết nút Bookmark**<br>⚠️ **Khuyết tab lọc Đã lưu**<br>ℹ️ Banner SOP chuyển vào Tài khoản | `lib/features/lookup/counter_recipe_lookup_page.dart`<br>DT-4: SOP chuyển vào Sổ tay trong Tài khoản để màn quầy bar tối ưu danh sách món. |
| **2** | **Chi tiết món**<br>`features/lookup/` | • Chọn quy cách: Mặc định cố định 1 ly<br>• Nút Bookmark ở thanh hành động<br>• Nút Góp ý ở từng bước (`step-feedback`)<br>• Nút vào Tự luyện món này<br>• Nút mở SOP liên quan<br>• Không có video (chỉ text ghi chú) | • Chọn size động: `S`, `M`, `L` đổi định lượng tức thì<br>• Chưa có nút Bookmark chi tiết<br>• Nút Góp ý nằm ở `AppBar` (chung cho món)<br>• Nút Tự luyện ở bottom bar & FAB<br>• Nút mở SOP liên quan ở cuối màn<br>• **Video streaming thật** từ Cloud Storage + đồng bộ mốc thời gian từng bước | ✅ Hỗ trợ đa size S/M/L<br>⚠️ **Khuyết nút góp ý ở từng bước**<br>✅ Video hướng dẫn vượt trội | `lib/features/lookup/recipe_detail_size_page.dart`<br>`lib/features/lookup/step_video_guide_page.dart`<br>`CreateFeedbackPage` đã có sẵn tham số `initialStepNumber`, chỉ cần gắn nút. |
| **3** | **Sổ tay SOP**<br>`features/sop_book/` | • Thanh điều hướng capsule: Đọc tiếp, Mục lục, PDF, Tìm kiếm<br>• Giao diện lật trang Web paper<br>• Xuất file PDF client-side | • Lật trang sách 3D quanh gáy trái<br>• Nút Tìm kiếm qua bottom sheet modal<br>• Xuất PDF toàn bộ sổ tay lưu về `Download/RecipeHub`<br>• Lưu vị trí trang đang đọc vào SharedPreferences | ✅ **Đầy đủ & Vượt trội** | `lib/features/sop_book/sop_book_page.dart`<br>`lib/features/sop_book/sop_book_views.dart`<br>`lib/core/services/report/sop_book_pdf.dart` |
| **4** | **Việc học (Barista)**<br>`features/learning/` | • Khối tiến độ: 3 stage (Đọc món, Quiz, Tự luyện)<br>• Khối "Tự luyện" trực tiếp trên màn hình<br>• Danh sách kết quả tự luyện gần nhất<br>• Nút xem SOP đã học | • 3 Tab phân loại Task: `Chưa học`, `Đang học`, `Hoàn thành`<br>• Nút nhanh `Làm bài Quiz`<br>• Nút nhanh `Kết quả thực hành`<br>• Nút icon `Tiến độ cá nhân`<br>• Tự luyện tách ra FAB và màn riêng | ℹ️ **Bố cục khác biệt**: Codebase quản lý task học việc đa dạng từ Firestore `learningTasks`. Lịch sử tự luyện xem tại `PracticeHistoryPage`. | `lib/features/learning/my_learning_page.dart`<br>`lib/features/learning/personal_progress_page.dart`<br>`lib/features/practice/practice_history_page.dart` |
| **5** | **Tự luyện & Bấm giờ**<br>`features/practice/` | • Chọn món (DataPicker bottom sheet)<br>• Bấm giờ Start / Pause / Finish / Reset<br>• Nhập ghi chú sau khi kết thúc<br>• Không có AI hỗ trợ | • Chọn món có tìm kiếm không dấu<br>• Đồng hồ bấm giờ chuẩn dung sai $\pm 5$s<br>• **Tích hợp Firebase AI Logic / Gemini Recall**: Tự động đặt câu hỏi ôn nguyên liệu/SOP trong lúc luyện<br>• Lưu Firestore `users/{uid}/practiceRecords` | ✅ **Vượt trội**: Có tính năng AI hỏi ôn tập thông minh (Gemini 3.5 Flash-Lite). | `lib/features/practice/self_practice_timer_page.dart`<br>`lib/core/services/ai/recipe_recall_builder.dart`<br>`lib/core/viewmodels/ai_practice_viewmodel.dart` |
| **6** | **Làm Quiz**<br>`features/practice/` | • 3 câu hỏi minh họa in-memory<br>• Chọn đáp án, hiển thị giải thích sau nộp | • Danh sách câu hỏi tải từ Firestore `quizzes`<br>• Quy tắc bảo mật: Client chỉ đọc `answerKey` sau khi đã nộp lần đầu<br>• Lưu kết quả bất biến vào `quizAttempts` | ✅ **Đầy đủ & Bảo mật** | `lib/features/practice/quiz_exam_page.dart`<br>`lib/core/viewmodels/training_viewmodel.dart` |
| **7** | **Đánh giá thực hành**<br>`features/practice/` | • Chọn Đạt / Cần luyện lại<br>• Checklist 3 tiêu chí mẫu cố định<br>• Nhập nhận xét tổng quan | • Checklist tiêu chí theo từng món tải từ Firestore `evaluationCriteria`<br>• Phân biệt tiêu chí trọng yếu<br>• Admin chấm và lưu bất biến vào `evaluations`; Barista xem kết quả cá nhân | ✅ **Đầy đủ & Nghiệp vụ chuẩn** | `lib/features/practice/practical_evaluation_page.dart`<br>`lib/features/admin_training/admin_store_training_page.dart` |
| **8** | **Đào tạo chi nhánh**<br>`admin_training/` | • Dải tóm tắt: Chờ chấm / Đã đánh giá<br>• Danh sách nhân viên và nút Chấm | • Quản lý nhân viên thật từ `users` (role viewer)<br>• Tỷ lệ đọc SOP, nhiệm vụ trễ hạn<br>• Mở form đánh giá tay nghề tại quầy | ✅ **Đầy đủ & Real-time** | `lib/features/admin_training/admin_store_training_page.dart`<br>`lib/core/viewmodels/training_viewmodel.dart` |
| **9** | **Phản hồi**<br>`features/feedback/` | • Danh sách phản hồi<br>• Tạo phản hồi có đính kèm ảnh (DataURL)<br>• Dòng giữ bản nháp: `Tiếp tục phản hồi đang viết`<br>• Admin nhập nội dung xử lý và đổi trạng thái | • Danh sách real-time Firestore `feedback`<br>• Tạo phản hồi đính kèm ảnh tải lên Firebase Storage (`feedback/{uid}/`)<br>• Hội thoại 2 chiều real-time (`replies`)<br>• 5 trạng thái: `newFeedback`, `inProgress`, `waitingInfo`, `resolved`, `closed` | ⚠️ **Khuyết cơ chế lưu Draft** khi thoát form giữa chừng.<br>✅ Luồng trao đổi và upload Storage vượt trội. | `lib/features/feedback/my_feedback_list_page.dart`<br>`lib/features/feedback/create_feedback_page.dart`<br>`lib/features/feedback/feedback_detail_page.dart` |
| **10**| **Tài khoản & Hệ thống**<br>`features/account/` | • Đổi role thử nghiệm (Barista / Quản lý)<br>• Màn hình Settings: Chữ lớn 200%, Giảm chuyển động, nút test Network (Online/Weak/Offline) | • Hồ sơ thật + Role bảo mật từ Custom Claim `role`<br>• Nút Admin xem dưới góc nhìn Barista<br>• Đổi mật khẩu tài khoản Email/Password<br>• Khu vực kiểm thử sự cố (Ghi non-fatal / Crash thật) gửi lên Firestore `incidents` & Crashlytics<br>• Đăng xuất an toàn (dọn FCM token) | ℹ️ Các nút test network/chữ lớn của Prototype chỉ phục vụ kiểm thử web mockup.<br>✅ Flutter có Crash demo & Quản lý claim chuẩn. | `lib/features/account/account_profile_page.dart`<br>`lib/features/account/change_password_page.dart`<br>`lib/core/bootstrap/firebase_bootstrap.dart` |

---

## 3. Danh sách các điểm khuyết giao diện (Actionable UI Gaps)

Dành cho AI Agent hoặc Developer muốn triển khai bổ sung để đồng bộ hoàn toàn với bản mẫu UI Prototype:

### Gap 1: Nút Bookmark (Lưu món yêu thích) & Tab lọc "Đã lưu"
- **Mức độ:** Khuyến nghị (Cải thiện trải nghiệm thao tác tại quầy).
- **Vị trí cần thêm:**
  1. Thẻ món trong [`lib/features/lookup/counter_recipe_lookup_page.dart`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/features/lookup/counter_recipe_lookup_page.dart): Thêm một `IconButton(icon: Icon(Icons.bookmark_outline))` góc phải card.
  2. Dải chip lọc danh mục: Thêm chip `"Đã lưu"` cạnh `"Tất cả"`.
  3. Màn hình chi tiết [`lib/features/lookup/recipe_detail_size_page.dart`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/features/lookup/recipe_detail_size_page.dart): Thêm icon Bookmark trên AppBar.
- **Lưu trữ dữ liệu:** Lưu danh sách mã món yêu thích `List<String> favorites` vào `SharedPreferences` theo `uid`.

### Gap 2: Nút Góp ý trực tiếp tại từng bước pha chế (Step Feedback)
- **Mức độ:** Dễ triển khai (Code backend và ViewModel đã sẵn sàng).
- **Vị trí cần thêm:**
  Trong [`lib/features/lookup/recipe_detail_size_page.dart`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/features/lookup/recipe_detail_size_page.dart), tại mỗi bước pha chế `recipe.steps.map((st) {...})`:
  Thêm một `IconButton` nhỏ:
  ```dart
  IconButton(
    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: NomadKit.secondary),
    tooltip: 'Góp ý bước ${st.stepNumber}',
    onPressed: () => go(
      context,
      CreateFeedbackPage(
        initialRecipeCode: recipe.code,
        initialRecipeName: recipe.name,
        initialVersion: recipe.version,
        initialStepNumber: st.stepNumber,
        initialStepTitle: st.title,
      ),
    ),
  )
  ```
  *(Trang `CreateFeedbackPage` đã nhận sẵn `initialStepNumber` và `initialStepTitle`).*

### Gap 3: Cơ chế giữ bản nháp phản hồi (Draft Retention)
- **Mức độ:** Cải thiện độ tin cậy khi nhập liệu.
- **Vị trí cần thêm:**
  1. Trong [`lib/features/feedback/create_feedback_page.dart`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/features/feedback/create_feedback_page.dart): Lưu nội dung tiêu đề và vấn đề vào bộ nhớ tạm khi đang gõ.
  2. Trong [`lib/features/feedback/my_feedback_list_page.dart`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/features/feedback/my_feedback_list_page.dart): Nếu có draft chưa gửi, hiển thị banner nhỏ *"Tiếp tục phản hồi đang viết"* để người dùng mở lại ngay.

---

## 4. Hướng dẫn cho AI Agent khi thao tác trên Codebase

1. **Tuân thủ MVVM + Provider**:
   - Widget (`lib/features/*`) tuyệt đối không import hoặc gọi trực tiếp SDK Firebase.
   - Mọi logic nghiệp vụ, trạng thái dữ liệu phải đi qua ViewModel (`lib/core/viewmodels/*`) và Service Interface (`lib/core/services/interfaces/*`).
2. **Quy tắc Design Token (NomadKit)**:
   - Sử dụng màu sắc và kiểu chữ từ [`lib/core/theme/nomad_kit.dart`](file:///d:/03_Dev/01_Projects/01_MyProject/PRN232/Assignment/Project/RecipeHub_Mobile/lib/core/theme/nomad_kit.dart). Không viết cứng màu mã hex lạ hoặc cỡ chữ mới.
3. **Quy tắc UI**:
   - Ẩn hoàn toàn mã món kỹ thuật thô (`recipe.code`) trên giao diện di động; chỉ hiển thị tên món, nhóm món và quy cách phục vụ.
4. **Tiêu chuẩn kiểm thử trước khi báo xong**:
   - `flutter analyze` đạt 0 issue.
   - `flutter test` vượt qua toàn bộ các ca kiểm thử.
