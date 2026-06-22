import 'package:flutter_test/flutter_test.dart';
import 'package:app_ponto/main.dart';

void main() {
  testWidgets('App Ponto test', (WidgetTester tester) async {
    // 🔥 Usar AppPonto em vez de MyApp
    await tester.pumpWidget(const AppPonto());

    // Verificar se o app inicia
    expect(find.text('App Ponto'), findsNothing);
  });
}