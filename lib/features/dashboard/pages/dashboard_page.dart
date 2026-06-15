import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior
      appBar: AppBar(
        title: const Text('Controle de Ponto'),

        // Ícone do usuário no canto direito
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Executa uma ação dependendo do item clicado

              if (value == 'logout') {
                // Futuramente fará logout
              }

              if (value == 'switch_account') {
                // Futuramente trocará de conta
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Meu Perfil'),
              ),
              const PopupMenuItem(
                value: 'switch_account',
                child: Text('Trocar Conta'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Sair'),
              ),
            ],
          ),
        ],
      ),

      // Menu lateral
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text(
                'Empresa Exemplo',
                style: TextStyle(fontSize: 22),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                context.go('/dashboard');
              },
            ),

            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Funcionários'),
              onTap: () {
                context.go('/funcionarios');
              },
            ),

            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Registro de Ponto'),
              onTap: () {
                context.go('/ponto');
              },
            ),

            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Relatórios'),
              onTap: () {
                context.go('/relatorios');
              },
            ),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configurações'),
              onTap: () {
                context.go('/configuracoes');
              },
            ),
          ],
        ),
      ),

      // Conteúdo principal
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,

          children: const [
            DashboardCard(
              titulo: 'Funcionários',
              valor: '25',
              icone: Icons.people,
            ),
            DashboardCard(
              titulo: 'Pontos Hoje',
              valor: '22',
              icone: Icons.access_time,
            ),
            DashboardCard(
              titulo: 'Pendências',
              valor: '3',
              icone: Icons.warning,
            ),
            DashboardCard(
              titulo: 'Horas Extras',
              valor: '18h',
              icone: Icons.schedule,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizável para os cards do dashboard
class DashboardCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const DashboardCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }
}