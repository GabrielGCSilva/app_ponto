import 'package:flutter/material.dart';

import 'app_drawer.dart';

class AppLayout extends StatelessWidget {
  final String titulo;
  final Widget body;

  const AppLayout({
    super.key,
    required this.titulo,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),

        actions: [
          PopupMenuButton<String>(

            // Avatar do usuário
            icon: const CircleAvatar(
              child: Icon(Icons.person),
            ),

            onSelected: (value) {

              if (value == 'logout') {
                // logout futuramente
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Meu Perfil'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Sair'),
              ),
            ],
          ),
        ],
      ),

      drawer: const AppDrawer(),

      body: body,
    );
  }
}