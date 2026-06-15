import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_layout.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      titulo: 'Dashboard',

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(
          children: [

            // ==========================
            // CARDS PRINCIPAIS
            // ==========================
            SizedBox(
              height: 170,

              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),

                crossAxisCount: 4,
                childAspectRatio: 1.8,

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
                    titulo: 'Alertas',
                    valor: '3',
                    icone: Icons.warning,
                    cor: Colors.orange,
                  ),

                  DashboardCard(
                    titulo: 'Horas Extras',
                    valor: '18h',
                    icone: Icons.schedule,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // AÇÕES RÁPIDAS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Ações Rápidas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                      children: [

                        AcaoRapidaCard(
                          titulo: 'Novo Funcionário',
                          icone: Icons.person_add,
                          onTap: () {
                            context.go('/funcionarios');
                          },
                        ),

                        AcaoRapidaCard(
                          titulo: 'Registrar Ponto',
                          icone: Icons.access_time,
                          onTap: () {
                            context.go('/ponto');
                          },
                        ),

                        AcaoRapidaCard(
                          titulo: 'Relatórios',
                          icone: Icons.description,
                          onTap: () {
                            context.go('/relatorios');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ÚLTIMOS REGISTROS
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Últimos Registros',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    RegistroItem(
                      nome: 'João Silva',
                      evento: 'Entrada',
                      horario: '08:01',
                    ),

                    RegistroItem(
                      nome: 'Maria Souza',
                      evento: 'Saída',
                      horario: '17:59',
                    ),

                    RegistroItem(
                      nome: 'Pedro Santos',
                      evento: 'Entrada',
                      horario: '08:10',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ALERTAS RECENTES

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Alertas Recentes',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    const AlertaItem(
                      categoria: 'REGISTRO AUSENTE',
                      texto: 'João Silva não registrou saída ontem.',
                      dataHora: '11/06/2026 18:00',
                      icone: Icons.warning_amber,
                    ),

                    const AlertaItem(
                      categoria: 'REGISTRO AUSENTE',
                      texto: 'Maria Souza não registrou entrada hoje.',
                      dataHora: '12/06/2026 08:00',
                      icone: Icons.warning_amber,
                    ),

                    const AlertaItem(
                      categoria: 'REGISTRO DUPLICADO',
                      texto: 'Pedro Santos possui registro duplicado.',
                      dataHora: '12/06/2026 09:15',
                      icone: Icons.error_outline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AcaoRapidaCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final VoidCallback onTap;

  const AcaoRapidaCard({
    super.key,
    required this.titulo,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      child: Card(
        elevation: 2,

        child: SizedBox(
          width: 180,
          height: 120,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(
                icone,
                size: 40,
              ),

              const SizedBox(height: 10),

              Text(
                titulo,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistroItem extends StatelessWidget {
  final String nome;
  final String evento;
  final String horario;

  const RegistroItem({
    super.key,
    required this.nome,
    required this.evento,
    required this.horario,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time),

      title: Text(nome),

      subtitle: Text(evento),

      trailing: Text(
        horario,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AlertaItem extends StatelessWidget {
  final String categoria;
  final String texto;
  final String dataHora;
  final IconData icone;

  const AlertaItem({
    super.key,
    required this.categoria,
    required this.texto,
    required this.dataHora,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icone,
        color: Colors.orange,
      ),

      title: Text(
        categoria,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const SizedBox(height: 4),

          Text(texto),

          const SizedBox(height: 4),

          Text(
            dataHora,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const DashboardCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    this.cor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            Icon(
              icone,
              size: 40,
              color: cor,
            ),
          ],
        ),
      ),
    );
  }
}