/// Lưu FCM token của máy này lên Firestore `users/{uid}/devices/{id}` để server gửi đúng người.
///
/// Token do FCM cấp cho từng cặp (app, máy); đổi khi cài lại app / xóa dữ liệu → `onTokenRefresh`.
abstract class IDeviceRegistry {
  Future<void> register(String uid, String token);

  Future<void> unregister(String uid, String token);
}
