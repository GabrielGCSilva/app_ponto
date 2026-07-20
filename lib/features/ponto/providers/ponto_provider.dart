import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import '../models/registro_ponto_model.dart';
import '../../../core/services/localizacao_service.dart';
import '../../../core/services/validacao_ponto_service.dart';
import 'package:geolocator/geolocator.dart';

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

  // 🔥 FLAG PARA EVITAR SINCRONIZAÇÃO CONCORRENTE
  bool _sincronizando = false;

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

    // 🔥 CHAMAR carregarRegistros() PARA CRIAR O CACHE!
    await carregarRegistros();
  }

  // 🔥 CARREGAR REGISTROS DO CACHE (SHAREDPREFERENCES)
  Future<void> _carregarRegistrosCache() async {
    try {
      debugPrint('🔍 [CACHE] === INICIANDO CARREGAMENTO ===');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyRegistrosCache);

      debugPrint('🔍 [CACHE] Chave: $_keyRegistrosCache');
      debugPrint('🔍 [CACHE] jsonString é null? ${jsonString == null}');

      if (jsonString != null) {
        debugPrint(
          '🔍 [CACHE] jsonString (primeiros 200 chars): ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}',
        );

        final List<dynamic> list = List<dynamic>.from(jsonDecode(jsonString));
        _registros = list.map((e) {
          final data = e as Map<String, dynamic>;
          // 🔥 USAR O ID SALVO NO CACHE
          final id =
              data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
          return RegistroPonto.fromFirestore(data, id);
        }).toList();
        debugPrint(
          '📋 [PONTO] Registros carregados do cache: ${_registros.length}',
        );

        // 🔥 LOG DOS IDs PARA DEBUG
        debugPrint(
          '🔍 [CACHE] IDs carregados: ${_registros.map((r) => r.id).toList()}',
        );
      } else {
        debugPrint('⚠️ [CACHE] NENHUM DADO ENCONTRADO no SharedPreferences');
      }
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao carregar cache de registros: $e');
    }
  }

  // 🔥 SALVAR REGISTROS NO CACHE (SHAREDPREFERENCES)
  Future<void> _salvarRegistrosCache() async {
    try {
      debugPrint('💾 [CACHE] === INICIANDO SALVAMENTO ===');
      debugPrint('💾 [CACHE] _registros.length = ${_registros.length}');

      if (_registros.isEmpty) {
        debugPrint(
          '⚠️ [CACHE] ATENÇÃO: _registros está vazio! Nada será salvo!',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      // 🔥 SALVAR COM ID INCLUÍDO
      final jsonString = jsonEncode(
        _registros.map((r) {
          return {'id': r.id, ...r.toFirestore()};
        }).toList(),
      );

      debugPrint('💾 [CACHE] Tamanho do JSON: ${jsonString.length} caracteres');
      debugPrint(
        '💾 [CACHE] JSON (primeiros 300 chars): ${jsonString.substring(0, jsonString.length > 300 ? 300 : jsonString.length)}',
      );

      await prefs.setString(_keyRegistrosCache, jsonString);

      // 🔥 VERIFICAR SE SALVOU
      final saved = prefs.getString(_keyRegistrosCache);
      debugPrint('💾 [CACHE] Verificação: saved é null? ${saved == null}');
      debugPrint(
        '💾 [CACHE] ✅ ${_registros.length} registros salvos com sucesso!',
      );
    } catch (e) {
      debugPrint('❌ [CACHE] ERRO ao salvar: $e');
      debugPrint('❌ [CACHE] Stacktrace: ${StackTrace.current}');
    }
  }

  // 🔥 SALVAR CACHE FORÇADO (SOLUÇÃO DEFINITIVA)
  Future<void> salvarCacheAgora() async {
    try {
      if (_registros.isEmpty) {
        debugPrint('⚠️ [CACHE] _registros vazio, nada para salvar');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      // 🔥 SALVAR COM ID INCLUÍDO
      final jsonString = jsonEncode(
        _registros.map((r) {
          return {'id': r.id, ...r.toFirestore()};
        }).toList(),
      );
      await prefs.setString(_keyRegistrosCache, jsonString);
      debugPrint(
        '✅ [CACHE] ${_registros.length} registros SALVOS COM SUCESSO!',
      );
    } catch (e) {
      debugPrint('❌ [CACHE] Erro crítico ao salvar: $e');
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

  // 🔥 SINCRONIZAR FILA COM O FIRESTORE (COM VERIFICAÇÃO DE DUPLICATA)
  Future<void> _sincronizarFila() async {
    await _carregarFilaPendentes();

    if (_filaPendentes.isEmpty) {
      debugPrint('📋 [PONTO] Fila vazia, nada para sincronizar');
      return;
    }

    debugPrint(
      '🔄 [PONTO] Sincronizando ${_filaPendentes.length} registros...',
    );

    // 🔥 FAZER UMA CÓPIA DA FILA PARA ITERAR
    final filaCopia = List<Map<String, dynamic>>.from(_filaPendentes);
    final List<Map<String, dynamic>> sincronizados = [];

    for (var item in filaCopia) {
      try {
        final registroData = item['registro'];
        final id =
            registroData['id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();

        // 🔥 VERIFICAR SE O REGISTRO JÁ EXISTE NO FIRESTORE
        final doc = await _firestore
            .collection('registros_ponto')
            .doc(id)
            .get();

        if (doc.exists) {
          debugPrint(
            '⚠️ [PONTO] Registro $id já existe no Firestore, ignorando...',
          );
          sincronizados.add(item);
          continue;
        }

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

    // 🔥 REMOVER APENAS OS ITENS SINCRONIZADOS
    final idsSincronizados = sincronizados
        .map((s) => s['registro']['id'])
        .toSet();

    _filaPendentes.removeWhere(
      (item) => idsSincronizados.contains(item['registro']['id']),
    );

    await _salvarFilaPendentes();

    debugPrint(
      '✅ [PONTO] Sincronização concluída! Restam ${_filaPendentes.length} pendentes',
    );
  }

  // 🔥 MÉTODO PARA SINCRONIZAR AO VOLTAR A INTERNET (COM BLOQUEIO)
  Future<void> sincronizarSeOnline() async {
    // 🔥 EVITAR SINCRONIZAÇÃO CONCORRENTE
    if (_sincronizando) {
      debugPrint('⚠️ [PONTO] Sincronização já em andamento, ignorando...');
      return;
    }

    final isOnline = await _verificarInternet();
    if (isOnline) {
      _sincronizando = true;
      debugPrint('🔒 [PONTO] Iniciando sincronização online...');

      try {
        await _carregarFilaPendentes();
        if (_filaPendentes.isNotEmpty) {
          debugPrint(
            '📡 [PONTO] Sincronizando ${_filaPendentes.length} registros pendentes...',
          );
          await _sincronizarFila();
        }
        await sincronizarEnderecosPendentes();
      } catch (e) {
        debugPrint('❌ [PONTO] Erro na sincronização online: $e');
      } finally {
        _sincronizando = false;
        debugPrint('🔓 [PONTO] Sincronização online finalizada');
      }
    }
  }

  // 🔥 🔥 🔥 OBTER LOCALIZAÇÃO - VERIFICA PERMISSÃO E GPS PRIMEIRO 🔥 🔥 🔥
  Future<({double lat, double lng, String endereco, bool pendente})>
  _obterLocalizacao({
    double? latitude,
    double? longitude,
    String? endereco,
  }) async {
    // 🔥 🔥 🔥 VERIFICAR PERMISSÃO ANTES DE TUDO 🔥 🔥 🔥
    final temPermissao = await localizacaoService.isLocationAvailable();
    if (!temPermissao) {
      debugPrint('📍 [PONTO] PERMISSÃO NEGADA - NÃO É POSSÍVEL REGISTRAR PONTO!');
      throw Exception('⚠️ Conceda permissão de localização para registrar o ponto!');
    }

    // 🔥 VERIFICAR SE O GPS ESTÁ ATIVO
    final gpsAtivo = await Geolocator.isLocationServiceEnabled();
    if (!gpsAtivo) {
      debugPrint('📍 [PONTO] GPS DESLIGADO - NÃO É POSSÍVEL REGISTRAR PONTO!');
      throw Exception('⚠️ Ative o GPS para registrar o ponto!');
    }

    // 🔥 PRIORIDADE 1: Localização recebida por parâmetro (da Home)
    if (latitude != null && longitude != null && endereco != null) {
      debugPrint('📍 [PONTO] Usando localização recebida por parâmetro');
      return (
        lat: latitude,
        lng: longitude,
        endereco: endereco,
        pendente: false,
      );
    }

    // 🔥 BUSCAR LOCALIZAÇÃO
    try {
      debugPrint('📍 [PONTO] Buscando localização do service...');
      final localizacao = await localizacaoService.getLocalizacaoCompleta();
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

    // 🔥 SE CHEGOU AQUI, BLOQUEIA O PONTO
    debugPrint('📍 [PONTO] NÃO FOI POSSÍVEL OBTER LOCALIZAÇÃO - PONTO BLOQUEADO!');
    throw Exception('⚠️ Não foi possível obter sua localização. Tente novamente.');
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

    // 🔥 LOG PARA DEBUG - ANTES DO FILTRO
    debugPrint('🔍 [DEBUG] Registros antes do filtro:');
    for (var r in todosRegistros) {
      if (r.funcionarioId == funcionarioId) {
        debugPrint(
          '  📌 ${r.tipo.label} | ID: ${r.id} | original: ${r.dataHora} | local: ${r.dataHora.toLocal()}',
        );
      }
    }

    debugPrint(
      '🔍 [PONTO] Total de registros para filtrar: ${todosRegistros.length}',
    );
    debugPrint('🔍 [PONTO] FuncionarioId buscado: $funcionarioId');
    debugPrint('🔍 [PONTO] Início: $inicio');
    debugPrint('🔍 [PONTO] Fim: $fim');

    final registrosHoje = <RegistroPonto>[];
    final idsVistos = <String>{};

    // 🔥 CONVERTER PARA O MESMO FUSO HORÁRIO
    final inicioLocal = inicio.toLocal();
    final fimLocal = fim.toLocal();

    for (var r in todosRegistros) {
      if (!idsVistos.contains(r.id)) {
        idsVistos.add(r.id);
        final dataRegistroLocal = r.dataHora.toLocal();

        if (r.funcionarioId == funcionarioId &&
            !dataRegistroLocal.isBefore(inicioLocal) &&
            dataRegistroLocal.isBefore(fimLocal)) {
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

  // 🔥 CARREGAR REGISTROS - VERSÃO DEFINITIVA
  Future<void> carregarRegistros({String? funcionarioId}) async {
    debugPrint('🚨🚨🚨 ENTROU NO carregarRegistros NOVO 🚨🚨🚨');
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      // 🔥 CARREGAR FILA PENDENTES
      await _carregarFilaPendentes();

      // 🔥 VERIFICAR INTERNET
      final isOnline = await _verificarInternet();

      if (isOnline) {
        debugPrint('📡 [PONTO] Online, sincronizando pendentes...');
        await sincronizarSeOnline();
        await _carregarFilaPendentes();

        Query<Map<String, dynamic>> query = _firestore.collection(
          'registros_ponto',
        );

        if (funcionarioId != null) {
          query = query.where('funcionarioId', isEqualTo: funcionarioId);
        }

        try {
          debugPrint('📡 [PONTO] Buscando do servidor...');
          final snapshot = await query
              .orderBy('dataHora', descending: true)
              .limit(100)
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 5));

          _registros = snapshot.docs.map((doc) {
            return RegistroPonto.fromFirestore(doc.data(), doc.id);
          }).toList();
          debugPrint('✅ [PONTO] ${_registros.length} registros do servidor');
        } catch (e) {
          debugPrint('⚠️ [PONTO] Erro ao buscar servidor: $e');

          try {
            debugPrint('📡 [PONTO] Fallback: buscando do cache Firestore...');
            final snapshot = await query
                .orderBy('dataHora', descending: true)
                .limit(100)
                .get(const GetOptions(source: Source.cache));

            _registros = snapshot.docs.map((doc) {
              return RegistroPonto.fromFirestore(doc.data(), doc.id);
            }).toList();
            debugPrint(
              '✅ [PONTO] ${_registros.length} registros do cache Firestore',
            );
          } catch (e2) {
            debugPrint('⚠️ [PONTO] Fallback Firestore falhou: $e2');
            await _carregarRegistrosCache();
          }
        }
      } else {
        debugPrint('📴 [PONTO] Offline, carregando cache local...');
        await _carregarRegistrosCache();
      }

      // 🔥 ADICIONAR REGISTROS DA FILA
      if (_filaPendentes.isNotEmpty) {
        debugPrint(
          '📋 [PONTO] Adicionando ${_filaPendentes.length} registros pendentes...',
        );
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

      // 🔥 SALVAR CACHE FORÇADO
      debugPrint(
        '💾 [PONTO] FORÇANDO salvamento de ${_registros.length} registros...',
      );
      await salvarCacheAgora();

      _carregando = false;
      notifyListeners();
      debugPrint('✅ Registros de ponto carregados: ${_registros.length}');
    } catch (e) {
      _carregando = false;
      _erro = e.toString();
      notifyListeners();
      debugPrint('❌ Erro ao carregar registros: $e');

      // 🔥 FALLBACK DE EMERGÊNCIA
      await _carregarRegistrosCache();
      if (_registros.isNotEmpty) {
        debugPrint(
          '✅ [PONTO] Fallback: ${_registros.length} registros do SharedPreferences',
        );
        _erro = null;
        notifyListeners();
      }
    }
  }

  // 🔥 REGISTRAR PONTO
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
    BuildContext? context,
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
        debugPrint(
          '📝 [PONTO] Admin detectado, exibindo diálogo de confirmação...',
        );

        final confirmar = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Atenção!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Este ponto já foi registrado hoje para este funcionário.',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
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
                  style: TextStyle(fontSize: 12, color: Colors.red.shade400),
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

        if (confirmar != true) {
          debugPrint('📝 [PONTO] Admin cancelou a sobrescrita');
          throw Exception('Operação cancelada pelo administrador');
        }

        debugPrint('📝 [PONTO] Admin confirmou sobrescrita!');

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
          context: null,
        );
        return;
      }

      if (!validacao.permitido) {
        throw Exception(validacao.mensagem);
      }

      if (!sobrescrever) {
        final registrosExistentes = registrosHoje
            .where((r) => r.tipo == tipo)
            .toList();

        if (registrosExistentes.isNotEmpty) {
          throw Exception('${tipo.label} já registrado hoje!');
        }
      } else {
        final registrosExistentes = registrosHoje
            .where((r) => r.tipo == tipo)
            .toList();

        if (registrosExistentes.isNotEmpty) {
          debugPrint(
            '📝 [PONTO] Registro antigo encontrado, deletando para sobrescrever...',
          );
          for (var doc in registrosExistentes) {
            try {
              await _firestore
                  .collection('registros_ponto')
                  .doc(doc.id)
                  .delete();
            } catch (e) {
              debugPrint('⚠️ [PONTO] Erro ao deletar do Firestore: $e');
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

      // 🔥 VERIFICAR SE O REGISTRO JÁ EXISTE NO CACHE (EVITAR DUPLICATAS)
      // 🔥 SÓ VERIFICAR SE NÃO ESTIVER SOBRESCREVENDO
      if (!sobrescrever) {
        final registroExistente = _registros.any(
          (r) =>
              r.funcionarioId == funcionarioId &&
              r.tipo == tipo &&
              r.dataHora.day == dataHoraRegistro.day &&
              r.dataHora.month == dataHoraRegistro.month &&
              r.dataHora.year == dataHoraRegistro.year,
        );

        if (registroExistente) {
          debugPrint('⚠️ [PONTO] Registro duplicado detectado, ignorando...');
          throw Exception('Este ponto já foi registrado hoje!');
        }
      }

      final existeNoCache = _registros.any((r) => r.id == registro.id);
      if (!existeNoCache) {
        debugPrint('💾 [PONTO] Inserindo registro no _registros...');
        _registros.insert(0, registro);
        debugPrint(
          '💾 [PONTO] _registros agora tem ${_registros.length} registros',
        );
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
          debugPrint('⚠️ [PONTO] Erro ao salvar no Firestore: $e');
          await _adicionarNaFila(registro);
        }
      } else {
        debugPrint('📴 [PONTO] Offline, salvando na fila');
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
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
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

  // 🔥 MÉTODO PÚBLICO PARA FORÇAR SINCRONIZAÇÃO (COM BLOQUEIO)
  Future<void> sincronizarPendentes() async {
    // 🔥 EVITAR SINCRONIZAÇÃO CONCORRENTE
    if (_sincronizando) {
      debugPrint('⚠️ [PONTO] Sincronização já em andamento, ignorando...');
      return;
    }

    _sincronizando = true;
    debugPrint('🔒 [PONTO] Iniciando sincronização...');

    try {
      final isOnline = await _verificarInternet();
      if (isOnline) {
        await _sincronizarFila();
      } else {
        debugPrint('📴 [PONTO] Offline, não foi possível sincronizar');
      }
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao sincronizar: $e');
    } finally {
      _sincronizando = false;
      debugPrint('🔓 [PONTO] Sincronização finalizada');
    }
  }
}