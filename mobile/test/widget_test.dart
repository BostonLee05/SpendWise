import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('SpendWise app loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SpendWiseApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Track your money with SpendWise.'), findsOneWidget);
  });
}
