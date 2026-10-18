import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/main.dart';

void main() {
  testWidgets('RecipeHub opens the NomadKit recipe library', (tester) async {
    await tester.pumpWidget(const RecipeHubApp());

    expect(find.text('Make every recipe easier to run.'), findsOneWidget);
    expect(find.text('Create recipe'), findsOneWidget);
    expect(find.text('Citrus Tiramisu'), findsOneWidget);
  });
}
