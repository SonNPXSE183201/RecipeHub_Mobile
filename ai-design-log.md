# RecipeHub Mobile — Nhật Ký Thiết Kế & Phản Biện AI (AI Design Log)

Tài liệu này ghi lại toàn bộ chuỗi quyết định thiết kế có hỗ trợ của AI (Analyze → Generate → Critique → Refine → Prototype → Handoff) theo đúng chuẩn đánh giá PRM323 Lab 2.

---

## 1. Prompt AI Nguyên Văn (Verbatim Original Prompt)

Dưới đây là prompt đầy đủ được nhóm sử dụng trên công cụ Google Stitch và Gemini UI Assistant để sinh giao diện ban đầu:

```text
Role & Persona:
You are an expert mobile UI/UX designer specialized in Enterprise F&B and kitchen operations.
Design a mobile application for Tran Thuy Linh (28 years old), a Beverage R&D Specialist at a 45-store coffee & milk tea chain. She works in a busy test kitchen with noisy blenders, wet hands, holding her phone with one hand while measuring ingredients.

Platform & Device Constraints:
- Android mobile application (portrait orientation).
- Optimized for standard screen widths: 360 dp (compact) and 412 dp (standard/large).
- Ergonomic one-handed thumb zone; touch targets must be at least 48x48 dp.
- Body text size >= 14 sp for high legibility under kitchen lighting.

Task & Functional Scope (Small Scope SRS):
1. Manage ingredient catalog with standardized metric units (g, ml) and stock thresholds; discontinued items must be preserved (no hard delete).
2. Create & edit beverage recipes with exact ingredient quantities, sequential steps (time, temp, tools, safety notes), and real/AI photos.
3. Strict Immutability & Version Control: Approved recipes are locked and immutable. Any change requires creating a new revision (v2, v3).
4. Human-in-the-loop AI: AI can suggest step refinements or generate illustration images, but CANNOT overwrite content without explicit user approval ("Accept" or "Reject"). AI images must have an explicit "Hình minh họa AI" badge.
5. Multi-selection Batch PDF Export: Combine multiple recipes into ONE single PDF SOP Booklet with cover page and table of contents. Draft recipes enforce a "BẢN NHÁP" watermark.
6. Offline resilience: Retain drafts locally during network loss with error recovery.

Design Style:
NomadKit Design System: Warm Sand (#D4A373) as primary accent, Ocean Cyan (#0891B2) for links/info, Forest Green (#166534) for approved/success, warm canvas background (#FFFDF7), clean cards (#FFFFFF) with 12-16 dp border radius. Clean typography with DM Serif Display for headlines and Inter for UI/body text. NO emojis for measurement units.
```

---

## 2. Kết Quả Sinh Giao Diện Ban Đầu (Initial Stitch Output) & Đánh Giá Tổng Quan

### Kết quả Stitch ban đầu:
* Stitch đề xuất giao diện phong cách "NoirLuxe" nền tối huyền bí (`#0C0C0E`) với điểm nhấn vàng ánh kim (`#C9A84C`).
* Danh mục nguyên liệu dùng nhiều Emoji minh họa (🍵 Bột matcha, 🥛 Sữa tươi, 🍊 Cam vàng).
* Trên màn hình chi tiết công thức, có nút "Sửa công thức" trực tiếp bất kỳ lúc nào và nút "AI Tối ưu hóa" tự động ghi đè định lượng theo tỷ lệ chuẩn của AI.
* Khi xuất PDF, mỗi công thức xuất thành một file PDF đơn lẻ riêng biệt, không có trang bìa hay mục lục chung.

---

## 3. Ba Vòng Lặp Tinh Chỉnh Có Mục Tiêu Khác Nhau (Three Distinct Iterations)

### Vòng 1: Thích Ứng Môi Trường Quầy Bar & Trợ Năng (Environment Adaptation & Accessibility)
* **Vấn đề phát hiện**: Tone màu tối NoirLuxe (`#0C0C0E`) gây chói lóa nghiêm trọng dưới ánh đèn rọi quầy bar và ánh sáng tự nhiên. Màn hình tối dính vệt nước làm mờ chữ, độ tương phản của chữ phụ màu xám trên nền đen chỉ đạt 2.8:1 (vi phạm WCAG AA).
* **Mục tiêu tinh chỉnh**: Chuyển đổi toàn bộ bảng màu sang hệ thống **NomadKit Canvas** ấm áp, dịu mắt, chống lóa.
* **Trước tinh chỉnh (Before)**: Nền đen tuyền `#0C0C0E`, chữ xám `#6B7280`, viền tối, nút vàng kim chói.
* **Sau tinh chỉnh (After)**: Nền kem ấm `#FFFDF7`, thẻ trắng `#FFFFFF`, chữ than đá `#292524` đạt độ tương phản **12.8 : 1** (vượt xa chuẩn WCAG 4.5:1), điểm nhấn Sand `#D4A373` và Forest `#166534`.

