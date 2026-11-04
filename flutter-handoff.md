# RecipeHub Mobile — Flutter Handoff Specification (Đồng Bộ Figma & Mobile Native)

Tài liệu này cung cấp toàn bộ thông số kỹ thuật chi tiết để lập trình viên Flutter có thể hiện thực hóa 100% thiết kế giao diện từ Figma sang mã nguồn Flutter mà không cần phỏng đoán, tuân thủ chặt chẽ **SRS Phạm vi nhỏ (v0.1)** và hướng dẫn đánh giá **PRM323 Lab 2**.

> **Phạm vi tài liệu:** đặc tả giao diện/prototype, không phải bằng chứng mọi nghiệp vụ đã tích hợp production. `LoginPage` hiện điều hướng theo email, chưa xác thực Identity. `AdminAiConfigPage` gọi Gateway `/health/live`, có nhánh giả lập thành công khi lỗi; số 138ms, chi nhánh, SHA-256 và hạn ngạch trong demo không chứng minh dữ liệu backend thật. Tên widget trong sơ đồ mã nguồn mục 3.2 là tên file hiện tại; các mã SCR là nhãn thiết kế.

🔗 **Figma Design URL**: [https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0](https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0) (Key: `FycUpbP0PtH6Q4sg6IvZr6`)

---

## 1. Bảng Ánh Xạ Design Token Sang Flutter ThemeData (Token Mapping)

| NomadKit Token | Giá trị Hex / CSS | Thuộc tính Flutter ThemeData / Code | Ghi chú kỹ thuật |
| :--- | :--- | :--- | :--- |
| `color.primarySand` | `#C49A6C` | `NomadKit.sand` / `Color(0xFFC49A6C)` | Màu Vàng cát trong source hiện tại |
| `color.sandDark` | `#A07040` | `NomadKit.sandDark` / `Color(0xFFA07040)` | Màu nhấn đậm khi hover/press, nhãn mục |
| `color.sandLight` | `#FAF6F0` | `NomadKit.sandLight` / `Color(0xFFFAF6F0)` | Màu nền highlight, viền thẻ |
| `color.secondaryOcean`| `#0891B2` | `NomadKit.ocean` / `Color(0xFF0891B2)` | Màu Xanh đại dương cho nút Ping Test, link, badge AI |
| `color.oceanLight` | `#F0F9FF` | `NomadKit.oceanLight` / `Color(0xFFF0F9FF)` | Nền badge AI, thông báo phụ |
| `color.tertiaryForest`| `#166534` | `NomadKit.forest` / `Color(0xFF166534)` | Màu Xanh rừng cho trạng thái Đã duyệt (Approved) |
| `color.forestLight` | `#DCFCE7` | `NomadKit.forestLight` / `Color(0xFFDCFCE7)` | Nền chip Approved, icon thành công |
| `color.background` | `#FFFDF7` | `NomadKit.canvas` / `Color(0xFFFFFDF7)` | Nền canvas ấm chống chói quầy bar |
| `color.surface` | `#FFFFFF` | `NomadKit.surface` / `Color(0xFFFFFFFF)` | Nền thẻ card, modal sheet, dialog |
| `color.surfaceMuted` | `#F6F1E8` | `Color(0xFFF6F1E8)` | Token thiết kế đề xuất; chưa có hằng `NomadKit.surfaceMuted` |
| `color.textPrimary` | `#292524` | `NomadKit.ink` / `Color(0xFF292524)` | Màu than đá cho tiêu đề & body (Contrast 12.8:1) |
| `color.textSecondary`| `#78716C` | `NomadKit.secondary` / `Color(0xFF78716C)` | Màu xám ấm cho metadata, nhãn phụ |
| `color.border` | `#E7E0D5` | `NomadKit.border` / `Color(0xFFE7E0D5)` | Viền thẻ 1dp tinh gọn |
| `color.warning` | `#CA8A04` | `NomadKit.warning` / `Color(0xFFCA8A04)` | Màu cảnh báo trong source hiện tại |
| `color.warningLight` | `#FEF9C3` | `NomadKit.warningLight` / `Color(0xFFFEF9C3)` | Nền chip Bản nháp (Draft) |
| `color.error` | `#DC2626` | `NomadKit.error` / `Color(0xFFDC2626)` | Màu đỏ báo lỗi kết nối, validation |
| `radius.sm` | `4 dp` | `BorderRadius.circular(4)` | Bo góc badge nhỏ |
| `radius.md` | `8 dp` | `BorderRadius.circular(8)` | Bo góc text field, dropdown |
| `radius.lg` | `14 dp` | `BorderRadius.circular(14)` | Bo góc thẻ card chuẩn |
| `radius.xl` | `16–18 dp` | `BorderRadius.circular(16)` | Bo góc card nổi bật, nút bấm chính, dialog lớn |
| `radius.pill` | `999 dp` | `StadiumBorder()` | Bo tròn hình viên thuốc cho Status Chip |
| `elevation.sm` | `0 2dp 8dp rgba(70,54,35,0.08)` | `BoxShadow(color: Color(0x14463623), blurRadius: 8, offset: Offset(0, 2))` | Đổ bóng nhẹ cho thẻ nổi |

