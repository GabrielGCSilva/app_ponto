import 'package:flutter/material.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),

      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.business),
            title: Text('Dados da Empresa'),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('Permissões'),
          ),
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text('GPS'),
          ),
        ],
      ),
    );
  }
}