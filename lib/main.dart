import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/funcionario/providers/funcionario_provider.dart';
import 'features/ponto/providers/ponto_provider.dart';
import 'features/ponto/providers/alerta_provider.dart';
import 'features/perfil/providers/historico_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("1️⃣ Antes do Firebase");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("2️⃣ Firebase inicializado");
  } catch (e) {
    debugPrint("❌ Firebase erro: $e");
  }

  debugPrint("3️⃣ Antes do runApp");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FuncionarioProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PontoProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertaProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoricoProvider(),
        ),
      ],
      child: const AppPonto(),
    ),
  );

  debugPrint("4️⃣ Depois do runApp");
}

class AppPonto extends StatelessWidget {
  const AppPonto({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("5️⃣ AppPonto build");

    return MaterialApp.router(
      title: 'App Ponto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}