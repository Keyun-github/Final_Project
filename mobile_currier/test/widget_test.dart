import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_currier/main.dart';

void main() {
  testWidgets('CourierApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CourierApp());
    expect(find.text('Mobile Courier'), findsOneWidget);
  });
}
