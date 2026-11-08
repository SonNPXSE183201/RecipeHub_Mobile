import 'package:image_picker/image_picker.dart';

import '../../models/session_models.dart';
import '../interfaces/i_media_picker_service.dart';

/// Chọn ảnh bằng image_picker (camera / gallery), nén nhẹ để dưới 5MB.
class ImagePickerMediaService implements IMediaPickerService {
  ImagePickerMediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  @override
  Future<PickedMedia?> pickImage({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedMedia(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType ?? _guessMime(file.name),
    );
  }
}
