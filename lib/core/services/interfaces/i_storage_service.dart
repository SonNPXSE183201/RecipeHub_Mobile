import 'dart:typed_data';

import '../../models/session_models.dart';

/// Tiến độ upload (0.0 → 1.0).
typedef UploadProgressCallback = void Function(double progress);

/// Firebase Cloud Storage boundary.
///
/// Cấu trúc thư mục (khớp `firebase/storage.rules`):
/// - `feedback/{uid}/{timestamp}_{file}` – ảnh minh chứng ≤ 5MB, chỉ `image/*`
/// - `reports/{uid}/{timestamp}_{file}.pdf` – báo cáo PDF, chỉ chủ sở hữu đọc/ghi
/// - `sop/{code}.pdf` – tài liệu SOP (đọc khi đã đăng nhập)
abstract class IStorageService {
  static const int maxImageBytes = 5 * 1024 * 1024;

  /// Tải ảnh feedback. Throws [StorageFailure].
  Future<UploadResult> uploadFeedbackImage({
    required String uid,
    required PickedMedia media,
    UploadProgressCallback? onProgress,
  });

  /// Tải báo cáo PDF lên `reports/{uid}/…`. Throws [StorageFailure].
  Future<UploadResult> uploadReportPdf({
    required String uid,
    required Uint8List bytes,
    required String fileName,
    UploadProgressCallback? onProgress,
  });

  /// Lấy URL tải tài liệu SOP PDF (`sop/{code}.pdf`). Trả `null` nếu chưa có file.
  Future<String?> getSopDocumentUrl(String sopCode);

  /// Hủy upload đang chạy (nếu có).
  Future<void> cancelActiveUpload();
}
