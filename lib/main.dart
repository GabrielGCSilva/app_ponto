import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/funcionario_mobile/pages/home_page.dart';
import 'features/funcionario/providers/funcionario_provider.dart';
import 'features/ponto/providers/ponto_provider.dart';
import 'features/ponto/providers/alerta_provider.dart';
import 'firebase_options.dart';

import 'features/dashboard/pages/dashboard_page.dart';
import 'features/funcionario/pages/funcionarios_page.dart';
import 'features/relatorios/pages/relatorios_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('usuario_logado') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FuncionarioProvider()..carregarFuncionarios(),
        ),
        ChangeNotifierProvider(
          create: (_) => PontoProvider()..carregarRegistros(),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertaProvider()..carregarAlertas(),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Ponto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 🔥 Rota inicial baseada no login
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/dashboard': (context) => const DashboardPage(), // Admin
        '/funcionarios': (context) => const FuncionariosPage(),
        // ... outras rotas
      },
      onGenerateRoute: (settings) {
        // 🔥 Rota para relatórios com parâmetros
        if (settings.name == '/relatorios') {
          final uri = Uri.parse(settings.name ?? '');
          final funcionarioId = uri.queryParameters['funcionarioId'] ?? '';
          final mes = int.tryParse(uri.queryParameters['mes'] ?? '') ?? DateTime.now().month;
          final ano = int.tryParse(uri.queryParameters['ano'] ?? '') ?? DateTime.now().year;
          
          return MaterialPageRoute(
            builder: (context) => RelatoriosPage(
              funcionarioId: funcionarioId,
              mes: mes,
              ano: ano,
            ),
          );
        }
        return null;
      },
    );
  }
}


