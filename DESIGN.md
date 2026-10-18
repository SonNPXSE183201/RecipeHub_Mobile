# NomadKit Design System (RecipeHub Mobile)

🔗 **Figma Design URL**: [https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0](https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0) (Key: `FycUpbP0PtH6Q4sg6IvZr6`)

## 1. Tổng Quan Hệ Thống Thiết Kế (Overview)

NomadKit là hệ thống thiết kế tinh gọn, ấm áp và hướng đến sự bền bỉ trong môi trường làm việc thực tế của ngành F&B (chuỗi quán cà phê và trà sữa 45 chi nhánh). Hệ thống kết hợp bề mặt nền cát kem ấm áp (`#FFFDF7`), thẻ trắng tinh khôi (`#FFFFFF`), các điểm nhấn Vàng cát (`#D4A373`), Xanh đại dương (`#0891B2`) và Xanh rừng (`#166534`).

Đối với ứng dụng **RecipeHub Mobile**, NomadKit hỗ trợ 3 luồng thao tác người dùng (3-Row Flow Architecture):
1. **Nhân viên R&D (Staff Flow)**: Soạn thảo công thức, định lượng nguyên liệu chính xác, hỗ trợ AI có kiểm soát và khóa phiên bản bất biến.
2. **Barista Chi Nhánh (Viewer Flow)**: Màn hình Trang Chủ Viewer tra cứu nhanh và Sách SOP Điện Tử Lật Trang (`BookletReaderPage`).
3. **Quản Trị Chuỗi (Admin Flow)**: Phân quyền tài khoản, cấu hình API Gemini với Live Ping và Nhật ký kiểm toán SHA-256.

---

## 2. Bảng Màu Chuẩn (Color Palette & Tokens)

| Token Name | Hex Code | Ý Nghĩa Sử Dụng & Độ Tương Phản |
| :--- | :--- | :--- |
| **Primary Sand** | `#D4A373` | Nút hành động chính (CTA), icon logo nhận diện thương hiệu |
| **Sand Dark** | `#A07040` | Nhãn tiêu đề mục, hiệu ứng khi nhấn nút |
| **Sand Light** | `#FAF6F0` | Nền thẻ nổi bật, viền hộp thoại |
| **Secondary Ocean**| `#0891B2` | Nút Ping Test kiểm tra API AI, liên kết, badge hỗ trợ AI |
| **Ocean Light** | `#E0F2FE` | Nền thông báo AI, chỉ số trạng thái |
| **Tertiary Forest**| `#166534` | Trạng thái Đã duyệt (Approved), thông báo thành công |
| **Forest Light** | `#DCFCE7` | Nền chip Approved, viền card thành công |
| **Background** | `#FFFDF7` | Màu nền toàn bộ ứng dụng, chống chói lóa dưới ánh sáng quầy bar |
| **Surface Default**| `#FFFFFF` | Nền thẻ card, trang sách SOP, hộp thoại modal |
| **Surface Muted** | `#F6F1E8` | Nền input vô hiệu hóa, thanh trượt trang |
| **Text Primary** | `#292524` | Chữ chính tiêu đề và nội dung (Tương phản 12.8:1 đạt chuẩn WCAG AAA) |
| **Text Secondary**| `#78716C` | Chữ phụ, nhãn đơn vị đo lường, Watermark "BẢN NHÁP" |
| **Border Default** | `#E7E0D5` | Viền thẻ card 1dp tinh tế |
| **Warning** | `#854D0E` | Chữ nhãn Bản nháp (Draft), cảnh báo tồn kho |
| **Warning Light** | `#FEF9C3` | Nền chip Bản nháp (Draft) |
| **Error** | `#DC2626` | Thông báo lỗi kết nối, cảnh báo nhập liệu sai |

---

## 3. Kiểu Chữ (Typography)

- **Display / Tiêu Đề Lớn**: `DM Serif Display` (hoặc `Georgia`), kích thước 26–32 sp.
- **Nội Dung / Giao Diện UI**: `Inter` (hoặc hệ thống sans-serif), kích thước 14–15 sp, chiều cao dòng 1.45–1.5.
- **Chữ Số / Mã Kiểm Toán**: `JetBrains Mono` / Monospace, kích thước 12–13 sp.
- **Tiêu Chuẩn Tiếp Cận**: Cỡ chữ tối thiểu cho nội dung là 14 sp. Chữ hướng dẫn quầy bar trong chế độ Barista Viewer đạt 18–22 sp để đọc rõ từ khoảng cách 1 mét.

---

## 4. Khoảng Cách, Bo Góc & Đổ Bóng (Spacing, Radius & Elevation)

- **Khoảng cách cơ sở**: Bội số của 4 dp (`sp-1`: 4dp, `sp-2`: 8dp, `sp-3`: 12dp, `sp-4`: 16dp, `sp-5`: 24dp).
- **Lề ngang màn hình**: 16 dp trên màn 360dp, 20–24 dp trên màn 412dp (Pixel 5).
- **Bo góc (Corner Radius)**:
  - `radius-sm` (4 dp): Badge nhỏ.
  - `radius-md` (8 dp): Ô nhập liệu text field, dropdown.
  - `radius-lg` (14 dp): Thẻ card chuẩn.
  - `radius-xl` (16–18 dp): Thẻ card chức năng, nút bấm chính, hộp thoại modal.
  - `radius-pill` (999 dp): Chip trạng thái hình viên thuốc.
- **Đổ bóng (Elevation)**:
  - `shadow-sm`: `0 2dp 8dp rgba(70, 54, 35, 0.08)` cho thẻ nổi.
  - `shadow-book`: `LinearGradient` chuyển từ đen mờ 15% sang trong suốt ở mép gáy sách của `BookletReaderPage`.

---

## 5. Quy Chuẩn Thành Phần Giao Diện (Components)

### Logo Tách Cà Phê (Squircle Coffee Cup Logo)
- Khối hình vuông bo góc tròn (squircle) màu vàng cát `#D4A373`.
- Icon tách cà phê trắng nằm chính tâm (`Icons.coffee_rounded`).
- Xuất hiện đồng bộ trên AppBar của mọi màn hình, Banner Admin, Header chi nhánh và Bìa Sách SOP.

### Nút Bấm (Buttons)
- Chiều cao cố định: **52 dp** (bảo đảm vượt chuẩn tiếp cận ngón tay cái quầy bar >= 48dp).
- Bo góc: **16 dp**.
- Nút Chính (Primary Sand): Nền `#D4A373`, chữ trắng hoặc than đá.
- Nút Kiểm Tra (Ping Test / Ocean): Nền `#0891B2`, chữ trắng, icon tia chớp.
- Nút Sách SOP: Nền `#A07040` (Sand Dark), chữ trắng, icon cuốn sách.

### Sách SOP Điện Tử (Booklet Reader)
- Bố cục mô phỏng sách giấy thật với hiệu ứng đổ bóng gáy sách 3D (`spine shadow`).
- Hệ thống 8 trang SOP chuẩn hóa.
- Thanh trượt trang (scrubber slider) và Drawer danh mục mục lục TOC.
- Watermark "BẢN NHÁP" in chéo 45 độ trên các trang công thức chưa được phê duyệt.
