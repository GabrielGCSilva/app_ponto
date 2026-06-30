import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/funcionario/providers/funcionario_provider.dart';
import 'features/ponto/providers/ponto_provider.dart';
import 'features/ponto/providers/alerta_provider.dart';
import 'features/perfil/providers/historico_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔥 REMOVIDO: setPersistence() não funciona no Android
  // await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  await FirebaseMessaging.instance.requestPermission();

  await NotificationService().init();

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
        ChangeNotifierProvider(
          create: (_) => HistoricoProvider(),
        ),
      ],
      child: const AppPonto(),
    ),
  );
}

class AppPonto extends StatelessWidget {
  const AppPonto({super.key});

  @override
  Widget build(BuildContext context) {
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
