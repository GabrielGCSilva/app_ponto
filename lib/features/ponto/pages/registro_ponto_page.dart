import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ponto_provider.dart';
import '../models/registro_ponto_model.dart';
import '../../funcionario/providers/funcionario_provider.dart';
import '../../../core/services/localizacao_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // 🔥 CAMPOS MANUAIS
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaController = TextEditingController();
  final TextEditingController _localController = TextEditingController();
  bool _usarLocalizacaoAtual = true;
  bool _usarDataHoraAtual = true;

  final List<String> _metodos = ['Senha', 'Digital', 'Facial'];

  // 🔥 INICIALIZAÇÃO LAZY
  LocalizacaoService? _localizacaoServiceInstance;
  LocalizacaoService get localizacaoService {
    _localizacaoServiceInstance ??= LocalizacaoService();
    return _localizacaoServiceInstance!;
  }

  @override
  void initState() {
    super.initState();
    _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _horaController.text = DateFormat('HH:mm').format(DateTime.now());
    _localController.text = 'Carregando localização...';
    _carregarLocalizacaoAtual();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PontoProvider>().carregarRegistros();
    });
  }

  Future<void> _carregarLocalizacaoAtual() async {
    try {
      final endereco = await localizacaoService.getEnderecoAtual();
      if (mounted) {
        setState(() {
          _localController.text = endereco;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localController.text = 'Local não identificado';
        });
      }
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _horaController.dispose();
    _localController.dispose();
    super.dispose();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              pontoProvider.carregarRegistros();
              _carregarLocalizacaoAtual();
            },
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Row(
        children: [
          // 🔥 Painel Esquerdo: Formulário
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📝 Registrar Ponto',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Funcionário
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Funcionário *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      const SizedBox(height: 12),

                      // Tipo de Ponto
                      DropdownButtonFormField<TipoPonto>(
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Registro *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        initialValue: _tipoSelecionado,
                        items: TipoPonto.values.map((tipo) {
                          return DropdownMenuItem(
                            value: tipo,
                            child: Row(
                              children: [
                                Icon(tipo.icon, color: tipo.color, size: 18),
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
                      const SizedBox(height: 12),

                      // Método de Autenticação
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Método de Autenticação *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      const SizedBox(height: 16),

                      // 🔥 SEÇÃO DATA E HORA
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dataController,
                                    decoration: const InputDecoration(
                                      labelText: 'Data',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.calendar_today, size: 18),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    readOnly: _usarDataHoraAtual,
                                    onTap: _usarDataHoraAtual ? null : _selecionarData,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _horaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Hora',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time, size: 18),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                    readOnly: _usarDataHoraAtual,
                                    onTap: _usarDataHoraAtual ? null : _selecionarHora,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _usarDataHoraAtual ? Icons.toggle_on : Icons.toggle_off,
                                    color: _usarDataHoraAtual ? Colors.blue : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _usarDataHoraAtual = !_usarDataHoraAtual;
                                      if (_usarDataHoraAtual) {
                                        _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
                                        _horaController.text = DateFormat('HH:mm').format(DateTime.now());
                                      }
                                    });
                                  },
                                  tooltip: _usarDataHoraAtual ? 'Usando data/hora atual' : 'Editar manualmente',
                                ),
                              ],
                            ),
                            if (!_usarDataHoraAtual)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '⚠️ Editando manualmente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🔥 SEÇÃO LOCALIZAÇÃO
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _localController,
                                decoration: const InputDecoration(
                                  labelText: 'Local',
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.location_on, size: 18),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                readOnly: _usarLocalizacaoAtual,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _usarLocalizacaoAtual ? Icons.toggle_on : Icons.toggle_off,
                                color: _usarLocalizacaoAtual ? Colors.blue : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _usarLocalizacaoAtual = !_usarLocalizacaoAtual;
                                  if (_usarLocalizacaoAtual) {
                                    _carregarLocalizacaoAtual();
                                  }
                                });
                              },
                              tooltip: _usarLocalizacaoAtual ? 'Usando localização atual' : 'Editar manualmente',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botão Registrar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _registrando || _funcionarioSelecionado == null || _tipoSelecionado == null
                              ? null
                              : _registrarPonto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _registrando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 20),
                          label: Text(
                            _registrando ? 'Registrando...' : 'Registrar Ponto',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🔥 Painel Direito: Lista de Registros
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📋 Últimos Registros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pontoProvider.registros.length} registros',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: pontoProvider.carregando
                        ? const Center(child: CircularProgressIndicator())
                        : pontoProvider.registros.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history, size: 48, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Nenhum registro encontrado',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildRegistroCard(RegistroPonto registro) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: registro.tipo.color.withValues(alpha: 0.2),
          child: Icon(
            registro.tipo.icon,
            color: registro.tipo.color,
            size: 16,
          ),
        ),
        title: Text(
          '${registro.funcionarioNome} - ${registro.tipo.label}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '📍 ${registro.endereco}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              registro.horaFormatada,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              registro.dataFormatada,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 MÉTODOS PARA SELECIONAR DATA E HORA
  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd/MM/yyyy').parse(_dataController.text),
      firstDate: DateTime(2020),
      lastDate: hoje,
    );
    if (dataSelecionada != null) {
      setState(() {
        _dataController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada);
      });
    }
  }

  Future<void> _selecionarHora() async {
    final horaAtual = DateFormat('HH:mm').parse(_horaController.text);
    final horaSelecionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(horaAtual),
    );
    if (horaSelecionada != null) {
      setState(() {
        final dataHora = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          horaSelecionada.hour,
          horaSelecionada.minute,
        );
        _horaController.text = DateFormat('HH:mm').format(dataHora);
      });
    }
  }

  // 🔥 REGISTRAR PONTO
  Future<void> _registrarPonto() async {
    // 🔥 Guardar referências ANTES do async
    final messenger = ScaffoldMessenger.of(context);
    final pontoProvider = context.read<PontoProvider>();
    final funcionarioProvider = context.read<FuncionarioProvider>();

    if (_funcionarioSelecionado == null || _tipoSelecionado == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos obrigatórios'),
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

      // 🔥 Construir data/hora
      DateTime dataHora;
      if (_usarDataHoraAtual) {
        dataHora = DateTime.now();
      } else {
        final dataParts = _dataController.text.split('/');
        final horaParts = _horaController.text.split(':');
        dataHora = DateTime(
          int.parse(dataParts[2]),
          int.parse(dataParts[1]),
          int.parse(dataParts[0]),
          int.parse(horaParts[0]),
          int.parse(horaParts[1]),
        );
      }

      // 🔥 Obter localização
      String endereco;
      double latitude = 0.0;
      double longitude = 0.0;

      if (_usarLocalizacaoAtual) {
        final loc = await localizacaoService.getLocalizacaoCompleta();
        if (loc != null) {
          endereco = loc['endereco'] as String;
          latitude = loc['latitude'] as double;
          longitude = loc['longitude'] as double;
        } else {
          endereco = 'Local não identificado';
        }
      } else {
        endereco = _localController.text;
      }

      // 🔥 Criar registro
      final registro = RegistroPonto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        funcionarioId: funcionario.id,
        funcionarioNome: funcionario.nome,
        dataHora: dataHora,
        tipo: _tipoSelecionado!,
        latitude: latitude,
        longitude: longitude,
        endereco: endereco,
        metodoAutenticacao: _metodoAutenticacao ?? 'Senha',
      );

      // 🔥 Salvar no Firestore
      await FirebaseFirestore.instance
          .collection('registros_ponto')
          .doc(registro.id)
          .set(registro.toFirestore());

      // 🔥 Recarregar registros
      await pontoProvider.carregarRegistros();

      if (mounted) {
        setState(() {
          _tipoSelecionado = null;
          _metodoAutenticacao = null;
          if (!_usarDataHoraAtual) {
            _dataController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
            _horaController.text = DateFormat('HH:mm').format(DateTime.now());
          }
          if (!_usarLocalizacaoAtual) {
            _localController.text = 'Localização atual';
          }
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