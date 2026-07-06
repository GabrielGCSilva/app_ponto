import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/registro_ponto_model.dart';
import '../../../core/services/localizacao_service.dart';

class PontoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalizacaoService _localizacaoService = LocalizacaoService();

  List<RegistroPonto> _registros = [];
  List<Map<String, dynamic>> _filaPendentes = [];
  bool _carregando = false;
  String? _erro;

  List<RegistroPonto> get registros => _registros;
  bool get carregando => _carregando;
  String? get erro => _erro;

  static const String _keyFilaPendentes = 'fila_pontos_pendentes';

  // 🔥 CARREGAR FILA PENDENTES
  Future<void> _carregarFilaPendentes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyFilaPendentes);
      if (jsonString != null) {
        final List<dynamic> list = List<dynamic>.from(jsonDecode(jsonString));
        _filaPendentes = list.map((e) => Map<String, dynamic>.from(e)).toList();
        debugPrint('📋 [PONTO] Fila pendentes carregada: ${_filaPendentes.length}');
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

  // 🔥 SALVAR NO FIRESTORE
  Future<void> _salvarNoFirestore(RegistroPonto registro) async {
    await _firestore
        .collection('registros_ponto')
        .doc(registro.id)
        .set(registro.toFirestore());
  }

  // 🔥 SINCRONIZAR FILA COM O FIRESTORE
  Future<void> _sincronizarFila() async {
    await _carregarFilaPendentes();
    
    if (_filaPendentes.isEmpty) {
      debugPrint('📋 [PONTO] Fila vazia, nada para sincronizar');
      return;
    }

    debugPrint('🔄 [PONTO] Sincronizando ${_filaPendentes.length} registros...');
    
    final List<Map<String, dynamic>> sincronizados = [];

    for (var item in _filaPendentes) {
      try {
        final registroData = item['registro'];
        final id = registroData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
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

    _filaPendentes.removeWhere((item) => sincronizados.contains(item));
    await _salvarFilaPendentes();
    
    debugPrint('✅ [PONTO] Sincronização concluída! Restam ${_filaPendentes.length} pendentes');
  }

  Future<void> carregarRegistros({String? funcionarioId}) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      await _carregarFilaPendentes();

      Query<Map<String, dynamic>> query = _firestore.collection('registros_ponto');

      if (funcionarioId != null) {
        query = query.where('funcionarioId', isEqualTo: funcionarioId);
      }

      final snapshot = await query
          .orderBy('dataHora', descending: true)
          .limit(100)
          .get();

      _registros = snapshot.docs.map((doc) {
        return RegistroPonto.fromFirestore(doc.data(), doc.id);
      }).toList();

      // 🔥 ADICIONAR REGISTROS DA FILA
      if (_filaPendentes.isNotEmpty) {
        for (var item in _filaPendentes) {
          try {
            final registro = RegistroPonto.fromFirestore(
              item['registro'], 
              item['registro']['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()
            );
            // 🔥 Verificar se já não existe na lista
            if (!_registros.any((r) => r.id == registro.id)) {
              _registros.insert(0, registro);
            }
          } catch (e) {
            debugPrint('❌ [PONTO] Erro ao carregar registro da fila: $e');
          }
        }
        debugPrint('✅ ${_filaPendentes.length} registros da fila adicionados');
      }

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

  // 🔥 BUSCAR REGISTROS DO DIA
  Future<List<RegistroPonto>> buscarRegistrosDoDia(String funcionarioId) async {
    final hoje = DateTime.now();
    final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('registros_ponto')
        .where('funcionarioId', isEqualTo: funcionarioId)
        .where('dataHora', isGreaterThanOrEqualTo: inicioDia.toIso8601String())
        .where('dataHora', isLessThan: fimDia.toIso8601String())
        .get();

    return snapshot.docs.map((doc) {
      return RegistroPonto.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // 🔥 BUSCAR REGISTROS DO DIA ESPECÍFICO
  Future<List<RegistroPonto>> buscarRegistrosDoDiaEspecifico(
    String funcionarioId,
    DateTime data,
  ) async {
    final inicioDia = DateTime(data.year, data.month, data.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('registros_ponto')
        .where('funcionarioId', isEqualTo: funcionarioId)
        .where('dataHora', isGreaterThanOrEqualTo: inicioDia.toIso8601String())
        .where('dataHora', isLessThan: fimDia.toIso8601String())
        .get();

    return snapshot.docs.map((doc) {
      return RegistroPonto.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  // 🔥 REGISTRAR PONTO - COM FILA OFFLINE
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
  }) async {
    try {
      debugPrint('📝 [PONTO] Iniciando registro...');
      debugPrint('📝 [PONTO] Funcionário: $funcionarioNome');
      debugPrint('📝 [PONTO] Tipo: ${tipo.label}');
      debugPrint('📝 [PONTO] Método: $metodoAutenticacao');
      debugPrint('📝 [PONTO] Sobrescrever: $sobrescrever');

      final DateTime dataHoraRegistro = dataHora ?? DateTime.now();

      // 🔥 LOCALIZAÇÃO
      double lat;
      double lng;
      String end;

      if (latitude != null && longitude != null && endereco != null) {
        lat = latitude;
        lng = longitude;
        end = endereco;
        debugPrint('📍 [PONTO] Localização fornecida: $end');
      } else {
        try {
          final localizacao = await _localizacaoService.getLocalizacaoCompleta();
          if (localizacao != null) {
            lat = localizacao['latitude'] as double;
            lng = localizacao['longitude'] as double;
            end = localizacao['endereco'] as String;
            debugPrint('📍 [PONTO] Localização obtida: $end');
          } else {
            lat = -23.5505;
            lng = -46.6333;
            end = 'Localização não disponível (Desktop)';
            debugPrint('⚠️ [PONTO] Localização indisponível, usando fallback');
          }
        } catch (e) {
          lat = -23.5505;
          lng = -46.6333;
          end = 'Localização não disponível (Desktop)';
          debugPrint('⚠️ [PONTO] Erro ao obter localização: $e');
        }
      }

      // 🔥 VERIFICAR SE ESTÁ ONLINE
      final isOnline = await _verificarInternet();
      debugPrint('📡 [PONTO] Status da internet: ${isOnline ? "ONLINE" : "OFFLINE"}');

      // 🔥 CRIAR REGISTRO
      final registro = RegistroPonto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        funcionarioId: funcionarioId,
        funcionarioNome: funcionarioNome,
        dataHora: dataHoraRegistro,
        tipo: tipo,
        latitude: lat,
        longitude: lng,
        endereco: end,
        metodoAutenticacao: metodoAutenticacao,
        fotoURL: fotoURL,
      );

      // 🔥 SALVAR LOCALMENTE PRIMEIRO (feedback imediato)
      _registros.insert(0, registro);
      notifyListeners();
      debugPrint('✅ [PONTO] Registro salvo localmente!');

      // 🔥 SE ESTIVER ONLINE, SALVAR NO FIRESTORE
      if (isOnline) {
        try {
          await _salvarNoFirestore(registro);
          debugPrint('✅ [PONTO] Registro sincronizado com o Firestore!');
        } catch (e) {
          debugPrint('⚠️ [PONTO] Erro ao salvar no Firestore: $e (será sincronizado depois)');
          await _adicionarNaFila(registro);
        }
      } else {
        // 🔥 OFFLINE: SALVAR NA FILA
        debugPrint('📴 [PONTO] Offline, salvando na fila para sincronização posterior');
        await _adicionarNaFila(registro);
      }

    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao registrar: $e');
      rethrow;
    }
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