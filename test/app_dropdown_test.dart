import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/widgets/app_dropdown.dart';

void main() {
  for (final width in [360.0, 412.0]) {
    testWidgets('AppDropdown matches field width and opens below at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String? selected = 'first';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) => AppDropdown<String>(
                  value: selected,
                  items: List.generate(
                    15,
                    (i) => DropdownMenuItem(
                      value: i == 0 ? 'first' : 'item$i',
                      child: Text('Món số $i tên dài để kiểm tra chiều rộng'),
                    ),
                  ),
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );
      final field = tester.getRect(find.byType(AppDropdown<String>));
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();
      final menu = tester.getRect(
        find.byKey(const ValueKey('app_dropdown_menu')),
      );
      expect(menu.width, field.width);
      expect(menu.left, field.left);
      expect(menu.top, field.bottom);
      expect(menu.height, lessThanOrEqualTo(320));
      final list = find.descendant(
        of: find.byKey(const ValueKey('app_dropdown_menu')),
        matching: find.byType(ListView),
      );
      expect(
        find.descendant(of: list, matching: find.byType(Scrollbar)),
        findsNothing,
      );
      await tester.tap(find.text('Món số 1 tên dài để kiểm tra chiều rộng'));
      await tester.pumpAndSettle();
      expect(selected, 'item1');
      expect(find.byKey(const ValueKey('app_dropdown_menu')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
