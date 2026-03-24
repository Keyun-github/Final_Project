import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_customer/main.dart';

void main() {
  testWidgets('App renders catalog home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Mobile Customer'), findsOneWidget);
  });
}
