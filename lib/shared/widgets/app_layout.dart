import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth_service.dart';
import 'app_drawer.dart';

class AppLayout extends StatelessWidget {
  final String titulo;
  final Widget body;
  final bool mostrarMenu;

  const AppLayout({
    super.key,
    required this.titulo,
    required this.body,
    this.mostrarMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (mostrarMenu)
            PopupMenuButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blue),
              ),
              tooltip: 'Menu do usuário',
              onSelected: (value) {
                if (value == 'profile') {
                  context.push('/perfil');
                } else if (value == 'logout') {
                  _confirmarLogout(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 12),
                      Text('Meu Perfil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12),
                      Text(
                        'Sair',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: body,
    );
  }

  void _confirmarLogout(BuildContext context) {
    final authService = AuthService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do App'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
            onPressed: () async {
              // Fecha o diálogo
              Navigator.pop(dialogContext);

              try {
                debugPrint('🚪 [APP_LAYOUT] Iniciando logout...');

                await authService.logout();

                debugPrint('🚪 [APP_LAYOUT] Logout finalizado.');

                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                debugPrint('❌ [APP_LAYOUT] Erro no logout: $e');

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erro ao sair: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}