---

## 2. Quy Định Đồng Bộ Nhận Diện Thương Hiệu (Brand Consistency)

Toàn bộ các màn hình trong ứng dụng phải tuân thủ nghiêm ngặt 3 quy chuẩn hiển thị thống nhất với màn hình Đăng nhập và Dashboard trên Figma:
1. **Logo Tách Hạt Cà Phê (Squircle Coffee Cup Logo)**:
   - Sử dụng khối bo góc tròn màu vàng cát (`NomadKit.sand` / `#C49A6C`); kích thước tùy vị trí, `LoginPage` hiện dùng `56×56 dp`.
   - Icon tách cà phê trắng nằm chính tâm (`Icons.coffee_rounded`, màu `Colors.white`), bo góc chuẩn `10–12 dp`.
   - Xuất hiện đồng bộ trên: AppBar của tất cả các màn hình con (`ScreenFrame`), Banner Quản trị hệ thống chuỗi (`AdminConsolePage`), Header chi nhánh Landmark 81 (`ViewerHomePage`), và Trang bìa Sách SOP (`BookletReaderPage`).
2. **Kích Thước Vùng Chạm & Bo Góc Nút Bấm (Button Specifications)**:
   - Chiều cao cố định: **52 dp** (bảo đảm vượt chuẩn tiếp cận ngón tay cái quầy bar >= 48dp).
   - Bo góc nút: **16 dp** (`RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`).
   - Font chữ nút: `Inter 14–15 sp`, `FontWeight.w700`.
3. **Quy Chuẩn Thẻ Card & Status Chip**:
   - Thẻ chức năng bo góc **16–18 dp**, viền mảnh 1dp màu `#E7E0D5`.
   - Status Chip chuẩn hình viên thuốc (`StadiumBorder`):
     - `Bản nháp (Draft)`: Nền vàng nhạt `#FEF9C3`, chữ nâu đất `#854D0E`, icon bút chì.
     - `Đã chốt (Approved)`: Nền xanh lá nhạt `#DCFCE7`, chữ xanh rừng `#166534`, icon tích tròn.

---

## 3. Kiến Trúc 3 Phân Hệ Vận Hành & Cấu Trúc Mã Nguồn Modular Chuẩn

### 3.1. Phân Chia 3 Phân Hệ Tác Nghiệp (3-Role Architecture)
Hệ thống được tổ chức thành **3 Phân Hệ Vận Hành Chuỗi** rành mạch, bảo đảm tối ưu hóa năng suất và không gây nhiễu luồng nghiệp vụ:
- **Phân hệ 1 — Nhân Viên R&D (Staff Flow)**: Quản lý thư viện công thức, kho nguyên liệu chuẩn (g/ml), trợ lý AI gợi ý có kiểm duyệt, xuất bộ PDF Master Book.
- **Phân hệ 2 — Barista Chi Nhánh (Viewer Flow)**: Trang chủ Viewer tra cứu món và Sách điện tử SOP lật trang tương tác (`BookletReaderPage`) với gáy sách 3D, mục lục TOC.
- **Phân hệ 3 — Quản Trị Toàn Chuỗi (Admin Flow)**: Bảng điều khiển 45 chi nhánh, phân quyền 48 tài khoản, cấu hình AI Gemini kèm kiểm tra Live Ping 138ms, đối soát nhật ký kiểm toán SHA-256.

