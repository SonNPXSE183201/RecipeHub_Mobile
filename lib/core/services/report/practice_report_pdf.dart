import 'dart:typed_data';

import '../../models/app_models.dart';
import 'report_document.dart';

class PracticeReportPdf {
  PracticeReportPdf._();

  static String fileName([DateTime? at]) {
    final t = at ?? DateTime.now();
    return 'luyen-tap_${dateStamp(t)}-${two(t.hour)}${two(t.minute)}.pdf';
  }

  static String two(int v) => v.toString().padLeft(2, '0');
  static String dateStamp(DateTime t) =>
      '${t.year}${two(t.month)}${two(t.day)}';
  static String dateLabel(DateTime t) =>
      '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';

  /// Pure builder: caller loads font once; every record is exported.
  static Uint8List build({
    required Uint8List fontBytes,
    required String storeLabel,
    required String traineeLabel,
    required List<SelfPracticeRecord> records,
    DateTime? generatedAt,
  }) {
    final pdf = ReportDocument(fontBytes, title: 'Lịch sử tự luyện cá nhân');
    pdf.page('Lịch sử tự luyện cá nhân');
    pdf.paragraph('Nhân viên: ${_label(traineeLabel)}');
    pdf.paragraph('Chi nhánh: ${_label(storeLabel)}');
    pdf.paragraph('Ngày xuất: ${dateLabel(generatedAt ?? DateTime.now())}');
    final timed = records.where((r) => r.targetSeconds > 0).toList();
    final passed = timed
        .where((r) => r.durationSeconds <= r.targetSeconds)
        .length;
    final rate = timed.isEmpty
        ? 'Chưa có chuẩn'
        : '${(100 * passed / timed.length).toStringAsFixed(0)}%';
    final average = records.isEmpty
        ? '—'
        : '${(records.fold<int>(0, (s, r) => s + r.durationSeconds) / records.length).round()} giây';
    final counts = <String, int>{};
    for (final r in records) {
      final name = _label(r.recipeName);
      counts.update(name, (v) => v + 1, ifAbsent: () => 1);
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        return count == 0 ? a.key.compareTo(b.key) : count;
      });
    pdf.table(
      [
        'Tổng lượt',
        'Đạt chuẩn',
        'Thời gian trung bình',
        'Món luyện nhiều nhất',
      ],
      [
        [
          '${records.length}',
          rate,
          average,
          ranked.isEmpty ? '—' : ranked.first.key,
        ],
      ],
      [80, 90, 140, 205.28],
    );
    pdf.paragraph(
      'Đạt chuẩn: thời gian thực tế ≤ chuẩn; chỉ tính lượt có chuẩn. Sai lệch thời gian chỉ để tự tham khảo, không dùng chấm thực hành (BR-09).',
      size: 9,
    );
    if (records.isEmpty) pdf.paragraph('Chưa có lượt tự luyện.');
    pdf.table(
      ['Ngày giờ', 'Món', 'Size', 'Thời gian', 'Chuẩn', 'Lệch', 'Ghi chú'],
      [
        for (final r in records)
          [
            _date(r.practicedAt),
            _label(r.recipeName),
            r.size,
            '${r.durationSeconds}s',
            r.targetSeconds > 0 ? '${r.targetSeconds}s' : '—',
            r.targetSeconds > 0
                ? '${r.deviationSeconds >= 0 ? '+' : ''}${r.deviationSeconds}s'
                : '—',
            r.notes.isEmpty ? '—' : r.notes,
          ],
      ],
      [76, 115, 42, 52, 46, 46, 138.28],
    );
    return pdf.save(source: 'Nguồn: lịch sử tự luyện cá nhân · RecipeHub');
  }

  static String _label(String value) =>
      value.trim().isEmpty ? 'Chưa cập nhật' : value;
  static String _date(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : dateLabel(parsed.toLocal());
  }
}
