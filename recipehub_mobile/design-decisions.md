# RecipeHub Mobile — Quyết Định Thiết Kế & Báo Cáo Đánh Giá UI/UX (Design Decisions)

Tài liệu này ghi lại các quyết định thiết kế quan trọng (Accept, Modify, Reject) trong quá trình phát triển hệ thống **RecipeHub Mobile**, đối chiếu với 10 nguyên lý Nielsen Heuristics, các tiêu chuẩn tiếp cận WCAG 2.1 AA và nguyên tắc thiết kế **NomadKit**.

🔗 **Figma Design URL**: [https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0](https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0) (Key: `FycUpbP0PtH6Q4sg6IvZr6`)

---

## 1. Bảng Tổng Hợp 9 Quyết Định Thiết Kế Cốt Lõi

| Quyết định | Loại | Đề xuất ban đầu (AI / Khảo sát) | Quyết định thực tế của nhóm | Căn cứ lý giải (Persona / Heuristic / Ràng buộc) |
| :--- | :--- | :--- | :--- | :--- |
| **DEC-01** | **MODIFY** | Dùng hệ màu tối huyền bí NoirLuxe (`#0C0C0E` / `#C9A84C`) cho toàn bộ ứng dụng | **Chuyển sang NomadKit Canvas**: Nền kem ấm (`#FFFDF7`), thẻ trắng (`#FFFFFF`), điểm nhấn Vàng cát (`#D4A373`) và Xanh đại dương (`#0891B2`). | **Bối cảnh quầy bar**: Quầy pha chế nhiều ánh sáng tự nhiên và đèn quầy; màn hình tối đen dễ bị chói và lóa nước. Màu NomadKit dịu mắt, dễ đọc hơn khi di chuyển liên tục. |
| **DEC-02** | **REJECT** | Dùng biểu tượng cảm xúc (Emoji) trong danh mục nguyên liệu (🍵, 🥛, 🍊...) | **Bác bỏ hoàn toàn Emoji, thay bằng Icon Vector line tối giản, chuẩn mực** (Material & Phosphor/Lucide). | **Chuyên nghiệp & Bền vững**: Emoji hiển thị không đồng nhất trên các hãng điện thoại Android/iOS khác nhau, tạo cảm giác thiếu chuyên nghiệp cho phần mềm R&D chuẩn chuỗi F&B. |
| **DEC-03** | **MODIFY** | Cho phép sửa trực tiếp công thức bất kỳ lúc nào để tiện lợi | **Khóa cứng bản đã chốt (Immutability)**; muốn sửa phải bấm *"Tạo bản sửa đổi (Create Revision)"* để sinh v2. | **Nielsen #5 (Ngăn ngừa lỗi)**: Tránh tuyệt đối rủi ro vô tình chạm màn hình làm đổi định lượng món đang phục vụ tại 45 chi nhánh. |
| **DEC-04** | **REJECT** | AI tự động cập nhật công thức và tự đổi định lượng khi chuyên viên bấm "Tối ưu hóa" | **AI chỉ đóng vai trò trợ lý đề xuất (Human-in-the-loop)**; hiển thị Dialog cho người dùng bấm "Chấp nhận" hoặc "Từ chối". | **Nielsen #3 (Quyền tự do và kiểm soát)**: Chuyên viên R&D chịu trách nhiệm pháp lý và hương vị sản phẩm, AI không được phép ghi đè tự động. |
| **DEC-05** | **ACCEPT** | Gom nhiều công thức vào **một tài liệu PDF duy nhất** thay vì xuất từng file rời rạc | **Tích hợp màn hình Chọn nhiều công thức kèm Trang bìa (Cover) và Mục lục (TOC)** trang trọng. | **Nhu cầu đào tạo SOP**: Cửa hàng cần một cuốn cẩm nang pha chế hoàn chỉnh đóng tập để in hoặc lưu trữ, không thể tải hàng chục file PDF rời rạc. |
| **DEC-06** | **ACCEPT** | Bắt buộc có màn hình Loading chuyển cảnh và màn hình Error phục hồi trong prototype | **Thiết kế màn hình Loading 1.5s với hiệu ứng cát ấm và màn hình Error lưu giữ bản nháp an toàn**. | **Nielsen #1 (Hiển thị trạng thái hệ thống) & Nielsen #9 (Giúp nhận biết và phục hồi lỗi)**: Người dùng luôn biết hệ thống đang xử lý và không sợ mất dữ liệu khi rớt mạng. |
| **DEC-07** | **ACCEPT** | Chuyển đổi từ các khối phím tắt dev thô sơ sang **Kiến trúc 3 Phân Hệ Vận Hành Chuỗi (3-Role Architecture)** với **Thanh chọn vai trò chuẩn Production UI** | **Chia rõ 3 phân hệ độc lập**: Phân hệ 1 cho Nhân viên R&D (Staff Flow), Phân hệ 2 cho Barista chi nhánh (Viewer Flow) và Phân hệ 3 cho Quản trị viên (Admin Flow); loại bỏ 100% card phím tắt dev, log BE và thanh trạng thái giả lập iOS. | **Trải nghiệm Production sạch sẽ & Phân định trách nhiệm**: Bảo đảm giao diện người dùng đạt chuẩn xuất xưởng cao cấp (Figma), đồng thời vẫn giữ trọn vẹn dữ liệu mock phong phú và phân định đúng không gian làm việc của từng vai trò. |
| **DEC-08** | **ACCEPT** | Thiết kế giao diện đọc **Sách SOP Điện Tử Lật Trang Tương Tác (`BookletReaderPage`)** | **Mô phỏng chân thực trải nghiệm sách giấy**: Đổ bóng gáy sách 3D (`spine shadow gradient`), thanh trượt trang mượt mà, Drawer mục lục TOC nhảy trang tức thì, và Watermark "BẢN NHÁP" in chéo 45 độ trên các trang chưa duyệt. | **Nielsen #2 (Tương đồng thế giới thực)**: Thay vì đọc file PDF phẳng nhàm chán, Barista được lướt qua từng trang sổ tay đào tạo như cầm trên tay cuốn cẩm nang quầy bar thực thụ. |
| **DEC-09** | **ACCEPT** | Xây dựng quy trình **Trích xuất giao diện nút bấm mobile lên Figma và Demo Native Mobile** (Không dùng Web) | **Chuẩn hóa quy trình 4 bước**: Chụp ảnh độ phân giải cao từ Android Emulator Pixel 5 qua ADB, đặt vào khung Mobile 412×915dp trên Figma, gắn liên kết Hotspot tương tác và chạy trình diễn bằng Figma Mirror / Máy ảo Android thực tế. | **Tính xác thực di động**: Đảm bảo toàn bộ tỷ lệ vùng chạm (Touch Target >= 52dp), viền bo 16dp và logo tách hạt hiển thị chuẩn xác 100% trên thiết bị cầm tay. |