### 3.2. Cấu Trúc Thư Mục Mã Nguồn Modular Chuẩn Flutter (Clean Architecture)
Mã nguồn ứng dụng được phân tách độc lập và module hóa triệt để từ file đơn monolithic ban đầu thành kiến trúc tính năng (Feature-first Architecture), đạt **0 lỗi / 0 cảnh báo khi chạy `flutter analyze`**:

```text
lib/
├── core/                               # Tài nguyên & Thành phần dùng chung toàn app
│   ├── theme/
│   │   └── nomad_kit.dart              # Hệ thống Design Tokens (Màu sắc, Typography, Spacing, Radius)
│   ├── utils/
│   │   └── navigation.dart             # Hàm điều hướng toàn cục go(context, screenId)
│   └── widgets/
│       ├── recipe_hub_logo.dart        # Logo thương hiệu tách cà phê squircle vàng cát (36dp / 64dp)
│       └── screen_frame.dart           # Khung màn hình chuẩn (AppBar, Back button, Title, Actions)
├── features/                           # Các phân hệ nghiệp vụ độc lập
│   ├── auth/                           # Đăng nhập & Đăng ký chuẩn Production
│   │   ├── login_page.dart             # Giao diện Production sạch sẽ & Thanh chọn vai trò [R&D | Barista | Quản trị]
│   │   └── register_page.dart          # Màn hình đăng ký chuyên viên mới
│   ├── rd_staff/                       # Phân hệ 1: Chuyên viên R&D (14 màn hình)
│   │   ├── dashboard_page.dart         # Dashboard 4 KPI & Hoạt động gần đây
│   │   ├── recipe_catalog_page.dart    # Thư viện công thức (Tab Đã duyệt & Nháp)
│   │   ├── recipe_detail_page.dart     # Chi tiết công thức & Khóa bất biến v2
│   │   ├── recipe_editor_page.dart     # Trình soạn thảo & Gọi AI gợi ý
│   │   ├── recipe_review_page.dart     # Checklist an toàn & Chốt khóa phiên bản
│   │   ├── ingredients_catalog_page.dart # Quản lý kho nguyên liệu metric (g, ml)
│   │   ├── ingredient_create_page.dart # Thêm nguyên liệu mới
│   │   ├── ingredient_edit_page.dart   # Sửa nguyên liệu & Cảnh báo khóa xóa cứng
│   │   ├── batch_export_page.dart      # Gom nhiều món đóng gói 1 PDF SOP Master
│   │   ├── pdf_cover_preview_page.dart # Xem trước Trang bìa & Mục lục PDF
│   │   ├── pdf_draft_preview_page.dart # Xem trước PDF đơn có Watermark Bản nháp 45°
│   │   ├── export_history_page.dart    # Thư viện & Lịch sử xuất bản PDF toàn chuỗi
│   │   ├── account_settings_page.dart  # Hồ sơ R&D & Điều hướng vai trò phân hệ
│   │   └── main_nav_shell.dart         # Vỏ điều hướng Bottom Navigation Bar 4 Tab
│   ├── barista/                        # Phân hệ 2: Barista Quầy Bar (4 màn hình)
│   │   ├── viewer_home_page.dart       # Trang chủ Barista Landmark 81 & Banner mở Sách SOP
│   │   ├── booklet_reader_page.dart    # Sách SOP E-Booklet lật 8 trang, gáy 3D, Drawer TOC
│   │   ├── barista_viewer_page.dart    # Chế độ xem nhanh chữ lớn 18-22sp
│   │   └── brewing_timer_page.dart     # Chế độ pha chế từng bước kèm Timer
│   ├── admin/                          # Phân hệ 3: Quản trị viên (4 màn hình)
│   │   ├── admin_console_page.dart     # Bảng điều khiển Admin 45 chi nhánh
│   │   ├── admin_user_management_page.dart # Phân quyền 48 tài khoản người dùng
│   │   ├── admin_ai_config_page.dart   # Cấu hình API Gemini & Live Ping Test 138ms
│   │   └── admin_audit_logs_page.dart  # Nhật ký kiểm toán toàn chuỗi lưu vết SHA-256
│   └── system/                         # Màn hình trạng thái hệ thống (2 màn hình)
│       ├── loading_transition_page.dart # Màn hình Loading chuyển cảnh mượt mà (1.5s)
│       └── error_recovery_page.dart    # Màn hình Báo lỗi mạng & Bảo toàn nháp ngoại tuyến
└── main.dart                           # Điểm khởi chạy ứng dụng tinh gọn & Điều hướng (~200 dòng)
```

