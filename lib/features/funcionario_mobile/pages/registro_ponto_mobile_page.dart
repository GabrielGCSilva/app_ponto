import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../ponto/providers/ponto_provider.dart';
import '../../ponto/models/registro_ponto_model.dart';
import '../../funcionario/providers/funcionario_provider.dart';

class RegistroPontoMobilePage extends StatefulWidget {
  const RegistroPontoMobilePage({super.key});

  @override
  State<RegistroPontoMobilePage> createState() =>
      _RegistroPontoMobilePageState();
}

class _RegistroPontoMobilePageState extends State<RegistroPontoMobilePage> {
  TipoPonto? _tipoSelecionado;
  bool _registrando = false;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Ponto'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Selecione o tipo de registro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha o tipo de ponto que deseja registrar',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            _buildOpcaoPonto(
              tipo: TipoPonto.entrada,
              icon: Icons.login,
              cor: Colors.green,
              descricao: 'Registrar entrada',
            ),
            const SizedBox(height: 12),
            _buildOpcaoPonto(
              tipo: TipoPonto.saidaAlmoco,
              icon: Icons.restaurant,
              cor: Colors.orange,
              descricao: 'Registrar saída para almoço',
            ),
            const SizedBox(height: 12),
            _buildOpcaoPonto(
              tipo: TipoPonto.retornoAlmoco,
              icon: Icons.restaurant,
              cor: Colors.blue,
              descricao: 'Registrar retorno do almoço',
            ),
            const SizedBox(height: 12),
            _buildOpcaoPonto(
              tipo: TipoPonto.saida,
              icon: Icons.logout,
              cor: Colors.red,
              descricao: 'Registrar saída',
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selecione o tipo de ponto e confirme para registrar.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoPonto({
    required TipoPonto tipo,
    required IconData icon,
    required Color cor,
    required String descricao,
  }) {
    return InkWell(
      onTap: _registrando ? null : () => _registrarPonto(tipo),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: cor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tipo.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                  Text(
                    descricao,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_registrando && _tipoSelecionado == tipo)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

    Future<void> _registrarPonto(TipoPonto tipo) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final pontoProvider = Provider.of<PontoProvider>(context, listen: false);
    final funcionarioProvider = Provider.of<FuncionarioProvider>(context, listen: false);

    setState(() {
      _tipoSelecionado = tipo;
      _registrando = true;
    });

    try {
      final usuario = await _authService.getUsuarioSalvo();

      if (usuario == null) {
        throw Exception('Usuário não encontrado. Faça login novamente.');
      }

      final funcionarioId = usuario['id'] ?? '';

      // 🔥 FORÇAR RECARREGAR DO FIRESTORE PARA TER DADOS ATUALIZADOS
      await funcionarioProvider.carregarFuncionarios();

      // 🔥 VERIFICAR SE O FUNCIONÁRIO ESTÁ ATIVO
      final podeBater = funcionarioProvider.podeBaterPonto(funcionarioId);

      if (!podeBater) {
        final funcionario = funcionarioProvider.buscarPorId(funcionarioId);
        final nome = funcionario?.nome ?? 'Funcionário';

        throw Exception(
          '❌ $nome está INATIVO no sistema.\n'
          'Entre em contato com o administrador para reativar seu acesso.\n'
          'Histórico de pontos mantido.',
        );
      }

      await pontoProvider.registrarPonto(
        funcionarioId: funcionarioId,
        funcionarioNome: usuario['nome'] ?? 'Funcionário',
        tipo: tipo,
        metodoAutenticacao: 'Senha',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ ${tipo.label} registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        final mensagem = e.toString().replaceFirst('Exception: ', '');
        messenger.showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _registrando = false);
      }
    }
  }
}