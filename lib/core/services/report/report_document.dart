import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Minimal A4 PDF writer. Embeds the existing Unicode TrueType font, including
/// ToUnicode mappings for searching/copying Vietnamese text. No network/fonts API.
class ReportDocument {
  ReportDocument(Uint8List fontBytes, {required this.title})
    : _font = _TrueType(fontBytes);

  final String title;
  final _TrueType _font;
  final List<StringBuffer> _pages = [];
  final Set<int> _used = {};
  double y = 40;
  static const width = 515.28;
  static const bottom = 770.0;
  int get pageCount => _pages.length;
  StringBuffer get _out => _pages.last;

  void page(String heading) {
    _pages.add(StringBuffer());
    y = 40;
    rect(40, y, width, 7, sand: true);
    y += 23;
    text('RecipeHub', 40, y, size: 15);
    y += 27;
    paragraph(heading, size: 21);
  }

  void rect(double x, double top, double w, double h, {bool sand = false}) {
    _out.writeln(
      'q ${sand ? '0.769 0.604 0.424' : '0.980 0.965 0.941'} rg '
      '$x ${841.89 - top - h} $w $h re f Q',
    );
  }

  void text(String value, double x, double top, {double size = 10}) {
    final codes = value.runes.map((r) => r <= 65535 ? r : 63).toList();
    _used.addAll(codes);
    final hex = codes.map((r) => r.toRadixString(16).padLeft(4, '0')).join();
    _out.writeln(
      'BT /F1 $size Tf 0.161 0.145 0.141 rg '
      '1 0 0 1 $x ${841.89 - top - size} Tm <$hex> Tj ET',
    );
  }

  List<String> wrap(String value, double w, double size) {
    final result = <String>[];
    for (final line in value.replaceAll('\r', '').split('\n')) {
      var current = '';
      for (final word in line.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        final candidate = current.isEmpty ? word : '$current $word';
        if (_font.measure(candidate, size) <= w) {
          current = candidate;
          continue;
        }
        if (current.isNotEmpty) result.add(current);
        current = '';
        for (final rune in word.runes) {
          final ch = String.fromCharCode(rune);
          if (current.isNotEmpty && _font.measure('$current$ch', size) > w) {
            result.add(current);
            current = '';
          }
          current += ch;
        }
      }
      result.add(current);
    }
    return result;
  }

  void paragraph(
    String value, {
    double size = 10,
    String continuation = 'Tiếp theo',
  }) {
    for (final line in wrap(value, width, size)) {
      if (y + size + 5 > bottom) page(continuation);
      text(line, 40, y, size: size);
      y += size + 5;
    }
    y += 5;
  }

  /// Rows split across pages when notes are long; no silent truncation.
  void table(
    List<String> headers,
    List<List<String>> rows,
    List<double> widths,
  ) {
    void draw(List<List<String>> cells, int start, int count, bool shaded) {
      final height = count * 13.0 + 12;
      if (shaded) rect(40, y, width, height);
      var x = 40.0;
      for (var c = 0; c < cells.length; c++) {
        for (var l = start; l < math.min(start + count, cells[c].length); l++) {
          text(cells[c][l], x + 5, y + 5 + (l - start) * 13, size: 9);
        }
        x += widths[c];
        _out.writeln(
          'q 0.88 G 0.4 w $x ${841.89 - y} m '
          '$x ${841.89 - y - height} l S Q',
        );
      }
      y += height;
      _out.writeln(
        'q 0.88 G 0.4 w 40 ${841.89 - y} m '
        '555.28 ${841.89 - y} l S Q',
      );
    }

    final head = [
      for (var i = 0; i < headers.length; i++)
        wrap(headers[i], widths[i] - 10, 9),
    ];
    final headLines = head.map((c) => c.length).reduce(math.max);
    void header() => draw(head, 0, headLines, true);
    if (y + headLines * 13 + 40 > bottom) page('$title · tiếp theo');
    header();
    for (var i = 0; i < rows.length; i++) {
      final cells = [
        for (var c = 0; c < widths.length; c++)
          wrap(rows[i][c], widths[c] - 10, 9),
      ];
      final lines = cells.map((c) => c.length).reduce(math.max);
      var start = 0;
      while (start < lines) {
        var available = ((bottom - y - 12) / 13).floor();
        if (available < 1) {
          page('$title · tiếp theo');
          header();
          available = ((bottom - y - 12) / 13).floor();
        }
        final count = math.min(available, lines - start);
        draw(cells, start, count, i.isEven);
        start += count;
      }
    }
    y += 12;
  }

