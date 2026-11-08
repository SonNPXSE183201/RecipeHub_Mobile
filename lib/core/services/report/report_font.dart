import 'package:flutter/services.dart';

/// Asset IO kept outside pure PDF layout/rendering.
class ReportFont {
  static Future<Uint8List> load() async =>
      (await rootBundle.load('assets/fonts/Roboto-Regular.ttf')).buffer
          .asUint8List();
}
