import 'package:uuid/uuid.dart';

/// Sự cố gửi lên Firestore `incidents/` để web Admin thấy ngay (Crashlytics vẫn nhận song song).
enum IncidentKind { fatal, nonFatal }

/// Nguồn phát sinh sự cố – khớp danh sách cho phép trong firestore.rules.
enum IncidentSource { demoButton, flutterError, platformError, previousCrash, nonFatalReport }

class IncidentReport {
  IncidentReport({
    String? id,
    required this.kind,
    required this.source,
    required this.message,
    this.errorType,
    this.stackTop,
    this.screen,
    this.occurredAt,
  }) : id = id ?? const Uuid().v4();

  /// Id do client tạo = id document Firestore → ghi lại (gửi bù, hàng đợi offline) không tạo bản trùng.
  final String id;
  final IncidentKind kind;
  final IncidentSource source;
  final String message;
  final String? errorType;
  final String? stackTop;
  final String? screen;
  final DateTime? occurredAt;

  static const int maxMessage = 500;
  static const int maxStack = 2000;
  static const int maxErrorType = 120;
  static const int maxScreen = 80;

  String get kindCode => kind == IncidentKind.fatal ? 'fatal' : 'non_fatal';

  String get sourceCode => switch (source) {
        IncidentSource.demoButton => 'demo_button',
        IncidentSource.flutterError => 'flutter_error',
        IncidentSource.platformError => 'platform_error',
        IncidentSource.previousCrash => 'previous_crash',
        IncidentSource.nonFatalReport => 'non_fatal_report',
      };

  /// Tạo từ một lỗi bất kỳ, cắt độ dài theo rules.
  factory IncidentReport.fromError(
    Object error,
    StackTrace? stack, {
    required IncidentKind kind,
    required IncidentSource source,
    String? screen,
  }) {
    final lines = (stack?.toString() ?? '').split('\n').where((l) => l.trim().isNotEmpty).take(10).join('\n');
    return IncidentReport(
      kind: kind,
      source: source,
      errorType: _cut(error.runtimeType.toString(), maxErrorType),
      message: _cut(error.toString(), maxMessage),
      stackTop: lines.isEmpty ? null : _cut(lines, maxStack),
      screen: screen == null ? null : _cut(screen, maxScreen),
      occurredAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kindCode,
        'source': sourceCode,
        'message': _cut(message, maxMessage),
        'errorType': errorType,
        'stackTop': stackTop,
        'screen': screen,
        'occurredAt': (occurredAt ?? DateTime.now()).toIso8601String(),
      };

  static IncidentReport fromJson(Map<String, dynamic> j) => IncidentReport(
        id: j['id'] as String?,
        kind: j['kind'] == 'fatal' ? IncidentKind.fatal : IncidentKind.nonFatal,
        source: IncidentSource.values.firstWhere(
          (s) => IncidentReport(kind: IncidentKind.fatal, source: s, message: '').sourceCode == j['source'],
          orElse: () => IncidentSource.previousCrash,
        ),
        message: j['message'] as String? ?? '',
        errorType: j['errorType'] as String?,
        stackTop: j['stackTop'] as String?,
        screen: j['screen'] as String?,
        occurredAt: DateTime.tryParse(j['occurredAt'] as String? ?? ''),
      );

  static String _cut(String s, int max) => s.length <= max ? s : s.substring(0, max);
}
