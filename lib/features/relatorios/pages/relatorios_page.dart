import 'package:flutter/material.dart';

class RelatoriosPage extends StatelessWidget {
  const RelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),

      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Espelho de Ponto'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Exportar Excel'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}