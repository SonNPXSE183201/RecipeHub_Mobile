# RecipeHub Mobile — Persona & Nghiên Cứu Người Dùng (3 Phân Hệ Vai Trò)

Tài liệu này xác lập chân dung người dùng (User Personas), bối cảnh thực tế trong quầy R&D, các điểm đau (Pain Points), phát biểu vấn đề (Problem Statement) và tiêu chí thành công đo lường được cho ứng dụng **RecipeHub Mobile**, tuân thủ 100% tài liệu **SRS Phạm vi nhỏ (v0.1)** và đồng bộ hoàn toàn với bản thiết kế Figma:
🔗 **Figma Design URL**: [https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0](https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0) (Key: `FycUpbP0PtH6Q4sg6IvZr6`)

---

## Kiến Trúc 3 Hàng / 3 Luồng Thao Tác (3-Row Flow Architecture)

Hệ thống RecipeHub Mobile được cấu trúc phân chia trực quan thành **3 hàng điều hướng** tương ứng với 3 phân hệ vai trò cốt lõi:
1. **Hàng 1 — Nhân viên R&D (Staff Flow)**: Chuyên viên sáng tạo công thức, khai báo nguyên liệu, kiểm soát AI và xuất bản bộ Sổ tay SOP PDF hoàn chỉnh.
2. **Hàng 2 — Nhân viên Quầy bar (Viewer Flow)**: Barista tại chi nhánh tra cứu nhanh món, thực hiện pha chế theo danh sách kiểm tra (checklist) và đọc Sách SOP lật trang tương tác (`BookletReaderPage`).
3. **Hàng 3 — Quản trị & Vận hành (Admin Flow)**: Quản trị viên phân quyền tài khoản 45 chi nhánh (`AdminUserManagementPage`), cấu hình tham số AI Gemini kèm kiểm tra kết nối Live Ping (`AdminAiConfigPage`) và giám sát Nhật ký kiểm toán bất biến SHA-256 (`AdminAuditLogsPage`).

---

## 1. Hàng 1: Persona Chuyên Viên R&D (Primary Persona — R&D Specialist)

| Thuộc tính | Chi tiết |
| :--- | :--- |
| **Họ và tên** | **Trần Thùy Linh** / **Minh Anh** (28 tuổi) |
| **Vai trò** | Chuyên viên Nghiên cứu & Phát triển Đồ uống (Beverage R&D Lead) |
| **Tổ chức** | Chuỗi cà phê & trà sữa Nomad Coffee & Tea (45 chi nhánh) |
| **Nơi làm việc** | Bếp thử nghiệm trung tâm (R&D Test Kitchen) |
| **Môi trường sử dụng** | Quầy pha chế thử nghiệm: Không gian bận rộn, tiếng máy xay và máy đánh bọt ồn ào, tay thường xuyên dính nước hoặc nguyên liệu siro/bột, một tay cầm điện thoại, một tay thao tác với cân tiểu ly và ca đong. |
| **Thiết bị** | Smartphone Android màn hình 6.5 inch (độ phân giải thử nghiệm chuẩn 360–412 dp), thường xuyên thao tác bằng một tay (One-handed Thumb Zone). |

### Mục tiêu cốt lõi (User Goals)
1. **Lưu trữ công thức chính xác & nhanh chóng**: Khai báo danh mục nguyên liệu, định lượng chuẩn từng gram (g) hoặc milliliter (ml) và các bước pha chế có thứ tự ngay trong lúc thử nghiệm món mới.
2. **Quản lý phiên bản an toàn & Khóa bất biến (Immutability)**: Phân biệt rành mạch giữa bản nháp (Draft) và bản chính thức đã chốt (Approved). Tuyệt đối không cho phép sửa trực tiếp bản đã chốt để tránh làm sai lệch hương vị đang phục vụ tại 45 chi nhánh; khi muốn đổi bắt buộc phải tạo bản sửa đổi (v2, v3).
3. **Ứng dụng AI có kiểm soát (Human-in-the-loop AI)**: Nhờ trợ lý Gemini AI gợi ý câu chữ hướng dẫn hoặc vẽ ảnh minh họa, nhưng Linh phải là người toàn quyền bấm *"Chấp nhận"* hoặc *"Từ chối"*. Toàn bộ ảnh do AI sinh phải có nhãn *"Hình minh họa AI"*.
4. **Xuất 1 bộ sổ tay SOP hoàn chỉnh (Batch PDF Studio)**: Tích chọn nhiều công thức đã chốt để xuất thành **MỘT file PDF duy nhất** có Trang bìa và Mục lục chuẩn hóa gửi đến các chi nhánh đào tạo barista.
5. **Độ tin cậy ngoại tuyến (Offline Resilience)**: Lưu trữ bản nháp cục bộ trên máy, cho phép tiếp tục thử nghiệm và phục hồi dữ liệu khi mất kết nối mạng tại khu vực pha chế.

### Điểm đau thực tế (Pain Points)
* **Dữ liệu phân mảnh**: Công thức cũ lưu rải rác trên Google Sheets, nhóm chat Zalo, sổ tay viết tay dính bẩn.
* **Nguy cơ ghi đè chết người**: Vô tình chạm nhầm sửa vào công thức đang áp dụng toàn chuỗi, làm mất dấu lịch sử mẻ pha trước.
* **AI tự ý can thiệp**: Các công cụ AI tự động đổi định lượng nguyên liệu ngoài tầm kiểm soát của chuyên viên.
* **Xuất file thủ công mất thời gian**: Phải copy-paste từng món vào Word/Canva để làm PDF, mất 2–3 tiếng mỗi lần ra menu mới.