---

## 2. Đánh Giá Theo 10 Nguyên Lý Khả Dụng Của Jakob Nielsen

| # | Nguyên lý Heuristic | Cách RecipeHub Mobile giải quyết thực tế |
| :--- | :--- | :--- |
| **1** | **Hiển thị trạng thái hệ thống (Visibility of system status)** | Trạng thái công thức luôn hiển thị rõ ràng bằng Status Chip kèm icon + nhãn chữ: `[Draft · Vàng]` hoặc `[Approved · Xanh lá]`. Màn hình Loading xuất hiện tức thì khi bấm tạo PDF; kiểm tra API AI có phản hồi Live Ping 138ms. |
| **2** | **Tương đồng giữa hệ thống và thế giới thực (Match real world)** | Sử dụng thuật ngữ quầy bar chuẩn: Định lượng (g, ml), Mẻ pha, Bản nháp, Chốt công thức, SOP Book. Giao diện `BookletReaderPage` mô phỏng gáy sách 3D và các trang sổ tay vật lý. |
| **3** | **Quyền kiểm soát và tự do cho người dùng (User control & freedom)** | Mọi màn hình con đều có nút Back rõ ràng không làm mất dữ liệu đã nhập. Khi AI đề xuất luôn có nút "Không phải lúc này (Not now)" để hủy bỏ. Sách SOP có Drawer mục lục TOC cho phép nhảy ngay đến trang mong muốn. |
| **4** | **Nhất quán và tuân thủ tiêu chuẩn (Consistency & standards)** | Toàn bộ ứng dụng sử dụng chung Design Token NomadKit: bo góc 14-16dp cho thẻ, 52dp cho nút bấm, logo hạt cà phê trong khung squircle vàng cát đồng bộ từ Đăng nhập, Trang chủ đến Bảng điều khiển Admin. |
| **5** | **Ngăn ngừa lỗi (Error prevention)** | Khóa sửa bản đã chốt; cảnh báo ngay khi định lượng <= 0 hoặc khi nguyên liệu cấu thành đã bị ngừng sử dụng; kiểm tra bắt buộc phải có ít nhất 1 thành phần và 1 bước mới cho duyệt. |
| **6** | **Nhận biết thay vì nhớ lại (Recognition rather than recall)** | Khi tạo công thức, danh mục nguyên liệu hiển thị sẵn kèm đơn vị mặc định; các bước pha chế có checklist trực quan giúp chuyên viên không phải nhớ bước tiếp theo. |
| **7** | **Linh hoạt và hiệu quả sử dụng (Flexibility & efficiency)** | Hỗ trợ tìm kiếm nhanh, lọc theo danh mục món, thanh trượt trang (scrubber) trong Sách SOP giúp lật 8 trang chỉ trong 1 giây. |
| **8** | **Thẩm mỹ tối giản, tập trung (Aesthetic & minimalist design)** | Không nhồi nhét thông tin; mỗi màn hình có cấu trúc phân tầng rõ ràng; khoảng trắng thoáng đãng, loại bỏ mọi emoji gây rối mắt. |
| **9** | **Giúp nhận biết, chẩn đoán và khắc phục lỗi (Help recognize & recover errors)** | Thông báo lỗi cụ thể (ví dụ: *"Mức tồn kho tối thiểu không được lớn hơn số lượng hiện có"* thay vì *"Lỗi không hợp lệ"*); màn hình lỗi kết nối giữ nguyên dữ liệu nháp và có nút Thử lại (Retry). |
| **10** | **Trợ giúp và tài liệu hướng dẫn (Help & documentation)** | Cung cấp chế độ Barista Viewer riêng cho nhân viên quầy bar; các bước pha chế có ghi chú an toàn (Safety Note) và dấu hiệu nhận biết khi món đạt chuẩn. |

