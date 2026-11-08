import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../models/session_models.dart';
import '../interfaces/i_storage_service.dart';

/// Firebase Cloud Storage – putData + snapshotEvents (progress) + getDownloadURL.
class FirebaseStorageService implements IStorageService {
  FirebaseStorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;
  UploadTask? _active;

  static StorageFailure _mapError(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'unauthenticated':
        return StorageFailure(StorageFailureCode.unauthorized, e.message);
      case 'canceled':
        return StorageFailure(StorageFailureCode.cancelled, e.message);
      case 'retry-limit-exceeded':
        return StorageFailure(StorageFailureCode.network, e.message);
      default:
        final msg = (e.message ?? '').toLowerCase();
        if (msg.contains('network') || msg.contains('host') || msg.contains('timeout')) {
          return StorageFailure(StorageFailureCode.network, e.message);
        }
        return StorageFailure(StorageFailureCode.unknown, '${e.code}: ${e.message}');
    }
  }

  Future<UploadResult> _put(
    String path,
    Uint8List bytes,
    String contentType,
    UploadProgressCallback? onProgress,
  ) async {
    final ref = _storage.ref(path);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: const {'app': 'recipehub_mobile', 'lab': 'prm393_lab3'},
      ),
    );
    _active = task;
    final sub = task.snapshotEvents.listen(
      (snap) {
        if (snap.totalBytes > 0) onProgress?.call(snap.bytesTransferred / snap.totalBytes);
      },
      onError: (Object _) {},
    );
    try {
      final snapshot = await task;
      onProgress?.call(1.0);
      final url = await snapshot.ref.getDownloadURL();
      return UploadResult(storagePath: path, downloadUrl: url, sizeBytes: bytes.lengthInBytes);
    } on FirebaseException catch (e) {
      throw _mapError(e);
    } finally {
      await sub.cancel();
      _active = null;
    }
  }

  @override
  Future<UploadResult> uploadFeedbackImage({
    required String uid,
    required PickedMedia media,
    UploadProgressCallback? onProgress,
  }) async {
    if (!media.isImage) throw const StorageFailure(StorageFailureCode.invalidType);
    if (media.sizeBytes > IStorageService.maxImageBytes) {
      throw const StorageFailure(StorageFailureCode.tooLarge);
    }
    final safeName = media.fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'feedback/$uid/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    return _put(path, media.bytes, media.mimeType, onProgress);
  }

  @override
  Future<UploadResult> uploadReportPdf({
    required String uid,
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  }) {
    final path = 'reports/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return _put(path, bytes, 'application/pdf', onProgress);
  }

  @override
  Future<String?> getSopDocumentUrl(String sopCode) async {
    try {
      return await _storage.ref('sop/$sopCode.pdf').getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      throw _mapError(e);
    }
  }

  @override
  Future<void> cancelActiveUpload() async {
    await _active?.cancel();
  }
}
