import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../providers/ponto_provider.dart';
import '../models/registro_ponto_model.dart';
import '../../funcionario/providers/funcionario_provider.dart';

class RegistroPontoAdminPage extends StatefulWidget {
  const RegistroPontoAdminPage({super.key});

  @override
  State<RegistroPontoAdminPage> createState() =>
      _RegistroPontoAdminPageState();
}

class _RegistroPontoAdminPageState extends State<RegistroPontoAdminPage> {
  String? _funcionarioSelecionado;
  TipoPonto? _tipoSelecionado;
  bool _registrando = false;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final funcionarioProvider = context.watch<FuncionarioProvider>();
    final pontoProvider = context.watch<PontoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Registrar Ponto - Admin'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              funcionarioProvider.carregarFuncionarios();
              pontoProvider.carregarRegistros();
            },
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📝 Registrar Ponto para Funcionário',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione o funcionário e o tipo de ponto para registrar.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // 🔥 DROPDOWN SIMPLIFICADO - SEM STACK
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Funcionário *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              value: _funcionarioSelecionado,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Selecione um funcionário...'),
                ),
                ...funcionarioProvider.funcionarios.map((f) {
                  return DropdownMenuItem(
                    value: f.id,
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              f.nome.isNotEmpty ? f.nome[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  f.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  f.cargo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: f.ativo
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              f.ativo ? 'Ativo' : 'Inativo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: f.ativo
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _funcionarioSelecionado = value;
                  _tipoSelecionado = null;
                });
              },
            ),

            const SizedBox(height: 24),

            if (_funcionarioSelecionado != null) ...[
              const Text(
                'Selecione o tipo de ponto:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTipoPonto(
                    tipo: TipoPonto.entrada,
                    icon: Icons.login,
                    cor: Colors.green,
                    label: 'Entrada',
                  ),
                  const SizedBox(width: 12),
                  _buildTipoPonto(
                    tipo: TipoPonto.saidaAlmoco,
                    icon: Icons.restaurant,
                    cor: Colors.orange,
                    label: 'Saída Alm.',
                  ),
                  const SizedBox(width: 12),
                  _buildTipoPonto(
                    tipo: TipoPonto.retornoAlmoco,
                    icon: Icons.restaurant,
                    cor: Colors.blue,
                    label: 'Retorno Alm.',
                  ),
                  const SizedBox(width: 12),
                  _buildTipoPonto(
                    tipo: TipoPonto.saida,
                    icon: Icons.logout,
                    cor: Colors.red,
                    label: 'Saída',
                  ),
                ],
              ),
            ],

            const Spacer(),

            if (_funcionarioSelecionado != null && _tipoSelecionado != null)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _registrando ? null : _registrarPonto,
                  icon: _registrando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _registrando
                        ? 'Registrando...'
                        : 'Registrar ${_tipoSelecionado!.label}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoPonto({
    required TipoPonto tipo,
    required IconData icon,
    required Color cor,
    required String label,
  }) {
    final isSelected = _tipoSelecionado == tipo;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _tipoSelecionado = tipo;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? cor.withValues(alpha: 0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? cor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? cor : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? cor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _registrarPonto() async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PontoProvider>();
    final funcionarioProvider = context.read<FuncionarioProvider>();

    setState(() => _registrando = true);

    try {
      final usuario = await _authService.getUsuarioSalvo();

      if (usuario == null) {
        throw Exception('Usuário não encontrado. Faça login novamente.');
      }

      final funcionario = funcionarioProvider.buscarPorId(
        _funcionarioSelecionado!,
      );

      if (funcionario == null) {
        throw Exception('Funcionário não encontrado.');
      }

      await provider.registrarPonto(
        funcionarioId: _funcionarioSelecionado!,
        funcionarioNome: funcionario.nome,
        tipo: _tipoSelecionado!,
        metodoAutenticacao: 'Admin (Senha)',
        sobrescrever: true,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${_tipoSelecionado!.label} registrada com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _tipoSelecionado = null;
        });
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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