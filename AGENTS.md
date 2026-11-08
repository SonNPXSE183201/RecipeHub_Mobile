# Hướng dẫn cho agent (RecipeHub Mobile – PRM393)

- Giao tiếp tiếng Việt, ngắn gọn; giữ nguyên thuật ngữ, code, lệnh.
- Flutter MVVM + Provider: widget không gọi SDK trực tiếp; logic ở ViewModel/Service có interface; mỗi màn tải dữ liệu có state loading/empty/error.
- Token giao diện ở `lib/core/theme/nomad_kit.dart`; không viết cứng màu/cỡ chữ mới trong màn.
- Dữ liệu thật trên Firestore; không thêm mock data vào `lib/` (bản giả chỉ dùng trong test).
- UI không hiện id/mã kỹ thuật thô (kể cả mã món trên mobile).
- Không commit secret: `google-services.json`, file env, keystore. Không commit/push khi chưa được chủ repo cho phép.
- Trước khi báo xong: `flutter analyze` 0 issue, `flutter test` pass.
