import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blue),
              ),
              tooltip: 'Menu do usuário',
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push('/perfil');
                } else if (value == 'logout') {
                  _confirmarLogout(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline),
                      SizedBox(width: 12),
                      Text('Meu Perfil'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Sair', style: TextStyle(color: Colors.red)),
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

  // 🔥 MÉTODO DE LOGOUT CORRIGIDO
  void _confirmarLogout(BuildContext context) {
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
            onPressed: () async {
              // 🔥 Fechar dialog
              Navigator.pop(dialogContext);
              
              try {
                // 🔥 Fazer logout
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  // 🔥 USAR context.go('/') EM VEZ DE context.go('/login')
                  context.go('/login'); // ← CORRIGIDO!
                }
              } catch (e) {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}