import '../interfaces/i_device_registry.dart';

/// Bản giả: ghi lại thao tác để test kiểm tra thứ tự.
class MockDeviceRegistry implements IDeviceRegistry {
  final List<String> log = [];
  final Set<String> registered = {};

  @override
  Future<void> register(String uid, String token) async {
    log.add('register:$uid:$token');
    registered.add(token);
  }

  @override
  Future<void> unregister(String uid, String token) async {
    log.add('unregister:$uid:$token');
    registered.remove(token);
  }
}
