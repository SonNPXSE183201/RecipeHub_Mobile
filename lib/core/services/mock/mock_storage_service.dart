import 'dart:typed_data';

import '../../models/session_models.dart';
import '../interfaces/i_storage_service.dart';

/// Storage giả lập: phát tiến độ 0 → 100% và trả URL giả có đúng cấu trúc thư mục.
class MockStorageService implements IStorageService {
  MockStorageService({this.failNext});

  StorageFailure? failNext;
  final List<String> uploadedPaths = [];

  Future<UploadResult> _fakeUpload(String path, int size, UploadProgressCallback? onProgress) async {
    final failure = failNext;
    for (final p in const [0.0, 0.25, 0.5, 0.75]) {
      onProgress?.call(p);
      await Future<void>.delayed(Duration.zero);
    }
    if (failure != null) {
      failNext = null;
      throw failure;
    }
    onProgress?.call(1.0);
    uploadedPaths.add(path);
    final encoded = Uri.encodeComponent(path);
    return UploadResult(
      storagePath: path,
      downloadUrl: 'https://firebasestorage.googleapis.com/v0/b/recipehub-mock.appspot.com/o/$encoded?alt=media',
      sizeBytes: size,
    );
  }

  @override
  Future<UploadResult> uploadFeedbackImage({
    required String uid,
    required PickedMedia media,
    UploadProgressCallback? onProgress,
  }) {
    if (!media.isImage) throw const StorageFailure(StorageFailureCode.invalidType);
    if (media.sizeBytes > IStorageService.maxImageBytes) {
      throw const StorageFailure(StorageFailureCode.tooLarge);
    }
    final path = 'feedback/$uid/${DateTime.now().millisecondsSinceEpoch}_${media.fileName}';
    return _fakeUpload(path, media.sizeBytes, onProgress);
  }

  @override
  Future<UploadResult> uploadReportPdf({
    required String uid,
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) {
    final path = 'reports/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return _fakeUpload(path, bytes.lengthInBytes, onProgress);
  }

  @override
  Future<String?> getSopDocumentUrl(String sopCode) async =>
      'https://firebasestorage.googleapis.com/v0/b/recipehub-mock.appspot.com/o/sop%2F$sopCode.pdf?alt=media';

  @override
  Future<void> cancelActiveUpload() async {}
}
