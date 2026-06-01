import 'package:flutter_test/flutter_test.dart';
import 'package:beerreal/main.dart';

void main() {
  testWidgets('PintRoot renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const PintRoot());
    expect(find.text('Pint'), findsOneWidget);
  });
}
