import 'dart:typed_data';

import '../../models/app_models.dart';
import 'practice_report_pdf.dart';
import 'report_document.dart';

class SopBookPdf {
  static String fileName([DateTime? at]) =>
      'so-tay-cong-thuc_${PracticeReportPdf.dateStamp(at ?? DateTime.now())}.pdf';

  static Uint8List build({
    required Uint8List fontBytes,
    required List<RecipeItem> recipes,
    required List<SopItem> sops,
    required DateTime generatedAt,
  }) {
    // Iterate layout until TOC page numbers settle (long titles/recipes wrap).
    var starts = <int>[];
    late ReportDocument pdf;
    while (true) {
      pdf = ReportDocument(fontBytes, title: 'Sổ tay công thức & SOP');
      pdf.page('Sổ tay công thức & SOP');
      pdf.y += 110;
      pdf.paragraph('CẨM NANG TẠI QUẦY', size: 24);
      pdf.paragraph('${recipes.length} món · ${sops.length} SOP', size: 16);
      pdf.paragraph('Ngày xuất: ${PracticeReportPdf.dateLabel(generatedAt)}');
      pdf.paragraph(
        'Nguồn: công thức và SOP đã ban hành trên RecipeHub.\n'
        'Đối chiếu phiên bản mới nhất trên ứng dụng trước khi phục vụ.',
      );
      pdf.page('Mục lục');
      final titles = [
        ...recipes.map((r) => r.name),
        ...sops.map((s) => 'SOP · ${s.title}'),
      ];
      pdf.table(
        ['Nội dung', 'Trang'],
        [
          for (var i = 0; i < titles.length; i++)
            [titles[i], starts.length == titles.length ? '${starts[i]}' : '—'],
        ],
        [455.28, 60],
      );
      final actual = <int>[];
      for (final r in recipes) {
        actual.add(pdf.pageCount + 1);
        _recipe(pdf, r);
      }
      for (final s in sops) {
        actual.add(pdf.pageCount + 1);
        pdf.page(s.title);
        pdf.paragraph('SOP · ${s.category} · Phiên bản ${s.version}');
        pdf.paragraph(s.summary);
        for (final step in s.steps) {
          pdf.paragraph('${step.stepNumber}. ${step.title}', size: 12);
          pdf.paragraph(step.content, continuation: s.title);
          if (step.note?.isNotEmpty == true) {
            pdf.paragraph('Lưu ý: ${step.note}');
          }
        }
      }
      if (_same(starts, actual)) break;
      starts = actual;
    }
    return pdf.save(source: 'Nguồn: công thức & SOP đã ban hành · RecipeHub');
  }

  static bool _same(List<int> a, List<int> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

  static void _recipe(ReportDocument pdf, RecipeItem r) {
    pdf.page(r.name);
    pdf.paragraph('${r.category} · Phiên bản ${r.version}');
    pdf.paragraph(r.description);
    pdf.paragraph(
      'Thời gian chuẩn: ${r.standardTime} · Nhiệt độ: ${r.standardTemp}',
    );
    pdf.paragraph('Định lượng theo size', size: 12);
    // Match name + unit, preserving multiple portions/notes rather than dropping
    // duplicate ingredient entries or confusing g and ml.
    final keys = <(String, String)>{
      for (final s in r.sizes)
        for (final i in s.ingredients) (i.name, i.unit),
    };
    // Very wide size sets are split into column groups to remain readable.
    for (var offset = 0; offset < r.sizes.length; offset += 4) {
      final sizes = r.sizes.skip(offset).take(4).toList();
      final sizeWidth = (ReportDocument.width - 175) / sizes.length;
      pdf.table(
        ['Nguyên liệu', ...sizes.map((s) => s.label)],
        [
          for (final key in keys)
            [
              key.$1,
              for (final s in sizes)
                s.ingredients
                    .where((i) => i.name == key.$1 && i.unit == key.$2)
                    .map(
                      (i) =>
                          '${_number(i.amount)} ${i.unit}'
                          '${i.note?.isNotEmpty == true ? '\n${i.note}' : ''}'
                          '${i.warning?.isNotEmpty == true ? '\nLưu ý: ${i.warning}' : ''}',
                    )
                    .join('\n'),
            ],
        ],
        [175, ...sizes.map((_) => sizeWidth)],
      );
    }
    if (r.sizes.isEmpty) pdf.paragraph('Chưa cập nhật định lượng.');
    pdf.paragraph('Phục vụ / yêu cầu đặc biệt', size: 12);
    for (final s in r.sizes) {
      if (s.servingNotes.isNotEmpty) {
        pdf.paragraph('${s.label}: ${s.servingNotes}');
      }
    }
    pdf.paragraph('Các bước thực hiện', size: 12);
    for (final step in r.steps) {
      pdf.paragraph('${step.stepNumber}. ${step.title}', size: 12);
      pdf.paragraph(step.instruction, continuation: r.name);
      final details = [
        if (step.temperature?.isNotEmpty == true)
          'Nhiệt độ: ${step.temperature}',
        if (step.durationText?.isNotEmpty == true)
          'Thời gian: ${step.durationText}',
      ];
      if (details.isNotEmpty) pdf.paragraph(details.join(' · '));
    }
  }

  static String _number(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}' : '$v';
}
