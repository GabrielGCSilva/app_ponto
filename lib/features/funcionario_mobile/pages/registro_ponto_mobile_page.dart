import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // 🔥 MÉTODO PRINCIPAL - CORRIGIDO
  Future<void> _registrarPonto(TipoPonto tipo) async {
    // 🔥 Guardar referências ANTES do async
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final pontoProvider = Provider.of<PontoProvider>(context, listen: false);
    final funcionarioProvider =
        Provider.of<FuncionarioProvider>(context, listen: false);

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

      // 🔥 FORÇAR RECARREGAR DO FIRESTORE
      await funcionarioProvider.carregarFuncionarios();

      // 🔥 VERIFICAR SE O FUNCIONÁRIO ESTÁ ATIVO
      final funcionario = funcionarioProvider.buscarPorId(funcionarioId);
      final podeBater = funcionarioProvider.podeBaterPonto(funcionarioId);
      final isAdmin = funcionario?.isAdmin ?? false;

      // 🔥 SE FOR ADMIN DESATIVADO, FORÇAR LOGOUT
if (!podeBater) {
  if (isAdmin) {
    // 🔥 Forçar logout do Admin desativado
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('❌ Admin foi desativado. Fazendo logout...'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        navigator.pushReplacementNamed('/login');
      }
    }
    return;
  } else {
    // ❌ Funcionário normal bloqueado
    final nome = funcionario?.nome ?? 'Funcionário';
    throw Exception(
      '❌ $nome está INATIVO no sistema.\n'
      'Entre em contato com o administrador.',
    );
  }
}

      // 🔥 TENTAR REGISTRAR PONTO (pode lançar erro de duplicado)
      try {
        await pontoProvider.registrarPonto(
          funcionarioId: funcionarioId,
          funcionarioNome: usuario['nome'] ?? 'Funcionário',
          tipo: tipo,
          metodoAutenticacao: 'Senha',
          sobrescrever: false, // Tentativa normal
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
        final mensagem = e.toString();

        // 🔥 VERIFICAR SE É ERRO DE PONTO DUPLICADO
        if (mensagem.contains('já registrado hoje') && mounted) {
          // 🔥 PERGUNTAR SE QUER SOBRESCREVER (SÓ ADMIN)
          if (isAdmin) {
            _mostrarDialogSobrescrever(
              context,
              tipo,
              funcionarioId,
              usuario['nome'] ?? 'Funcionário',
            );
          } else {
            // ❌ FUNCIONÁRIO NORMAL NÃO PODE SOBRESCREVER
            messenger.showSnackBar(
              SnackBar(
                content: Text('❌ ${tipo.label} já registrado hoje!'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // ❌ OUTRO ERRO
          rethrow;
        }
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

  // 🔥 DIALOG PARA SOBRESCREVER PONTO (APENAS ADMIN)
  void _mostrarDialogSobrescrever(
    BuildContext context,
    TipoPonto tipo,
    String funcionarioId,
    String funcionarioNome,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final pontoProvider = Provider.of<PontoProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('⚠️ Ponto já registrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tipo.label} já foi registrado hoje para $funcionarioNome.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sobrescrever irá DELETAR o registro anterior.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                // 🔥 SOBRESCREVER O PONTO
                await pontoProvider.registrarPonto(
                  funcionarioId: funcionarioId,
                  funcionarioNome: funcionarioNome,
                  tipo: tipo,
                  metodoAutenticacao: 'Senha (Admin)',
                  sobrescrever: true, // 🔥 SOBRESCREVER!
                );

                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ ${tipo.label} sobrescrita com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  navigator.pop();
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('❌ Erro: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Sobrescrever'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}