  Uint8List save({required String source}) {
    for (var i = 0; i < _pages.length; i++) {
      // Footers are added after layout so total page count is exact.
      final footer = 'Trang ${i + 1}/${_pages.length} · $source';
      final previous = _pages.last;
      _pages[_pages.length - 1] = _pages[i];
      text(footer, 40, 790, size: 8);
      _pages[_pages.length - 1] = previous;
    }
    final objects = <Uint8List>[];
    int add(String s) {
      objects.add(Uint8List.fromList(latin1.encode(s)));
      return objects.length;
    }

    int stream(Uint8List bytes, [String extra = '']) {
      final b = BytesBuilder()
        ..add(latin1.encode('<< /Length ${bytes.length} $extra >>\nstream\n'))
        ..add(bytes)
        ..add(latin1.encode('\nendstream'));
      objects.add(b.toBytes());
      return objects.length;
    }

    add('<< /Type /Catalog /Pages 2 0 R >>');
    add(''); // page tree, filled after content streams
    final fontFile = stream(_font.bytes, '/Length1 ${_font.bytes.length}');
    final descriptor = add(
      '<< /Type /FontDescriptor /FontName /Roboto /Flags 32 '
      '/FontBBox [-1000 -1000 2000 2000] /ItalicAngle 0 /Ascent 1000 /Descent -300 '
      '/CapHeight 700 /StemV 80 /FontFile2 $fontFile 0 R >>',
    );
    final mapping = ByteData(65536 * 2);
    for (final c in _used) {
      mapping.setUint16(c * 2, _font.glyph(c));
    }
    final map = stream(mapping.buffer.asUint8List());
    final codes = _used.toList()..sort();
    final widths = codes.map((c) => '$c [${_font.advance(c)}]').join(' ');
    final cid = add(
      '<< /Type /Font /Subtype /CIDFontType2 /BaseFont /Roboto '
      '/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> '
      '/FontDescriptor $descriptor 0 R /CIDToGIDMap $map 0 R /W [$widths] >>',
    );
    final cmap = StringBuffer(
      '/CIDInit /ProcSet findresource begin\n12 dict begin\n'
      'begincmap\n/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def\n'
      '/CMapName /RecipeHubUnicode def\n/CMapType 2 def\n'
      '1 begincodespacerange\n<0000> <FFFF>\nendcodespacerange\n',
    );
    for (var i = 0; i < codes.length; i += 100) {
      final chunk = codes.skip(i).take(100);
      cmap.writeln('${chunk.length} beginbfchar');
      for (final c in chunk) {
        final h = c.toRadixString(16).padLeft(4, '0');
        cmap.writeln('<$h> <$h>');
      }
      cmap.writeln('endbfchar');
    }
    cmap.write(
      'endcmap\nCMapName currentdict /CMap defineresource pop\nend\nend',
    );
    final unicode = stream(Uint8List.fromList(latin1.encode(cmap.toString())));
    final type0 = add(
      '<< /Type /Font /Subtype /Type0 /BaseFont /Roboto '
      '/Encoding /Identity-H /DescendantFonts [$cid 0 R] /ToUnicode $unicode 0 R >>',
    );
    final kids = <int>[];
    for (final p in _pages) {
      final content = stream(Uint8List.fromList(latin1.encode(p.toString())));
      kids.add(
        add(
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] '
          '/Resources << /Font << /F1 $type0 0 R >> >> /Contents $content 0 R >>',
        ),
      );
    }
    objects[1] = Uint8List.fromList(
      latin1.encode(
        '<< /Type /Pages /Count ${kids.length} '
        '/Kids [${kids.map((k) => '$k 0 R').join(' ')}] >>',
      ),
    );
    final titleHex = title.codeUnits
        .map((c) => c.toRadixString(16).padLeft(4, '0'))
        .join();
    final info = add('<< /Title <FEFF$titleHex> /Author (RecipeHub) >>');
    final out = BytesBuilder()..add(latin1.encode('%PDF-1.4\n'));
    final offsets = <int>[];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(out.length);
      out
        ..add(latin1.encode('${i + 1} 0 obj\n'))
        ..add(objects[i])
        ..add(latin1.encode('\nendobj\n'));
    }
    final xref = out.length;
    out.add(
      latin1.encode(
        'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n'
        '${offsets.map((o) => '${o.toString().padLeft(10, '0')} 00000 n \n').join()}'
        'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R /Info $info 0 R >>\n'
        'startxref\n$xref\n%%EOF\n',
      ),
    );
    return out.toBytes();
  }
}

/// Reads Unicode BMP cmap format 4 and horizontal advances from a TTF.
class _TrueType {
  _TrueType(this.bytes) : data = ByteData.sublistView(bytes) {
    for (var i = 0; i < u16(4); i++) {
      final at = 12 + i * 16;
      tables[latin1.decode(bytes.sublist(at, at + 4))] = u32(at + 8);
    }
    final cmap = tables['cmap']!;
    for (var i = 0; i < u16(cmap + 2); i++) {
      final at = cmap + 4 + i * 8;
      final offset = cmap + u32(at + 4);
      if ((u16(at) == 0 || u16(at) == 3) && u16(offset) == 4) {
        format4 = offset;
      }
    }
    if (format4 == null) {
      throw FormatException('Font requires Unicode cmap format 4');
    }
  }
  final Uint8List bytes;
  final ByteData data;
  final Map<String, int> tables = {};
  int? format4;
  int u16(int at) => data.getUint16(at);
  int u32(int at) => data.getUint32(at);
  int glyph(int code) {
    final f = format4!;
    final n = u16(f + 6) ~/ 2;
    for (var i = 0; i < n; i++) {
      if (code > u16(f + 14 + i * 2)) continue;
      final start = u16(f + 16 + n * 2 + i * 2);
      if (code < start) return 0;
      final delta = u16(f + 16 + n * 4 + i * 2);
      final at = f + 16 + n * 6 + i * 2;
      final range = u16(at);
      if (range == 0) return (code + delta) & 65535;
      final g = u16(at + range + 2 * (code - start));
      return g == 0 ? 0 : (g + delta) & 65535;
    }
    return 0;
  }

  int advance(int code) {
    final g = math.min(glyph(code), u16(tables['hhea']! + 34) - 1);
    return (u16(tables['hmtx']! + g * 4) * 1000 / u16(tables['head']! + 18))
        .round();
  }

  double measure(String s, double size) =>
      s.runes.fold<double>(0, (sum, c) => sum + advance(c) * size / 1000);
}
