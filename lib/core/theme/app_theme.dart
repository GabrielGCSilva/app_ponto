import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // CORREÇÃO AQUI:
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Definimos uma altura fixa (50), mas a largura (0) permite que 
          // o botão se ajuste ao texto ou ao componente pai.
          minimumSize: const Size(0, 50), 
          padding: const EdgeInsets.symmetric(horizontal: 24), // Espaço interno lateral
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
