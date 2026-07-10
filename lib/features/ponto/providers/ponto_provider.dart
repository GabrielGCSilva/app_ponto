import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../models/registro_ponto_model.dart';
import '../../../core/services/localizacao_service.dart';
import '../../../core/services/validacao_ponto_service.dart';

class PontoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 INICIALIZAÇÃO LAZY
  LocalizacaoService? _localizacaoService;
  LocalizacaoService get localizacaoService {
    _localizacaoService ??= LocalizacaoService();
    return _localizacaoService!;
  }

  List<RegistroPonto> _registros = [];
  List<Map<String, dynamic>> _filaPendentes = [];
  bool _carregando = false;
  String? _erro;

  List<RegistroPonto> get registros => _registros;
  bool get carregando => _carregando;
  String? get erro => _erro;

  static const String _keyFilaPendentes = 'fila_pontos_pendentes';
  static const String _keyRegistrosCache = 'registros_cache';

  // 🔥 CONSTRUTOR
  PontoProvider() {
    _inicializar();
  }

  // 🔥 INICIALIZAÇÃO
  Future<void> _inicializar() async {
    await _carregarFilaPendentes();
    await _carregarRegistrosCache();
    await _verificarInternet();
    _monitorarInternet();
  }

  // 🔥 CARREGAR REGISTROS DO CACHE (SHAREDPREFERENCES)
  Future<void> _carregarRegistrosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyRegistrosCache);
      if (jsonString != null) {
        final List<dynamic> list = List<dynamic>.from(jsonDecode(jsonString));
        _registros = list.map((e) {
          return RegistroPonto.fromFirestore(
            e as Map<String, dynamic>,
            e['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          );
        }).toList();
        debugPrint(
          '📋 [PONTO] Registros carregados do cache: ${_registros.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao carregar cache de registros: $e');
    }
  }

  // 🔥 SALVAR REGISTROS NO CACHE (SHAREDPREFERENCES)
  Future<void> _salvarRegistrosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _registros.map((r) => r.toFirestore()).toList(),
      );
      await prefs.setString(_keyRegistrosCache, jsonString);
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao salvar cache de registros: $e');
    }
  }

  // 🔥 CARREGAR FILA PENDENTES
  Future<void> _carregarFilaPendentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFilaPendentes);
      if (jsonString != null) {
        final List<dynamic> list = List<dynamic>.from(jsonDecode(jsonString));
        _filaPendentes = list.map((e) => Map<String, dynamic>.from(e)).toList();
        debugPrint(
          '📋 [PONTO] Fila pendentes carregada: ${_filaPendentes.length}',
        );
      }
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao carregar fila: $e');
    }
  }

  // 🔥 SALVAR FILA PENDENTES
  Future<void> _salvarFilaPendentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_filaPendentes);
      await prefs.setString(_keyFilaPendentes, jsonString);
      debugPrint('💾 [PONTO] Fila pendentes salva: ${_filaPendentes.length}');
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao salvar fila: $e');
    }
  }

  // 🔥 ADICIONAR NA FILA OFFLINE
  Future<void> _adicionarNaFila(RegistroPonto registro) async {
    await _carregarFilaPendentes();

    _filaPendentes.add({
      'registro': registro.toFirestore(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _salvarFilaPendentes();
    debugPrint('📴 [PONTO] Registro adicionado à fila pendente');
  }

  // 🔥 VERIFICAR INTERNET (com timeout)
  Future<bool> _verificarInternet() async {
    try {
      await _firestore
          .collection('configuracoes')
          .doc('check')
          .get()
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      debugPrint('📡 [PONTO] Offline detectado');
      return false;
    }
  }

  // 🔥 MONITORAR INTERNET
  void _monitorarInternet() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (isConnected) {
        debugPrint('📡 [PONTO] Internet reconectada!');
        sincronizarSeOnline();
      }
    });
  }

  // 🔥 SALVAR NO FIRESTORE
  Future<void> _salvarNoFirestore(RegistroPonto registro) async {
    await _firestore
        .collection('registros_ponto')
        .doc(registro.id)
        .set(registro.toFirestore());
  }

  // 🔥 CONVERTER ENDEREÇOS PENDENTES (QUANDO INTERNET VOLTAR)
  Future<void> sincronizarEnderecosPendentes() async {
    final isOnline = await _verificarInternet();
    if (!isOnline) {
      debugPrint('📴 [PONTO] Offline, não foi possível converter endereços');
      return;
    }

    final pendentes = _registros.where((r) => r.enderecoPendente).toList();
    if (pendentes.isEmpty) {
      debugPrint('📋 [PONTO] Nenhum endereço pendente para converter');
      return;
    }

    debugPrint(
      '🔄 [PONTO] Convertendo ${pendentes.length} endereços pendentes...',
    );

    for (var registro in pendentes) {
      try {
        final endereco = await localizacaoService.getEnderecoCompleto(
          registro.latitude,
          registro.longitude,
        );

        if (endereco.isNotEmpty) {
          await _firestore
              .collection('registros_ponto')
              .doc(registro.id)
              .update({'endereco': endereco, 'enderecoPendente': false});

          final index = _registros.indexWhere((r) => r.id == registro.id);
          if (index != -1) {
            _registros[index] = RegistroPonto(
              id: registro.id,
              funcionarioId: registro.funcionarioId,
              funcionarioNome: registro.funcionarioNome,
              dataHora: registro.dataHora,
              tipo: registro.tipo,
              latitude: registro.latitude,
              longitude: registro.longitude,
              endereco: endereco,
              metodoAutenticacao: registro.metodoAutenticacao,
              fotoURL: registro.fotoURL,
              sincronizado: registro.sincronizado,
              dataCriacao: registro.dataCriacao,
              enderecoPendente: false,
            );
          }

          debugPrint('✅ [PONTO] Endereço convertido: $endereco');
        }
      } catch (e) {
        debugPrint('❌ [PONTO] Erro ao converter endereço: $e');
      }
    }

    await _salvarRegistrosCache();
    notifyListeners();
    debugPrint('✅ [PONTO] Conversão de endereços concluída!');
  }

  // 🔥 SINCRONIZAR FILA COM O FIRESTORE
  Future<void> _sincronizarFila() async {
    await _carregarFilaPendentes();

    if (_filaPendentes.isEmpty) {
      debugPrint('📋 [PONTO] Fila vazia, nada para sincronizar');
      return;
    }

    debugPrint(
      '🔄 [PONTO] Sincronizando ${_filaPendentes.length} registros...',
    );

    final List<Map<String, dynamic>> sincronizados = [];

    for (var item in _filaPendentes) {
      try {
        final registroData = item['registro'];
        final id =
            registroData['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();

        await _firestore
            .collection('registros_ponto')
            .doc(id)
            .set(registroData);

        sincronizados.add(item);
        debugPrint('✅ [PONTO] Registro sincronizado: $id');
      } catch (e) {
        debugPrint('❌ [PONTO] Erro ao sincronizar: $e');
      }
    }

    // 🔥 REMOVER APENAS OS ITENS SINCRONIZADOS (COMPARAÇÃO CORRETA)
    _filaPendentes.removeWhere(
      (item) => sincronizados.any(
        (s) => s['registro']['id'] == item['registro']['id'],
      ),
    );

    await _salvarFilaPendentes();

    debugPrint(
      '✅ [PONTO] Sincronização concluída! Restam ${_filaPendentes.length} pendentes',
    );
  }

  // 🔥 MÉTODO PARA SINCRONIZAR AO VOLTAR A INTERNET
  Future<void> sincronizarSeOnline() async {
    final isOnline = await _verificarInternet();
    if (isOnline) {
      await _carregarFilaPendentes();
      if (_filaPendentes.isNotEmpty) {
        debugPrint(
          '📡 [PONTO] Sincronizando ${_filaPendentes.length} registros pendentes...',
        );
        await _sincronizarFila();
      }
      await sincronizarEnderecosPendentes();
    }
  }

  // 🔥 OBTER LOCALIZAÇÃO (COM TIMEOUT CURTO E COORDENADAS REAIS OFFLINE)
  Future<({double lat, double lng, String endereco, bool pendente})>
  _obterLocalizacao({
    double? latitude,
    double? longitude,
    String? endereco,
  }) async {
    if (latitude != null && longitude != null && endereco != null) {
      return (
        lat: latitude,
        lng: longitude,
        endereco: endereco,
        pendente: false,
      );
    }

    try {
      final localizacao = await Future.any([
        localizacaoService.getLocalizacaoCompleta(),
        Future.delayed(const Duration(seconds: 3), () => null),
      ]);

      if (localizacao != null) {
        return (
          lat: localizacao['latitude'] as double,
          lng: localizacao['longitude'] as double,
          endereco: localizacao['endereco'] as String,
          pendente: false,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [PONTO] Erro ao obter localização: $e');
    }

    try {
      final position = await Future.any([
        localizacaoService.getLocalizacaoAtual(),
        Future.delayed(const Duration(seconds: 5), () => null),
      ]);

      if (position != null) {
        final lat = position.latitude;
        final lng = position.longitude;
        final coords = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
        debugPrint('📍 [PONTO] Coordenadas reais obtidas (offline): $coords');
        return (lat: lat, lng: lng, endereco: coords, pendente: true);
      }
    } catch (e) {
      debugPrint('⚠️ [PONTO] Erro ao obter coordenadas do GPS: $e');
    }

    debugPrint(
      '⚠️ [PONTO] Nenhuma localização disponível, usando fallback final',
    );
    return (
      lat: -23.5505,
      lng: -46.6333,
      endereco: 'Localização não disponível',
      pendente: false,
    );
  }

  // 🔥 MÉTODO PRIVADO PARA BUSCAR REGISTROS DO PERÍODO
  Future<List<RegistroPonto>> _buscarRegistrosDoPeriodo({
    required String funcionarioId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final isOnline = await _verificarInternet();

    List<RegistroPonto> registrosFirestore = [];

    if (isOnline) {
      try {
        final snapshot = await _firestore
            .collection('registros_ponto')
            .where('funcionarioId', isEqualTo: funcionarioId)
            .where('dataHora', isGreaterThanOrEqualTo: inicio.toIso8601String())
            .where('dataHora', isLessThan: fim.toIso8601String())
            .get()
            .timeout(const Duration(seconds: 3));

        registrosFirestore = snapshot.docs.map((doc) {
          return RegistroPonto.fromFirestore(doc.data(), doc.id);
        }).toList();

        debugPrint(
          '📡 [PONTO] ${registrosFirestore.length} registros do Firestore',
        );
      } catch (e) {
        debugPrint('⚠️ [PONTO] Erro ao buscar Firestore: $e');
      }
    } else {
      debugPrint('📴 [PONTO] Offline, usando apenas fila + cache local');
    }

    await _carregarFilaPendentes();

    final todosRegistros = <RegistroPonto>[
      ...registrosFirestore,
      ..._registros,
      ..._filaPendentes.map((item) {
        return RegistroPonto.fromFirestore(
          item['registro'],
          item['registro']['id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
        );
      }),
    ];

    final registrosHoje = <RegistroPonto>[];
    final idsVistos = <String>{};

    for (var r in todosRegistros) {
      if (!idsVistos.contains(r.id)) {
        idsVistos.add(r.id);
        final dataRegistro = r.dataHora;
        if (r.funcionarioId == funcionarioId &&
            !dataRegistro.isBefore(inicio) &&
            dataRegistro.isBefore(fim)) {
          registrosHoje.add(r);
        }
      }
    }

    debugPrint('📋 [PONTO] ${registrosHoje.length} registros para validação');
    debugPrint(
      '📋 [PONTO] Tipos: ${registrosHoje.map((r) => r.tipo.label).toList()}',
    );

    return registrosHoje;
  }

  // 🔥 BUSCAR REGISTROS DO DIA
  Future<List<RegistroPonto>> buscarRegistrosDoDia(String funcionarioId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    return await _buscarRegistrosDoPeriodo(
      funcionarioId: funcionarioId,
      inicio: inicioDia,
      fim: fimDia,
    );
  }

  // 🔥 BUSCAR REGISTROS DO DIA ESPECÍFICO
  Future<List<RegistroPonto>> buscarRegistrosDoDiaEspecifico(
    String funcionarioId,
    DateTime data,
  ) async {
    final inicioDia = DateTime(data.year, data.month, data.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    return await _buscarRegistrosDoPeriodo(
      funcionarioId: funcionarioId,
      inicio: inicioDia,
      fim: fimDia,
    );
  }

  // 🔥 CARREGAR REGISTROS - ATUALIZADO COM Source.server
  Future<void> carregarRegistros({String? funcionarioId}) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      await _carregarFilaPendentes();
      await sincronizarSeOnline();

      Query<Map<String, dynamic>> query = _firestore.collection(
        'registros_ponto',
      );

      if (funcionarioId != null) {
        query = query.where('funcionarioId', isEqualTo: funcionarioId);
      }

      // 🔥 FORÇAR BUSCA NO SERVIDOR (IGNORAR CACHE)
      final snapshot = await query
          .orderBy('dataHora', descending: true)
          .limit(100)
          .get(const GetOptions(source: Source.server));

      // 🔥 ATUALIZAR _registros COM DADOS DO FIRESTORE
      _registros = snapshot.docs.map((doc) {
        return RegistroPonto.fromFirestore(doc.data(), doc.id);
      }).toList();

      debugPrint('✅ Registros carregados do Firestore: ${_registros.length}');

      // 🔥 ADICIONAR REGISTROS DA FILA (PENDENTES)
      if (_filaPendentes.isNotEmpty) {
        for (var item in _filaPendentes) {
          try {
            final registro = RegistroPonto.fromFirestore(
              item['registro'],
              item['registro']['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
            );
            if (!_registros.any((r) => r.id == registro.id)) {
              _registros.insert(0, registro);
            }
          } catch (e) {
            debugPrint('❌ [PONTO] Erro ao carregar registro da fila: $e');
          }
        }
        debugPrint('✅ ${_filaPendentes.length} registros da fila adicionados');
      }

      // 🔥 SALVAR CACHE PARA USO OFFLINE
      await _salvarRegistrosCache();

      _carregando = false;
      notifyListeners();
      debugPrint('✅ Registros de ponto carregados: ${_registros.length}');
    } catch (e) {
      _carregando = false;
      _erro = e.toString();
      notifyListeners();
      debugPrint('❌ Erro ao carregar registros: $e');
    }
  }

  // 🔥 REGISTRAR PONTO - COM DIÁLOGO DE CONFIRMAÇÃO PARA ADMIN
  Future<void> registrarPonto({
    required String funcionarioId,
    required String funcionarioNome,
    required TipoPonto tipo,
    required String metodoAutenticacao,
    bool sobrescrever = false,
    String? fotoURL,
    DateTime? dataHora,
    String? endereco,
    double? latitude,
    double? longitude,
    bool isAdmin = false,
    BuildContext? context, // 🔥 NOVO: contexto para exibir o diálogo
  }) async {
    try {
      debugPrint('📝 [PONTO] Iniciando registro...');
      debugPrint('📝 [PONTO] Funcionário: $funcionarioNome');
      debugPrint('📝 [PONTO] Tipo: ${tipo.label}');
      debugPrint('📝 [PONTO] Método: $metodoAutenticacao');
      debugPrint('📝 [PONTO] Sobrescrever: $sobrescrever');
      debugPrint('📝 [PONTO] isAdmin: $isAdmin');

      final DateTime dataHoraRegistro = dataHora ?? DateTime.now();

      final localizacao = await _obterLocalizacao(
        latitude: latitude,
        longitude: longitude,
        endereco: endereco,
      );

      final inicioDia = DateTime(
        dataHoraRegistro.year,
        dataHoraRegistro.month,
        dataHoraRegistro.day,
      );
      final fimDia = inicioDia.add(const Duration(days: 1));

      final registrosHoje = await _buscarRegistrosDoPeriodo(
        funcionarioId: funcionarioId,
        inicio: inicioDia,
        fim: fimDia,
      );

      // 🔥 VALIDAR REGRAS DE NEGÓCIO
      final validacao = ValidacaoPontoService.validar(
        tipo: tipo,
        registrosHoje: registrosHoje,
        isAdmin: isAdmin,
        isSobrescrevendo: sobrescrever,
      );

      // 🔥 Se for Admin e precisa confirmar, EXIBE DIÁLOGO
      if (isAdmin && validacao.precisaConfirmar && context != null) {
        debugPrint('📝 [PONTO] Admin detectado, exibindo diálogo de confirmação...');
        
        final confirmar = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Atenção!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Este ponto já foi registrado hoje para este funcionário.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📌 Detalhes do registro existente:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Funcionário: $funcionarioNome',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        '• Tipo: ${tipo.label}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        '• Data: ${_formatarData(dataHoraRegistro)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Deseja sobrescrever este registro anterior?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '⚠️ O registro antigo será substituído permanentemente.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Sobrescrever'),
              ),
            ],
          ),
        );

        // 🔥 Se o usuário cancelou, interrompe
        if (confirmar != true) {
          debugPrint('📝 [PONTO] Admin cancelou a sobrescrita');
          throw Exception('Operação cancelada pelo administrador');
        }

        debugPrint('📝 [PONTO] Admin confirmou sobrescrita!');
        
        // 🔥 Chama novamente com sobrescrever = true (sem exibir novo diálogo)
        await registrarPonto(
          funcionarioId: funcionarioId,
          funcionarioNome: funcionarioNome,
          tipo: tipo,
          metodoAutenticacao: metodoAutenticacao,
          sobrescrever: true,
          fotoURL: fotoURL,
          dataHora: dataHoraRegistro,
          endereco: endereco,
          latitude: latitude,
          longitude: longitude,
          isAdmin: true,
          context: null, // 🔥 Passa null para evitar loop infinito
        );
        return;
      }

      if (!validacao.permitido) {
        throw Exception(validacao.mensagem);
      }

      // 🔥 Se não for Admin ou se já está sobrescrevendo
      if (!sobrescrever) {
        final registrosExistentes = registrosHoje
            .where((r) => r.tipo == tipo)
            .toList();

        if (registrosExistentes.isNotEmpty) {
          throw Exception('${tipo.label} já registrado hoje!');
        }
      } else {
        // 🔥 Admin sobrescrevendo: deleta registros existentes
        final registrosExistentes = registrosHoje
            .where((r) => r.tipo == tipo)
            .toList();

        if (registrosExistentes.isNotEmpty) {
          debugPrint('📝 [PONTO] Registro antigo encontrado, deletando para sobrescrever...');
          for (var doc in registrosExistentes) {
            try {
              await _firestore
                  .collection('registros_ponto')
                  .doc(doc.id)
                  .delete();
            } catch (e) {
              debugPrint('⚠️ [PONTO] Erro ao deletar do Firestore: $e (pode estar offline)');
            }
          }
          debugPrint('✅ [PONTO] Registro antigo deletado com sucesso!');
        }
      }

      final registro = RegistroPonto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        funcionarioId: funcionarioId,
        funcionarioNome: funcionarioNome,
        dataHora: dataHoraRegistro,
        tipo: tipo,
        latitude: localizacao.lat,
        longitude: localizacao.lng,
        endereco: localizacao.endereco,
        metodoAutenticacao: metodoAutenticacao,
        fotoURL: fotoURL,
        enderecoPendente: localizacao.pendente,
      );

      final existeNoCache = _registros.any((r) => r.id == registro.id);
      if (!existeNoCache) {
        _registros.insert(0, registro);
        await _salvarRegistrosCache();
        notifyListeners();
        debugPrint('✅ [PONTO] Registro salvo no cache local');
      } else {
        debugPrint('⚠️ [PONTO] Registro já existe no cache');
      }

      final isOnline = await _verificarInternet();

      if (isOnline) {
        try {
          await _salvarNoFirestore(registro);
          debugPrint('✅ [PONTO] Registro sincronizado com o Firestore!');
        } catch (e) {
          debugPrint(
            '⚠️ [PONTO] Erro ao salvar no Firestore: $e (será sincronizado depois)',
          );
          await _adicionarNaFila(registro);
        }
      } else {
        debugPrint(
          '📴 [PONTO] Offline, salvando na fila para sincronização posterior',
        );
        await _adicionarNaFila(registro);
      }
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao registrar: $e');
      rethrow;
    }
  }

  // 🔥 MÉTODO AUXILIAR PARA FORMATAR DATA
  String _formatarData(DateTime data) {
    final meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${data.day} de ${meses[data.month - 1]} de ${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  // 🔥 BUSCAR REGISTROS POR FUNCIONÁRIO
  Future<List<RegistroPonto>> buscarRegistrosPorFuncionario(
    String funcionarioId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('registros_ponto')
          .where('funcionarioId', isEqualTo: funcionarioId)
          .orderBy('dataHora', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return RegistroPonto.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar registros: $e');
      return [];
    }
  }

  // 🔥 BUSCAR REGISTROS POR PERÍODO
  Future<List<RegistroPonto>> buscarRegistrosPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
    String? funcionarioId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('registros_ponto')
          .where('dataHora', isGreaterThanOrEqualTo: inicio.toIso8601String())
          .where('dataHora', isLessThanOrEqualTo: fim.toIso8601String());

      if (funcionarioId != null) {
        query = query.where('funcionarioId', isEqualTo: funcionarioId);
      }

      final snapshot = await query.orderBy('dataHora', descending: true).get();

      return snapshot.docs.map((doc) {
        return RegistroPonto.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar registros por período: $e');
      return [];
    }
  }

  // 🔥 DELETAR REGISTRO
  Future<void> deletarRegistro(String registroId) async {
    try {
      await _firestore.collection('registros_ponto').doc(registroId).delete();
      _registros.removeWhere((r) => r.id == registroId);
      await _salvarRegistrosCache();
      notifyListeners();
      debugPrint('✅ Registro deletado: $registroId');
    } catch (e) {
      debugPrint('❌ Erro ao deletar registro: $e');
      rethrow;
    }
  }

  // 🔥 MÉTODO PÚBLICO PARA FORÇAR SINCRONIZAÇÃO
  Future<void> sincronizarPendentes() async {
    final isOnline = await _verificarInternet();
    if (isOnline) {
      await _sincronizarFila();
    } else {
      debugPrint('📴 [PONTO] Offline, não foi possível sincronizar');
    }
  }
}