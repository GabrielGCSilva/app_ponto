
import 'package:flutter_test/flutter_test.dart';
import 'package:app_ponto/main.dart';

void main() {
  testWidgets('App Ponto test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AppPonto());

    // Verify that the app starts correctly
    expect(find.text('App Ponto'), findsNothing);
  });
}