### 3.3. Chi Tiết Màn Hình & Phạm Vi Prototype

#### SCR-01: Đăng Nhập Demo (`LoginPage`)
- **Loại Bỏ Hoàn Toàn Tạp Dư Dev**: Xóa bỏ hoàn toàn 3 khối card phím tắt dev thô sơ, các dòng log BE và thanh trạng thái giả lập iOS `9:41`.
- **Điều Hướng Vai Trò Demo:** `LoginPage` hiện chọn Viewer nếu email chứa `barista`, Admin nếu chứa `admin`, còn lại mở R&D; chưa gọi Identity và không có thanh chọn vai trò. Đây không phải cơ chế phân quyền production.
- **Bảo Toàn Mock Data Thực Tế**: Dữ liệu công thức, nguyên liệu và thông tin chuỗi được giữ nguyên độ phong phú để giao diện chân thực nhất.

#### SCR-16a: Trang Chủ Viewer Quầy Bar (`ViewerHomePage`)
- **Layout**: Header chi nhánh Landmark 81 với logo tách hạt, thanh tìm kiếm đồ uống, hàng chip phân loại (Tất cả, Cà phê, Trà hoa quả, Đá xay).
- **Banner Nổi Bật**: Thẻ truy cập Sổ tay SOP Master Book 2026 với nút kêu gọi hành động "Mở Sách Lật Trang SOP (E-Book)".
- **Danh Sách Món**: Mỗi món hiển thị ảnh thật, công thức phiên bản (v1, v2), chip trạng thái và 2 nút hành động:
  - `[📖 Đọc trang SOP]`: Nhảy trực tiếp vào trang công thức trong `BookletReaderPage`.
  - `[📋 Pha chế (Checklist)]`: Mở màn hình hướng dẫn từng bước với đồng hồ đếm giờ.

#### SCR-17a: Sách SOP Điện Tử Lật Trang Tương Tác (`BookletReaderPage`)
- **Layout Sách 3D**:
  - Khung sách mô phỏng trang giấy thật với hiệu ứng đổ bóng gáy sách (`spine shadow gradient`: viền đen mờ 15% chuyển dần sang trong suốt ở mép gáy).
  - Trọn bộ 8 trang nội dung:
    1. Trang bìa: Logo vàng cát, huy hiệu "OFFICIAL SOP 2026", mã xác thực SHA-256.
    2. Quy chuẩn an toàn quầy bar (HACCP, nhiệt độ bảo quản, vệ sinh vòi steam).
    3. Công thức chuẩn Cold Brew Cam Quế v2 (Approved).
    4. Kỹ thuật ủ lạnh 16 giờ & kiểm soát độ chua.
    5. Công thức chuẩn Ô Long Sen Vàng v1 (Approved).
    6. Kỹ thuật đánh bọt Macchiato bồng bềnh 2.5cm.
    7. Công thức Matcha Latte Mây v3 (Bản nháp — có Watermark "BẢN NHÁP" in chéo 45 độ màu xám).
    8. Bảng dung sai định lượng toàn chuỗi & Hotline R&D.
