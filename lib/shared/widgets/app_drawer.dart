import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text(
              'Empresa Exemplo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => context.go('/dashboard'),
          ),

          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Funcionários'),
            onTap: () => context.go('/funcionarios'),
          ),

          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Registro de Ponto'),
            onTap: () => context.go('/ponto'),
          ),

          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Relatórios'),
            onTap: () => context.go('/relatorios'),
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () => context.go('/configuracoes'),
          ),
        ],
      ),
    );
  }
}