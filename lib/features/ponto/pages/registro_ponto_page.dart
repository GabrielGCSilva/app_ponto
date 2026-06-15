import 'package:flutter/material.dart';

class RegistroPontoPage extends StatelessWidget {
  const RegistroPontoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ponto'),
      ),

      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            // Futuramente registrará o ponto
          },
          icon: const Icon(Icons.fingerprint),
          label: const Text('Registrar Ponto'),
        ),
      ),
    );
  }
}