---

## 2. Hàng 2: Persona Trưởng Ca / Barista Quầy Bar (Viewer Flow — Store Barista)

| Thuộc tính | Chi tiết |
| :--- | :--- |
| **Họ và tên** | **Nguyễn Hoàng Tuấn** (23 tuổi) |
| **Vai trò** | Trưởng ca quầy bar / Barista (Lead Barista) tại Chi nhánh Landmark 81 |
| **Hình thức tiếp cận** | Truy cập màn hình **Trang Chủ Viewer (`ViewerHomePage`)** và mở **Sách Điện Tử SOP (`BookletReaderPage`)** trực tiếp trên mobile hoặc tablet tại quầy bar. |
| **Môi trường sử dụng** | Quầy bar giờ cao điểm: khách đông, ánh sáng đèn chiếu mạnh, cần tra cứu công thức cực nhanh trong vòng 5–10 giây. |
| **Nhu cầu** | - Tìm kiếm đồ uống nhanh theo tên món hoặc mã SKU.<br>- Đọc quy trình từng bước rõ ràng, chữ to dễ đọc (tối thiểu 14–18 sp).<br>- Tích chọn từng bước đã làm xong để không bị nhầm lẫn thứ tự nguyên liệu.<br>- Đọc trọn vẹn cuốn Sổ tay SOP tổng hợp dạng E-Book với hiệu ứng lật trang và gáy sách 3D trực quan. |
| **Điểm đau** | File giấy SOP quầy bar hay bị ướt rách, tìm món trong file PDF hàng chục trang rất lâu nếu không có mục lục thông minh. |

---

## 3. Hàng 3: Persona Giám Đốc Bếp & Vận Hành Chuỗi (Admin Flow — Operations Director)

| Thuộc tính | Chi tiết |
| :--- | :--- |
| **Họ và tên** | **Lê Hoàng Nam** / **Vũ Quang Minh** (35 tuổi) |
| **Vai trò** | Giám đốc Vận hành & Tiêu chuẩn Chuỗi (Operations & Kitchen Director) |
| **Hình thức tiếp cận** | Truy cập **Bảng Điều Khiển Admin (`AdminConsolePage`)** và 3 phân hệ quản trị chuyên sâu: Phân quyền tài khoản (`AdminUserManagementPage`), Cấu hình API AI (`AdminAiConfigPage`), và Nhật ký kiểm toán (`AdminAuditLogsPage`). |
| **Nhu cầu** | - Kiểm soát tài khoản nhân sự và phân quyền trên 45 chi nhánh.<br>- Quản lý khóa API Google AI Studio / Gemini, kiểm tra độ trễ mạng thực tế (Live Ping Test) và điều chỉnh nhiệt độ sáng tạo (Temperature).<br>- Truy vết trách nhiệm pháp lý và lịch sử chốt công thức, xuất bản PDF thông qua mã băm bất biến SHA-256. |
| **Điểm đau** | Không có bằng chứng đối soát khi chi nhánh pha chế sai công thức; thiếu cơ chế kiểm tra kết nối API AI trực tiếp trên thiết bị di động. |

---

## 4. Phát Biểu Vấn Đề (Problem Statement)

> **"Đội ngũ R&D và vận hành chuỗi Nomad Coffee & Tea cần một giải pháp mobile chuẩn hóa với 3 phân hệ luồng rõ ràng: Nhân viên R&D sáng tạo và chốt công thức bất biến không bị ghi đè, Nhân viên Barista tra cứu và đọc Sổ tay SOP dạng E-booklet trực quan, và Quản trị viên giám sát cấu hình AI cùng nhật ký kiểm toán SHA-256 toàn diện trên 45 chi nhánh."**

---

## 5. Tiêu Chí Thành Công Đo Lường Được (Measurable Success Criteria)

1. **An toàn phiên bản tuyệt đối (100% Immutability)**: 0 trường hợp công thức đã chốt bị chỉnh sửa trực tiếp. Muốn cập nhật bắt buộc phải tạo bản sửa đổi (v2, v3).
2. **Thời gian xuất tài liệu (Efficiency)**: Giảm thời gian tổng hợp và xuất bộ PDF gồm 5–10 công thức có trang bìa từ **120 phút** (làm thủ công) xuống dưới **30 giây** trên ứng dụng mobile.
3. **Độ chính xác nguyên liệu (Traceability)**: Nguyên liệu đã ngừng dùng (discontinued) vẫn được bảo toàn nguyên vẹn trong các phiên bản công thức lịch sử, không làm hỏng dữ liệu cũ.
4. **Kiểm soát AI (Human-in-the-loop)**: 100% nội dung hoặc hình ảnh do AI đề xuất phải thông qua bước xác nhận người dùng; toàn bộ hình ảnh AI đều được gắn nhãn định danh *"Hình minh họa AI"*.
5. **Trải nghiệm đọc SOP dạng Sách (E-Book UX)**: Barista lật mở 8 trang SOP với gáy sách 3D, danh mục mục lục TOC mở tức thì, nhảy trang mượt mà không độ trễ.
6. **Kiểm toán an toàn (Auditability)**: 100% thao tác chốt phiên bản và xuất file được lưu vết bất biến với mã băm SHA-256, thời gian và địa chỉ IP/thiết bị rõ ràng.