- **Điều Khiển Đọc Sách**:
  - Thanh trượt trang (scrubber slider) mượt mà giúp lướt nhanh từ trang 1 đến trang 8.
  - Nút `< Trang trước` và `Trang sau >`.
  - Nút `Mục lục` mở Modal Bottom Sheet hiển thị danh sách 8 chương mục, chạm vào để nhảy ngay đến trang mong muốn.

#### SCR-18: Bảng Điều Khiển Admin (`AdminConsolePage`)
- Thống kê chỉ số chuỗi: 45 Chi nhánh, 48 Nhân sự, 98.5% Tuân thủ SOP.
- 3 Ô điều hướng chuyên sâu:
  1. `Phân quyền tài khoản (SCR-18a)`: Mở `AdminUserManagementPage`.
  2. `Cấu hình API Gemini / AI (SCR-18b)`: Mở `AdminAiConfigPage`.
  3. `Nhật ký kiểm toán (SCR-18c)`: Mở `AdminAuditLogsPage`.

#### SCR-18a: Phân Quyền Tài Khoản Chuỗi (`AdminUserManagementPage`)
- Bộ lọc vai trò: Tất cả (48), R&D Lead (3), Barista (45).
- Thẻ người dùng hiển thị ảnh đại diện, họ tên, chi nhánh trực thuộc, công tắc bật/tắt kích hoạt (Switch) và danh sách chip quyền hạn (Sáng tạo công thức, Chốt v2/v3, Đọc SOP).

#### SCR-18b: Cấu Hình API Gemini & AI Engine (`AdminAiConfigPage`)
- Dropdown chọn mô hình: Gemini 1.5 Pro (Độ chính xác cao) / Gemini 1.5 Flash (Tốc độ cao).
- Trường nhập API Key với nút ẩn/hiện mật khẩu.
- Nút `Kiểm tra kết nối API (Ping Test)`: hiện gọi Gateway `/health/live`, không gọi trực tiếp Gemini. Nhánh demo có thể hiện "138 ms · HTTP 200 OK" kể cả khi request lỗi; không dùng kết quả này để xác nhận AI provider sẵn sàng.
- Thanh trượt độ chặt chẽ (Temperature) 0.0 – 1.0 (Khuyến nghị 0.2 cho chuẩn F&B).
- System Prompt và thanh tiến độ hạn ngạch token trong tháng.

#### SCR-18c: Nhật Ký Kiểm Toán Toàn Chuỗi (`AdminAuditLogsPage`)
- Dòng thời gian (Timeline) ghi nhận toàn bộ thao tác: Chốt phiên bản, Xuất PDF Master Book, Cập nhật API AI, Tải file SOP về máy POS.
- Mỗi bản ghi có thời gian chính xác, người thực hiện, địa chỉ IP thiết bị và chuỗi mã băm bất biến SHA-256.

---

## 4. Giải Pháp Trích Xuất Giao Diện & Nút Bấm Mobile Lên Figma Để Làm Prototype và Demo Native Mobile

Để giải quyết bài toán: **Lấy giao diện các nút bấm/component từ ứng dụng Mobile đưa lên Figma làm Prototype và thực hiện Demo hoàn toàn trên thiết bị di động (Không dùng trình duyệt Web)**, quy trình kỹ thuật chuẩn 4 bước được triển khai như sau:

```
[Mã nguồn Flutter Mobile]
          │
          ▼ (Chạy thực tế trên Android Emulator Pixel 5)
[Chụp ảnh màn hình Native 1080×2340 px qua ADB]
          │
          ▼ (Đưa vào Figma Frame Mobile 412×915 dp)
[Xây dựng Frame & Component Library trên Figma]
          │
          ▼ (Gắn Hotspot tương tác On Tap -> Navigate To)
[Figma Prototype Click-Through]
          │
          ▼ (Chạy thử & Trình diễn qua Figma Mirror App hoặc Trực tiếp trên Android Emulator)
[MOBILE NATIVE DEMO (100% Mobile Không Dùng Web)]
```

