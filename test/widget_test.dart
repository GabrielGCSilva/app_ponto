import 'package:flutter_test/flutter_test.dart';
import 'package:app_ponto/main.dart';

void main() {
  testWidgets('App Ponto test', (WidgetTester tester) async {
    // 🔥 Usar MyApp em vez de AppPonto
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verificar se a tela de login aparece
    expect(find.text('App Ponto'), findsOneWidget);
  });
}