---

### Vòng 2: Chuẩn Hóa Nhận Diện & Biểu Tượng Đa Nền Tảng (Cross-Platform Consistency & UI Hygiene)
* **Vấn đề phát hiện**: Việc AI sử dụng Emoji (🍵, 🥛, 🍋) làm icon nguyên liệu hiển thị méo mó, không đồng nhất trên các hãng điện thoại Android (Samsung OneUI hiển thị khác Google Pixel và Xiaomi MIUI). Vùng chạm (touch target) của nút xóa dòng chỉ có 28×28 dp, khiến chuyên viên tay ướt bấm nhầm liên tục.
* **Mục tiêu tinh chỉnh**: Bác bỏ toàn bộ Emoji; áp dụng thư viện Icon Vector line chuẩn mực (Material Rounded & Lucide) với vùng chạm tối thiểu 48×48 dp.
* **Trước tinh chỉnh (Before)**: Emoji lộn xộn, không có nhãn đơn vị đo rõ ràng, nút xóa nhỏ 28 dp.
* **Sau tinh chỉnh (After)**: Icon vector tinh gọn có nền bo góc, phân tách rõ ràng đơn vị đo (`g`, `ml`), toàn bộ nút điều khiển và icon button mở rộng padding đạt **52 dp**.

---

### Vòng 3: Khóa Bất Biến Doanh Nghiệp & Kiểm Soát AI (Enterprise Immutability & Human-in-the-loop AI)
* **Vấn đề phát hiện**: 
  1. Cho phép sửa trực tiếp công thức đã chốt vi phạm nghiêm trọng nguyên lý **Nielsen #5 (Ngăn ngừa lỗi)**, có thể gây sai lệch hương vị toàn chuỗi 45 cửa hàng.
  2. Nút AI tự ý đổi định lượng vi phạm nguyên lý **Nielsen #3 (Quyền tự do và kiểm soát của người dùng)**.
  3. Xuất file rời rạc gây tốn thời gian tổng hợp thủ công (mất 2–3 giờ mỗi mùa menu mới).
* **Mục tiêu tinh chỉnh**: Thiết lập kiến trúc bất biến (Immutability Lock), tích hợp quy trình AI trợ lý đề xuất có nút "Chấp nhận" / "Từ chối", và phân hệ **Batch PDF Studio** đóng gói 1 bộ SOP có Bìa, Mục lục và Watermark bản nháp.
* **Trước tinh chỉnh (Before)**: Sửa trực tiếp tự do; AI tự ghi đè; xuất PDF từng file lẻ.
* **Sau tinh chỉnh (After)**: 
  - Công thức đã duyệt có nhãn xanh `[Đã duyệt · v2]`, bị khóa sửa; muốn đổi phải bấm *"Tạo bản sửa đổi mới"* để sinh v3.
  - Dialog AI hiển thị nội dung đề xuất với nhãn *"Chưa áp dụng"* cùng 2 lựa chọn: *"Chấp nhận"* hoặc *"Từ chối"*.
  - Toàn bộ ảnh do AI sinh gắn nhãn định danh *"Hình minh họa AI"*.
  - Màn hình SCR-11 cho phép tích chọn nhiều món để tạo 1 file `RecipeHub_SOP_MasterBook.pdf` có Trang bìa và Mục lục.

---

## 4. Năm Phát Hiện UX Cụ Thể Trên Từng Màn Hình (Five Screen-Specific UX Findings)