---

## 3. Báo Cáo Đo Kiểm Tiếp Cận (Accessibility & Responsive Audit)

### 3.1. Độ tương phản màu sắc (Contrast Ratio - WCAG 2.1 AA)
* **Chữ chính (`#292524`) trên Nền kem (`#FFFDF7`)**: Đạt **12.8 : 1** (Vượt xa chuẩn yêu cầu 4.5:1).
* **Nút bấm Vàng cát (`#D4A373`) với Chữ than đá (`#292524`)**: Đạt **5.1 : 1** (Đạt chuẩn WCAG AA cho nút bấm điều khiển).
* **Nhãn trạng thái Xanh rừng (`#166534`) trên Nền trắng**: Đạt **7.4 : 1** (Đạt chuẩn WCAG AAA).
* **Cảnh báo Lỗi (`#DC2626`) trên Nền trắng**: Đạt **4.6 : 1** (Đạt chuẩn WCAG AA).

### 3.2. Kích thước vùng chạm (Touch Target Size)
* Tất cả nút hành động chính (`PrimaryButton`, `SecondaryButton`, `PingTestButton`) có chiều cao tối thiểu **52 dp** (vượt chuẩn 48×48 dp).
* Các icon điều hướng trên AppBar và NavigationBar có padding vùng chạm mở rộng đạt **48×48 dp**, tối ưu khi tay bị ướt hoặc thao tác một tay tại quầy pha chế.

### 3.3. Kích thước phông chữ & Khả năng phóng to (Typography & Text Scaling)
* Cỡ chữ nội dung (`bodyLarge`, `bodyMedium`) được đặt từ **14 sp đến 15 sp**, không bao giờ nhỏ hơn 14 sp. Chữ hướng dẫn quầy bar trong chế độ Viewer đạt **18–22 sp**.
* Hỗ trợ Dynamic Type / Android Font Scaling từ **100% đến 200%** mà không bị tràn viền hoặc cắt chữ nhờ sử dụng Auto Layout và `Flexible`/`Expanded` widget trong Flutter.

### 3.4. Kiểm tra đáp ứng trên kích thước màn hình 360 dp và 412 dp
* **Chiều rộng 360 dp (Thiết bị nhỏ)**: Bố cục tự động co gọn theo 1 cột duy nhất, lề ngang 16 dp, nút CTA ghim cố định ở đáy màn hình không bị che lấp.
* **Chiều rộng 412 dp (Thiết bị tiêu chuẩn Pixel 5 - 1080×2340 px)**: Tăng khoảng thở giữa các thẻ lên 12–16 dp, lề ngang mở rộng lên 20 dp, giữ nguyên thứ bậc thị giác và thứ tự thao tác.