### Bước 1: Trích Xuất Giao Diện & Nút Bấm Từ Mobile Sang Figma
1. **Chụp ảnh màn hình chuẩn tỷ lệ Pixel-perfect từ máy ảo Android qua lệnh ADB**:
   ```bash
   adb exec-out screencap -p > output/screenshots/scr_ten_man_hinh.png
   ```
   *Lợi thế*: Ảnh chụp giữ nguyên độ phân giải chuẩn 1080×2340 px, chuẩn tỷ lệ 9:19.5 của Pixel 5, không bị mờ nhòe hay sai lệch layout như khi co kéo trên trình duyệt web.
2. **Tạo Frame chuẩn Mobile trên Figma**:
   - Tạo Frame có kích thước chuẩn **Android Compact / Large (412 × 915 dp)**.
   - Dán ảnh chụp màn hình native vào Frame, căn chỉnh vừa khít khung nhìn.
3. **Tái hiện Component Nút Bấm & Thẻ (Component Extraction)**:
   - Dùng công cụ Rectangle của Figma vẽ đè lên vị trí nút bấm mobile: Chiều cao `52 dp`, `Corner Radius = 16 dp`, Fill `#C49A6C` (Primary Sand hiện tại) hoặc `#0891B2` (Ocean).
   - Đặt Text `Inter 14sp Bold` và chèn Icon vector tương ứng.
   - Bấm `Ctrl + Alt + K` để biến thành Figma Component Master (ví dụ: `Button/Primary_52dp`, `Button/PingTest_52dp`, `Card/RecipeTile_16dp`).
   - Tạo các biến thể Component (Variants): `Default`, `Hover/Pressed`, `Disabled`.

### Bước 2: Thiết Lập Tương Tác Prototype Trên Figma
1. Chuyển sang tab **Prototype** trên thanh công cụ phải của Figma.
2. Chọn nút bấm hoặc thẻ chức năng:
   - Kéo mũi tên tương tác từ nút bấm sang màn hình đích.
   - Thiết lập Trigger: `On tap`.
   - Action: `Navigate to [Tên màn hình đích]`.
   - Animation: `Smart Animate` (thời gian `300ms`, đường cong `Ease Out`) hoặc `Push / Slide In` từ phải sang trái để mô phỏng chính xác hiệu ứng chuyển cảnh của Flutter Android.
3. Với các tính năng như Drawer Mục lục (TOC) của Sách SOP:
   - Thiết lập Action: `Open overlay` -> `Bottom sheet`.
   - Animation: `Move in` từ dưới lên (`Bottom to Top`).

### Bước 3: Phương Pháp Trình Diễn Live Demo Native Mobile (100% Không Dùng Web)
Có 2 phương pháp demo hoàn toàn trên môi trường di động thực tế:
1. **Phương pháp A — Sử dụng Ứng dụng Figma Mirror / Figma Mobile App**:
   - Cài đặt ứng dụng **Figma** từ Google Play Store lên máy ảo Android Emulator hoặc điện thoại thật.
   - Đăng nhập tài khoản Figma và mở file `FycUpbP0PtH6Q4sg6IvZr6`.
   - Chọn tab **Mirror** hoặc mở Prototype: Ứng dụng sẽ hiển thị toàn màn hình (Full-screen Native), hỗ trợ chạm vuốt cảm ứng đa điểm, chuyển trang mượt mà 60 FPS y hệt như ứng dụng thật được cài đặt trong máy.
2. **Phương pháp B — Chạy Trực Tiếp Ứng Dụng Flutter Đã Build Trên Máy Ảo Android**:
   - Khởi chạy ứng dụng qua lệnh:
     ```bash
     flutter run -d emulator-5554
     ```
   - Trình chiếu trực tiếp cửa sổ Android Emulator Pixel 5 trong buổi báo cáo.
   - Trình diễn Ping Gateway health, sách SOP và điều hướng 3 vai trò demo. Kết quả Ping giả lập không xác nhận kết nối Gemini; đăng nhập và dữ liệu nghiệp vụ phải tích hợp Identity/API thật trước khi nghiệm thu production.
