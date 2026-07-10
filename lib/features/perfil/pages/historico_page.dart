import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/historico_provider.dart';
import '../widgets/historico_mensal_widget.dart';
import '../../../core/services/auth_service.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarHistorico();
    });
  }

  Future<void> _carregarHistorico() async {
    // 🔥 USAR O MESMO AuthService do PerfilPage
    final usuario = await _authService.getUsuarioSalvo();

    // 🔥 Verificar se o widget ainda está montado
    if (!mounted) return;

    if (usuario != null) {
      // 🔥 USAR O ID DO USUÁRIO SALVO, NÃO O UID DO FIREBASE
      // Fallback: se 'id' for null, tenta 'uid'
      final funcionarioId = usuario['id'] ?? usuario['uid'];

      // 🔥 Verificar se o ID é válido (não nulo e não vazio)
      if (funcionarioId != null && funcionarioId.isNotEmpty) {
        debugPrint(
          '📋 [HISTORICO] Carregando para funcionarioId: $funcionarioId',
        );
        await context.read<HistoricoProvider>().carregarHistorico(
          funcionarioId,
        );
      } else {
        debugPrint('⚠️ [HISTORICO] ID do usuário não encontrado');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: ID do usuário não encontrado.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      debugPrint('⚠️ [HISTORICO] Usuário não encontrado');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro: Usuário não encontrado. Faça login novamente.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historicoProvider = context.watch<HistoricoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Histórico de Pontos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarHistorico,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: historicoProvider.carregando
          ? const Center(child: CircularProgressIndicator())
          : historicoProvider.erro != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    historicoProvider.erro!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _carregarHistorico,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : historicoProvider.historico.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Nenhum registro de ponto encontrado',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bata seu primeiro ponto para começar!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historicoProvider.historico.length,
              itemBuilder: (context, index) {
                final mes = historicoProvider.historico[index];
                return HistoricoMensalWidget(mes: mes);
              },
            ),
    );
  }
}
