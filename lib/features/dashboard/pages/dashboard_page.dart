import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_layout.dart';
import '../../funcionario/providers/funcionario_provider.dart';
import '../../ponto/providers/ponto_provider.dart';
import '../../ponto/providers/alerta_provider.dart';
import '../../ponto/models/registro_ponto_model.dart';
import '../../ponto/models/alerta_ponto_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final funcionarioProvider = context.read<FuncionarioProvider>();
    final pontoProvider = context.read<PontoProvider>();
    final alertaProvider = context.read<AlertaProvider>();

    await funcionarioProvider.carregarFuncionarios();
    await pontoProvider.carregarRegistros();
    await alertaProvider.carregarAlertas();
  }

  @override
  Widget build(BuildContext context) {
    final funcionarioProvider = context.watch<FuncionarioProvider>();
    final pontoProvider = context.watch<PontoProvider>();
    final alertaProvider = context.watch<AlertaProvider>();

    final totalFuncionarios = funcionarioProvider.funcionarios.length;
    final totalAlertas = alertaProvider.totalAlertas;

    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final pontosHoje = pontoProvider.registros
        .where((r) => r.dataHora.isAfter(inicioDia))
        .length;

    // 🔥 Calcular horas extras (simples)
    final horasExtras = '0h';

    return AppLayout(
      titulo: 'Dashboard',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de Estatísticas
            Row(
              children: [
                _buildStatCard(
                  'Funcionários',
                  '$totalFuncionarios',
                  Icons.people,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Pontos Hoje',
                  '$pontosHoje',
                  Icons.access_time,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Alertas',
                  '$totalAlertas',
                  Icons.warning,
                  Colors.red,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Horas Extras',
                  horasExtras,
                  Icons.timer,
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ações Rápidas
            const Text(
              '⚡ Ações Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton(
                  context,
                  'Novo Funcionário',
                  Icons.person_add,
                  () => context.go('/cadastrar-funcionario'),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  context,
                  'Registrar Ponto (Admin)',
                  Icons.fingerprint,
                  () => context.go('/registro-ponto-admin'),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  context,
                  'Relatórios',
                  Icons.assessment,
                  () => context.go('/relatorios'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Últimos Registros + Alertas
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildUltimosRegistros(pontoProvider),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildAlertasRecentes(alertaProvider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildUltimosRegistros(PontoProvider provider) {
    final registros = provider.registros.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Últimos Registros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: provider.carregando
                  ? const Center(child: CircularProgressIndicator())
                  : registros.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum registro encontrado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: registros.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return _buildRegistroItem(registros[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 MÉTODO CORRIGIDO - Busca o nome do funcionário pelo ID
  // 🔥 MÉTODO CORRIGIDO
Widget _buildRegistroItem(RegistroPonto registro) {
  // 🔥 Buscar o funcionário pelo ID
  final funcionarioProvider = context.watch<FuncionarioProvider>();
  final funcionario = funcionarioProvider.buscarPorId(registro.funcionarioId);
  
  // 🔥 Usar o nome do funcionário ou fallback (simplificado)
  final nome = funcionario?.nome ?? 'Funcionário';
  
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 50,
          decoration: BoxDecoration(
            color: registro.tipo.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Icon(
                    registro.tipo.icon,
                    size: 14,
                    color: registro.tipo.color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    registro.tipo.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                registro.dataFormatada,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              registro.horaFormatada,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              _getDiaSemana(registro.dataHora.weekday),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    ),
  );
}

  // 🔥 Método auxiliar para dia da semana
  String _getDiaSemana(int weekday) {
    const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return dias[weekday - 1];
  }

  Widget _buildAlertasRecentes(AlertaProvider provider) {
    final alertas = provider.alertas.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔔 Alertas Recentes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (provider.totalAlertas > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.totalAlertas} novo(s)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.carregando)
              const Center(child: CircularProgressIndicator())
            else if (alertas.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 40, color: Colors.green),
                      SizedBox(height: 8),
                      Text(
                        'Tudo certo!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Nenhum alerta pendente',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...alertas.map((alerta) => _buildAlertaItem(alerta)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertaItem(AlertaPonto alerta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REGISTRO AUSENTE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Text(
                    '${alerta.funcionarioNome} não registrou ${_getTipoDescricao(alerta.tipo)}.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    alerta.dataHoraFormatada,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _resolverAlerta(alerta),
              tooltip: 'Marcar como resolvido',
            ),
          ],
        ),
      ),
    );
  }

  String _getTipoDescricao(TipoAlerta tipo) {
    switch (tipo) {
      case TipoAlerta.entradaAusente:
        return 'entrada';
      case TipoAlerta.saidaAusente:
        return 'saída';
      case TipoAlerta.almocoAusente:
        return 'saída para almoço';
      case TipoAlerta.retornoAusente:
        return 'retorno do almoço';
    }
  }

  Future<void> _resolverAlerta(AlertaPonto alerta) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AlertaProvider>();

    final justificativa = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolver Alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Alerta: ${alerta.funcionarioNome} - ${alerta.tipo.label}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Informe a justificativa para resolver este alerta:'),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Funcionário justificou...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, 'Justificado pelo admin');
            },
            child: const Text('Resolver'),
          ),
        ],
      ),
    );

    if (justificativa != null && mounted) {
      try {
        await provider.resolverAlerta(alerta.id, justificativa);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Alerta resolvido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao resolver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}