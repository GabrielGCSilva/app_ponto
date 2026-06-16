import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';

import 'features/funcionario/providers/funcionario_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [

        ChangeNotifierProvider(
          create: (_) => FuncionarioProvider(),
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

      routerConfig: appRouter,

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
    );
  }
}