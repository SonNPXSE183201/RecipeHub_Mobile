import '../../models/session_models.dart';

/// Chọn ảnh từ camera / thư viện (image_picker) – tách interface để test không cần thiết bị.
abstract class IMediaPickerService {
  /// Trả `null` nếu người dùng hủy.
  Future<PickedMedia?> pickImage({required bool fromCamera});
}
