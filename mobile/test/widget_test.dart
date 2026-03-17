import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_finder/main.dart';

void main() {
  testWidgets('FuelFinderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FuelFinderApp());
    expect(find.text('Fuel Finder'), findsOneWidget);
  });
}
