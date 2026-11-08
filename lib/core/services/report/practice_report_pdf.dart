import 'dart:convert';
import 'dart:typed_data';

import '../../models/app_models.dart';

/// Sinh PDF báo cáo tự luyện (thuần Dart, không phụ thuộc package ngoài).
///
/// Font chuẩn PDF (Helvetica / WinAnsi) không có dấu tiếng Việt nên nội dung được
/// chuyển sang không dấu – đủ cho mục đích báo cáo nội bộ & kiểm chứng Storage.
class PracticeReportPdf {
  PracticeReportPdf._();

  static Uint8List build({
    required String storeLabel,
    required String traineeLabel,
    required List<SelfPracticeRecord> records,
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    final lines = <_Line>[
      _Line('RecipeHub - Bao cao tu luyen quay bar', 18, bold: true),
      _Line('PRM393 Lab 3 - Firebase Cloud Storage', 10),
      _Line('', 8),
      _Line('Chi nhanh: ${_ascii(storeLabel)}', 11),
      _Line('Nhan vien: ${_ascii(traineeLabel)}', 11),
      _Line('Thoi diem xuat: ${_fmt(now)}', 11),
      _Line('So lan luyen: ${records.length}', 11),
      _Line('', 8),
      _Line('Ma mon        Size      Thuc te   Chuan   Sai so   Ngay', 10, bold: true),
    ];
    for (final r in records.take(30)) {
      final dev = r.targetSeconds == 0 ? '-' : '${r.deviationSeconds >= 0 ? '+' : ''}${r.deviationSeconds}s';
      lines.add(_Line(
        '${_pad(r.recipeCode, 14)}${_pad(_ascii(r.size).split(' (').first, 10)}'
        '${_pad('${r.durationSeconds}s', 10)}${_pad(r.targetSeconds == 0 ? '-' : '${r.targetSeconds}s', 8)}'
        '${_pad(dev, 9)}${_ascii(r.practicedAt)}',
        10,
      ));
      if (r.notes.isNotEmpty) lines.add(_Line('   Ghi chu: ${_ascii(r.notes)}', 9));
    }
    lines
      ..add(_Line('', 8))
      ..add(_Line('BR-09: Sai so thoi gian chi de tu tham khao, khong dung de cham thuc hanh.', 9))
      ..add(_Line('Tai lieu noi bo - chi chu so huu UID duoc doc (storage.rules).', 9));
    return _render(lines);
  }

  static String _pad(String s, int n) => s.length >= n ? '${s.substring(0, n - 1)} ' : s.padRight(n);

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static const String _vi = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
      'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
  static const String _en = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
      'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

  /// Bỏ dấu tiếng Việt + loại ký tự ngoài ASCII in được.
  static String _ascii(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final i = _vi.indexOf(ch);
      if (i >= 0) {
        sb.write(_en[i]);
      } else if (rune >= 32 && rune < 127) {
        sb.write(ch);
      } else if (ch == '·' || ch == '–' || ch == '—') {
        sb.write('-');
      } else if (ch == '°') {
        sb.write(' do ');
      }
    }
    return sb.toString();
  }

  static String _escape(String s) => s.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

  static Uint8List _render(List<_Line> lines) {
    final content = StringBuffer()..write('BT\n');
    var y = 800.0;
    for (final l in lines) {
      y -= l.size + 6;
      content.write('/${l.bold ? 'F2' : 'F1'} ${l.size} Tf\n1 0 0 1 48 ${y.toStringAsFixed(1)} Tm\n(${_escape(l.text)}) Tj\n');
    }
    content.write('ET\n');
    final stream = content.toString();

    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
          '/Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>',
      '<< /Length ${latin1.encode(stream).length} >>\nstream\n${stream}endstream',
    ];

    final out = BytesBuilder();
    final offsets = <int>[];
    void write(String s) => out.add(latin1.encode(s));
    write('%PDF-1.4\n');
    for (var i = 0; i < objects.length; i++) {
      offsets.add(out.length);
      write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }
    final xref = out.length;
    write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
    for (final o in offsets) {
      write('${o.toString().padLeft(10, '0')} 00000 n \n');
    }
    write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n');
    return out.toBytes();
  }
}

class _Line {
  _Line(this.text, this.size, {this.bold = false});

  final String text;
  final double size;
  final bool bold;
}
