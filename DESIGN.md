# NomadKit Design System (RecipeHub Mobile)

Figma: https://www.figma.com/design/FycUpbP0PtH6Q4sg6IvZr6/RecipeHub (key `FycUpbP0PtH6Q4sg6IvZr6`).
Nguồn token trong code: `lib/core/theme/nomad_kit.dart`.

## 1. Tổng quan
NomadKit là bộ giao diện ấm, tương phản cao cho quầy bar chuỗi cà phê và trà sữa. Nền kem `#FFFDF7`, thẻ trắng, nhấn vàng cát `#C49A6C`.
Ứng dụng có 2 vai trò:
1. **Barista (Viewer)**: tra cứu công thức theo size, xem video từng bước, đọc SOP, học và làm quiz, tự luyện bấm giờ, gửi phản hồi.
2. **Quản lý cửa hàng (Admin)**: theo dõi tiến độ đào tạo nhân viên chi nhánh, chấm thực hành tại quầy, trao đổi phản hồi với barista.

## 2. Màu (khớp `NomadKit`)
| Token | Hex | Dùng cho |
| :--- | :--- | :--- |
| `sand` | `#C49A6C` | Nhấn chính, logo, nút chính |
| `sandDark` | `#A07040` | Nhãn mục, trạng thái nhấn |
| `sandLight` | `#FAF6F0` | Nền thẻ nhấn, lối tắt |
| `ocean` / `oceanLight` | `#0891B2` / `#F0F9FF` | Thông tin, liên kết |
| `forest` / `forestLight` | `#166534` / `#DCFCE7` | Đã duyệt, hoàn thành |
| `warning` / `warningLight` | `#CA8A04` / `#FEF9C3` | Bản nháp, sắp hạn |
| `error` | `#DC2626` | Lỗi, quá hạn |
| `ink` | `#292524` | Chữ chính |
| `secondary` | `#78716C` | Chữ phụ |
| `canvas` | `#FFFDF7` | Nền ứng dụng |
| `surface` | `#FFFFFF` | Thẻ, hộp thoại |
| `border` | `#E7E0D5` | Viền 1 dp |

## 3. Chữ, khoảng cách, bo góc
- Chữ hệ thống sans-serif; thân 14–15 sp, hướng dẫn ở quầy 18–22 sp; mã/số dùng monospace.
- Khoảng cách bội số 4 dp, lề ngang 16 dp.
- Bo góc: 4 (badge), 8 (ô nhập), 14 (thẻ), 16 (nút, hộp thoại), pill (chip).
- Vùng chạm tối thiểu 48 dp, nút chính 52 dp.

## 4. Logo và icon
- Logo: squircle vàng cát với tách cà phê trắng, file `assets/icons/app_logo_hero_2k.png`, hiển thị qua `RecipeHubLogo` (có icon dự phòng khi thiếu ảnh).
- Icon nghiệp vụ và icon tab dưới là PNG trong `assets/icons/` (`nav_*` có bản `_active`); ảnh minh họa trạng thái trống, lỗi, huy hiệu ở `assets/illustrations/`.
- Quy tắc: chỉ giữ ảnh có tham chiếu trong `lib/`. Thêm ảnh mới thì thêm tham chiếu, ảnh không còn dùng thì xóa.
- Không dùng emoji; icon hệ thống còn lại là Material Icons.

## 5. Thành phần
- **Thanh trên**: logo, tên thương hiệu, chuông thông báo (`NotificationsPage`).
- **Thanh dưới**: 4 tab trong `MainAppShell`: Tra cứu, Việc học (Barista) hoặc Đào tạo (Admin), Phản hồi, Tài khoản.
- **Chọn size S/M/L**: định lượng đổi theo size trong `RecipeDetailSizePage`.
- **Chip trạng thái**: Đang học, Quá hạn, Cần học lại, Hoàn thành; phản hồi Mới, Đang xử lý, Chờ thêm thông tin, Đã giải quyết, Đã đóng.
- **Màn hình hệ thống**: `LoadingTransitionPage`, `ErrorRecoveryPage`.
