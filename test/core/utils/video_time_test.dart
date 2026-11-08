import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/utils/video_time.dart';

void main() {
  group('formatVideoTime', () {
    for (final entry in {
      0: '00:00',
      9: '00:09',
      59: '00:59',
      60: '01:00',
      75: '01:15',
      599: '09:59',
      600: '10:00',
      3600: '60:00',
    }.entries) {
      test('${entry.key} seconds displays ${entry.value}', () {
        expect(formatVideoTime(Duration(seconds: entry.key)), entry.value);
      });
    }
  });
}