| # | Màn hình | Nguyên lý / Tiêu chuẩn đối chiếu | Vấn đề UX phát hiện | Giải pháp cải tiến thực tế |
|---|---|---|---|---|
| **1** | **SCR-05 (Chi tiết công thức)** | **Nielsen #5 (Ngăn ngừa lỗi)** | Cho phép sửa trực tiếp công thức đang áp dụng tại 45 chi nhánh, dễ bấm nhầm làm hỏng SOP toàn chuỗi. | Khóa cứng bản đã chốt (`Immutability`). Khi bấm sửa, hệ thống hiển thị Dialog giải thích và chuyển hướng sang tạo bản sửa đổi mới (v2, v3). |
| **2** | **SCR-06 (Soạn thảo công thức)** | **Nielsen #3 (Quyền kiểm soát & tự do)** | AI tự ý cập nhật câu chữ và định lượng vào bản lưu khi người dùng bấm "Tối ưu hóa". | Thiết kế Dialog đề xuất AI độc lập: Chuyên viên xem trước, có toàn quyền bấm **"Chấp nhận"** hoặc **"Từ chối"** mà không bị ghi đè. |
| **3** | **SCR-11 & SCR-12 (Batch PDF Studio)** | **Nielsen #1 (Hiển thị trạng thái hệ thống)** | Khi xuất bộ PDF gồm nhiều công thức, người dùng không biết hệ thống đang xử lý hay bị treo. | Bổ sung màn hình **SCR-19 (Loading Transition 1.5s)** hiển thị tiến trình: *"Đang kết xuất bộ PDF gồm X công thức..."*, sau đó chuyển cảnh sang bản xem trước có Trang bìa. |
| **4** | **SCR-08 & SCR-10 (Quản lý nguyên liệu)** | **WCAG 2.1 AA (Touch Targets & Constraints)** | Nút thao tác trên danh sách nguyên liệu quá nhỏ (28dp), dễ bấm nhầm; nguyên liệu bị xóa cứng làm hỏng lịch sử công thức cũ. | Mở rộng vùng chạm lên **52 dp**; ngăn chặn xóa cứng nguyên liệu đã có liên kết công thức, chỉ cho phép chuyển sang trạng thái *"Ngừng dùng"*. |
| **5** | **SCR-20 (Phục hồi lỗi & Ngoại tuyến)** | **Nielsen #9 (Nhận biết & phục hồi lỗi)** | Khi mất mạng lúc đang gọi AI hoặc xuất PDF, ứng dụng báo lỗi chung chung và xóa trắng form nhập liệu. | Thiết kế màn hình **SCR-20 Error & Recovery**: Bảo lưu nguyên vẹn 100% dữ liệu nháp vào bộ nhớ máy, cung cấp nút **"Thử lại kết nối"** và nút **"Tiếp tục sửa thủ công"**. |

---

> **Figma Design URL**: [https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0](https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub?node-id=0-1&p=f&t=CCMYGJ1nhqFSWdS1-0) (Key: `FycUpbP0PtH6Q4sg6IvZr6`)  
> **Testing Platform**: Android Emulator Pixel 5 (1080×2340 px) Native Mobile Test

## 5. Bảng Quyết Định Thiết Kế (Design Decisions Summary - 9 Quyết Định)

1. **DEC-01 (MODIFY)**: Từ chối Dark Mode NoirLuxe `#0C0C0E`, chuyển sang NomadKit Canvas `#FFFDF7` dịu mắt, chống chói quầy bar.
2. **DEC-02 (REJECT)**: Bác bỏ hoàn toàn Emoji, thay bằng Icon Vector line chuẩn mực và đơn vị đo lường metric `g`, `ml`.
3. **DEC-03 (MODIFY)**: Khóa cứng bản công thức đã chốt (`Immutability`), bắt buộc tạo bản sửa đổi để sinh phiên bản mới.
4. **DEC-04 (REJECT)**: Không cho phép AI tự động ghi đè định lượng; áp dụng mô hình Human-in-the-loop với xác nhận tường minh.
5. **DEC-05 (ACCEPT)**: Tích hợp tính năng gom nhiều công thức xuất chung 1 file PDF SOP có Trang bìa và Mục lục.
6. **DEC-06 (ACCEPT)**: Bổ sung màn hình Loading chuyển cảnh (SCR-19) và màn hình Error phục hồi ngoại tuyến (SCR-20).
7. **DEC-07 (ACCEPT)**: Kiến trúc điều hướng 3 Hàng (3-Row Flow Architecture: Staff R&D, Barista Viewer, Admin Console) giúp cách ly vai trò và tối ưu trải nghiệm.
8. **DEC-08 (ACCEPT)**: Trải nghiệm đọc sổ tay SOP E-Booklet chân thực (SCR-17a `BookletReaderPage`) với gáy sách 3D, thanh trượt 8 trang, TOC drawer và watermark bản nháp 45 độ.
9. **DEC-09 (ACCEPT)**: Quy trình trích xuất nút/UI mobile lên Figma làm Master Components và kịch bản demo native 100% không dùng trình duyệt web.
