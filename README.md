# recipehub_mobile

Ứng dụng Flutter RecipeHub dùng NomadKit; gồm giao diện R&D, Viewer và Admin. Xem [design](DESIGN.md) và [handoff](flutter-handoff.md).

## Getting Started

Mã nguồn hiện kết hợp API Recipe/Content với màn hình demo. `LoginPage` chỉ điều hướng theo email, chưa xác thực Identity; Ping trong cấu hình AI gọi Gateway health và có nhánh giả lập thành công khi lỗi, không chứng minh Gemini hoạt động. Không dùng các màn hình này làm bằng chứng nghiệm thu backend hoặc phân quyền.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
