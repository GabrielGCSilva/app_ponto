import 'package:flutter/material.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const AppPonto());
}

class AppPonto extends StatelessWidget {
  const AppPonto({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App Ponto',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
    );
  }
}