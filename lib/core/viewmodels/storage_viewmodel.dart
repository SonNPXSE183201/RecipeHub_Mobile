import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../models/session_models.dart';
import '../services/interfaces/i_analytics_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_crash_reporter.dart';
import '../services/interfaces/i_media_picker_service.dart';
import '../services/interfaces/i_storage_service.dart';
import '../services/report/practice_report_pdf.dart';

/// Upload ảnh feedback (M-11) + xuất báo cáo PDF (M-19) lên Firebase Storage.
class StorageViewModel extends ChangeNotifier {
  StorageViewModel({
    required this._storage,
    required this._picker,
    required this._auth,
    required this._analytics,
    required this._crash,
  });

  final IStorageService _storage;
  final IMediaPickerService _picker;
  final IAuthService _auth;
  final IAnalyticsService _analytics;
  final ICrashReporter _crash;
  bool _disposed = false;

  // ── Feedback attachment ──
  PickedMedia? _attachment;
  UploadStatus _attachmentStatus = UploadStatus.idle;
  double _attachmentProgress = 0;
  UploadResult? _attachmentResult;
  String? _attachmentError;

  PickedMedia? get attachment => _attachment;
  UploadStatus get attachmentStatus => _attachmentStatus;
  double get attachmentProgress => _attachmentProgress;
  String? get attachmentUrl => _attachmentResult?.downloadUrl;
  String? get attachmentPath => _attachmentResult?.storagePath;
  String? get attachmentError => _attachmentError;
  bool get isUploadingAttachment => _attachmentStatus == UploadStatus.uploading;

  Future<void> pickAttachment({required bool fromCamera}) async {
    _attachmentError = null;
    _attachmentStatus = UploadStatus.validating;
    _notify();
    try {
      final media = await _picker.pickImage(fromCamera: fromCamera);
      if (media == null) {
        _attachmentStatus = _attachmentResult != null ? UploadStatus.success : UploadStatus.idle;
        _notify();
        return;
      }
      if (!media.isImage) {
        _setAttachmentError(const StorageFailure(StorageFailureCode.invalidType).userMessage);
        return;
      }
      if (media.sizeBytes >= IStorageService.maxImageBytes) {
        _setAttachmentError(const StorageFailure(StorageFailureCode.tooLarge).userMessage);
        return;
      }
      _attachment = media;
      _attachmentResult = null;
      _attachmentProgress = 0;
      _attachmentStatus = UploadStatus.idle;
      _notify();
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'media_pick');
      _setAttachmentError('Không mở được camera/thư viện ảnh.');
    }
  }

  void _setAttachmentError(String message) {
    _attachmentError = message;
    _attachmentStatus = UploadStatus.error;
    _notify();
  }

  /// Upload ảnh đang chọn → trả download URL (hoặc null nếu lỗi).
  Future<String?> uploadAttachment() async {
    final media = _attachment;
    if (media == null) return null;
    if (_attachmentResult != null) return _attachmentResult!.downloadUrl;
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _setAttachmentError(const StorageFailure(StorageFailureCode.unauthorized).userMessage);
      return null;
    }
    _attachmentStatus = UploadStatus.uploading;
    _attachmentProgress = 0;
    _attachmentError = null;
    _notify();
    try {
      final result = await _storage.uploadFeedbackImage(
        uid: uid,
        media: media,
        onProgress: (p) {
          _attachmentProgress = p;
          _notify();
        },
      );
      _attachmentResult = result;
      _attachmentStatus = UploadStatus.success;
      _attachmentProgress = 1;
      _notify();
      return result.downloadUrl;
    } on StorageFailure catch (f, s) {
      if (f.code != StorageFailureCode.cancelled) {
        await _crash.recordError(f, s, reason: 'storage_upload_feedback');
      }
      _setAttachmentError(f.userMessage);
      return null;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'storage_upload_feedback');
      _setAttachmentError(const StorageFailure(StorageFailureCode.unknown).userMessage);
      return null;
    }
  }

  Future<void> cancelUpload() => _storage.cancelActiveUpload();

  void clearAttachment() {
    _attachment = null;
    _attachmentResult = null;
    _attachmentError = null;
    _attachmentProgress = 0;
    _attachmentStatus = UploadStatus.idle;
    _notify();
  }

  // ── Report PDF ──
  UploadStatus _reportStatus = UploadStatus.idle;
  double _reportProgress = 0;
  String? _reportError;
  final List<UploadResult> _reports = [];
  int _lastReportBytes = 0;

  UploadStatus get reportStatus => _reportStatus;
  double get reportProgress => _reportProgress;
  String? get reportError => _reportError;
  List<UploadResult> get reports => List.unmodifiable(_reports);
  UploadResult? get lastReport => _reports.isEmpty ? null : _reports.first;
  int get lastReportBytes => _lastReportBytes;

  Future<UploadResult?> exportPracticeReport({
    required List<SelfPracticeRecord> records,
    required String traineeLabel,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _reportError = const StorageFailure(StorageFailureCode.unauthorized).userMessage;
      _reportStatus = UploadStatus.error;
      _notify();
      return null;
    }
    _reportStatus = UploadStatus.uploading;
    _reportProgress = 0;
    _reportError = null;
    _notify();
    try {
      final bytes = PracticeReportPdf.build(
        storeLabel: AppConfig.storeBranch,
        traineeLabel: traineeLabel,
        records: records,
      );
      _lastReportBytes = bytes.lengthInBytes;
      final result = await _storage.uploadReportPdf(
        uid: uid,
        bytes: bytes,
        fileName: 'practice_report.pdf',
        onProgress: (p) {
          _reportProgress = p;
          _notify();
        },
      );
      _reports.insert(0, result);
      _reportStatus = UploadStatus.success;
      _reportProgress = 1;
      _notify();
      await _analytics.logExportReportPdf(
        reportType: 'practice_history',
        recordCount: records.length,
        fileSizeKb: (bytes.lengthInBytes / 1024).ceil(),
      );
      return result;
    } on StorageFailure catch (f, s) {
      await _crash.recordError(f, s, reason: 'storage_upload_report');
      _reportError = f.userMessage;
      _reportStatus = UploadStatus.error;
      _notify();
      return null;
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'storage_upload_report');
      _reportError = const StorageFailure(StorageFailureCode.unknown).userMessage;
      _reportStatus = UploadStatus.error;
      _notify();
      return null;
    }
  }

  /// URL tài liệu SOP PDF trên Storage (`sop/{code}.pdf`).
  Future<String?> sopDocumentUrl(String code) async {
    try {
      return await _storage.getSopDocumentUrl(code);
    } catch (e, s) {
      await _crash.recordError(e, s, reason: 'storage_sop_url');
      return null;
    }
  }

  void reset() {
    clearAttachment();
    _reports.clear();
    _reportStatus = UploadStatus.idle;
    _reportProgress = 0;
    _reportError = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
