import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ponto_provider.dart';
import '../models/registro_ponto_model.dart';
import '../../funcionario/providers/funcionario_provider.dart';

class RegistroPontoPage extends StatefulWidget {
  const RegistroPontoPage({super.key});

  @override
  State<RegistroPontoPage> createState() => _RegistroPontoPageState();
}

class _RegistroPontoPageState extends State<RegistroPontoPage> {
  String? _funcionarioSelecionado;
  TipoPonto? _tipoSelecionado;
  String? _metodoAutenticacao;
  bool _registrando = false;

  final List<String> _metodos = ['Senha', 'Digital', 'Facial'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PontoProvider>().carregarRegistros();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pontoProvider = context.watch<PontoProvider>();
    final funcionarioProvider = context.watch<FuncionarioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ponto'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Registro
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Registrar Ponto',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selecionar Funcionário
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Funcionário',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      initialValue: _funcionarioSelecionado,
                      items: funcionarioProvider.funcionarios.map((f) {
                        return DropdownMenuItem(
                          value: f.id,
                          child: Text(f.nome),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _funcionarioSelecionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selecionar Tipo de Ponto
                    DropdownButtonFormField<TipoPonto>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Registro',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      initialValue: _tipoSelecionado,
                      items: TipoPonto.values.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Row(
                            children: [
                              Icon(tipo.icon, color: tipo.color, size: 20),
                              const SizedBox(width: 8),
                              Text(tipo.label),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoSelecionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selecionar Método de Autenticação
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Método de Autenticação',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      initialValue: _metodoAutenticacao,
                      items: _metodos.map((metodo) {
                        return DropdownMenuItem(
                          value: metodo,
                          child: Text(metodo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _metodoAutenticacao = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botão Registrar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _registrando || _funcionarioSelecionado == null || _tipoSelecionado == null
                            ? null
                            : _registrarPonto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _registrando
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle),
                        label: Text(
                          _registrando ? 'Registrando...' : 'Registrar Ponto',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Lista de Últimos Registros
            const Text(
              '📋 Últimos Registros',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: pontoProvider.carregando
                  ? const Center(child: CircularProgressIndicator())
                  : pontoProvider.registros.isEmpty
                      ? const Center(
                          child: Text('Nenhum registro encontrado'),
                        )
                      : ListView.builder(
                          itemCount: pontoProvider.registros.length,
                          itemBuilder: (context, index) {
                            final registro = pontoProvider.registros[index];
                            return _buildRegistroCard(registro);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistroCard(RegistroPonto registro) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: registro.tipo.color.withValues(alpha: 0.2),
          child: Icon(
            registro.tipo.icon,
            color: registro.tipo.color,
          ),
        ),
        title: Text(
          '${registro.funcionarioNome} - ${registro.tipo.label}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${registro.endereco}'),
            Text('🔐 ${registro.metodoAutenticacao}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              registro.horaFormatada,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              registro.dataFormatada,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarPonto() async {
    // 🔥 Guardar referências ANTES do async
    final messenger = ScaffoldMessenger.of(context);
    final pontoProvider = context.read<PontoProvider>();
    final funcionarioProvider = context.read<FuncionarioProvider>();

    if (_funcionarioSelecionado == null || _tipoSelecionado == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _registrando = true);

    try {
      final funcionario = funcionarioProvider.buscarPorId(_funcionarioSelecionado!);

      if (funcionario == null) {
        throw Exception('Funcionário não encontrado');
      }

      await pontoProvider.registrarPonto(
        funcionarioId: funcionario.id,
        funcionarioNome: funcionario.nome,
        tipo: _tipoSelecionado!,
        metodoAutenticacao: _metodoAutenticacao ?? 'Senha',
      );

      await pontoProvider.carregarRegistros();

      if (mounted) {
        setState(() {
          _tipoSelecionado = null;
          _metodoAutenticacao = null;
        });

        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Ponto registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
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