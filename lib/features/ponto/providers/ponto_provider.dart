import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registro_ponto_model.dart';
import '../../../core/services/localizacao_service.dart';

class PontoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalizacaoService _localizacaoService = LocalizacaoService();

  List<RegistroPonto> _registros = [];
  bool _carregando = false;
  String? _erro;

  List<RegistroPonto> get registros => _registros;
  bool get carregando => _carregando;
  String? get erro => _erro;

  Future<void> carregarRegistros({String? funcionarioId}) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      Query<Map<String, dynamic>> query = _firestore.collection(
        'registros_ponto',
      );

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

  // 🔥 Buscar registros do dia para um funcionário
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

  // 🔥 Buscar registros do dia específico (para data editada)
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

  // 🔥 REGISTRAR PONTO - CORRIGIDO
  Future<void> registrarPonto({
    required String funcionarioId,
    required String funcionarioNome,
    required TipoPonto tipo,
    required String metodoAutenticacao,
    bool sobrescrever = false,
    String? fotoURL,
    // 🔥 PARÂMETROS OPCIONAIS (para Admin editar)
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

      // 🔥 Usar data/hora fornecida ou atual
      final DateTime dataHoraRegistro = dataHora ?? DateTime.now();
      debugPrint('📝 [PONTO] Data/Hora: $dataHoraRegistro');

      // 🔥 USAR LOCALIZAÇÃO FORNECIDA OU BUSCAR
      double lat;
      double lng;
      String end;

      if (latitude != null && longitude != null && endereco != null) {
        // 🔥 Usar dados fornecidos pelo Admin (sem o operador '!' desnecessário)
        lat = latitude;
        lng = longitude;
        end = endereco;
        debugPrint('📍 [PONTO] Localização fornecida: $end');
      } else {
        // 🔥 Buscar localização atual
        try {
          final localizacao = await _localizacaoService
              .getLocalizacaoCompleta();
          if (localizacao != null) {
            lat = localizacao['latitude'] as double;
            lng = localizacao['longitude'] as double;
            end = localizacao['endereco'] as String;
            debugPrint('📍 [PONTO] Localização obtida: $end');
          } else {
            throw Exception('Localização nula');
          }
        } catch (e) {
          debugPrint(
            '⚠️ [PONTO] Localização indisponível, usando fallback (Desktop)',
          );
          lat = -23.5505;
          lng = -46.6333;
          end = 'Desktop - Localização simulada';
        }
      }

      // 🔥 VERIFICAR SE JÁ EXISTE REGISTRO DO MESMO TIPO NO DIA EDITADO
      final inicioDia = DateTime(
        dataHoraRegistro.year,
        dataHoraRegistro.month,
        dataHoraRegistro.day,
      );
      final fimDia = inicioDia.add(const Duration(days: 1));

      final registrosHoje = await _firestore
          .collection('registros_ponto')
          .where('funcionarioId', isEqualTo: funcionarioId)
          .where(
            'dataHora',
            isGreaterThanOrEqualTo: inicioDia.toIso8601String(),
          )
          .where('dataHora', isLessThan: fimDia.toIso8601String())
          .where('tipo', isEqualTo: tipo.name)
          .get();

      if (registrosHoje.docs.isNotEmpty) {
        if (sobrescrever) {
          debugPrint(
            '📝 [PONTO] Registro antigo encontrado, deletando para sobrescrever...',
          );
          for (var doc in registrosHoje.docs) {
            await doc.reference.delete();
          }
          debugPrint('✅ [PONTO] Registro antigo deletado com sucesso!');
        } else {
          throw Exception('${tipo.label} já registrado hoje!');
        }
      }

      // 🔥 CRIAR REGISTRO COM DATA/HORA CORRETA
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

      // 🔥 SALVAR NO FIRESTORE
      await _firestore
          .collection('registros_ponto')
          .doc(registro.id)
          .set(registro.toFirestore());

      // 🔥 ATUALIZAR LISTA LOCAL
      _registros.insert(0, registro);
      notifyListeners();

      debugPrint('✅ [PONTO] Registro salvo com sucesso! ID: ${registro.id}');
    } catch (e) {
      debugPrint('❌ [PONTO] Erro ao registrar: $e');
      rethrow;
    }
  }

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
}
