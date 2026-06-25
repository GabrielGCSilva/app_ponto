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

  // 🔥 MÉTODO REGISTRAR PONTO COM SOBRESCREVER
  Future<void> registrarPonto({
    required String funcionarioId,
    required String funcionarioNome,
    required TipoPonto tipo,
    required String metodoAutenticacao,
    bool sobrescrever = false, // 🔥 NOVO PARÂMETRO
    String? fotoURL,
  }) async {
    try {
      debugPrint('📝 [PONTO] Iniciando registro...');
      debugPrint('📝 [PONTO] Funcionário: $funcionarioNome');
      debugPrint('📝 [PONTO] Tipo: ${tipo.label}');
      debugPrint('📝 [PONTO] Método: $metodoAutenticacao');
      debugPrint('📝 [PONTO] Sobrescrever: $sobrescrever');

      // 🔥 TENTAR OBTER LOCALIZAÇÃO COM FALLBACK
      double latitude;
      double longitude;
      String endereco;

      try {
        final localizacao = await _localizacaoService.getLocalizacaoCompleta();
        if (localizacao != null) {
          latitude = localizacao['latitude'] as double;
          longitude = localizacao['longitude'] as double;
          endereco = localizacao['endereco'] as String;
          debugPrint('📍 [PONTO] Localização obtida: $endereco');
        } else {
          throw Exception('Localização nula');
        }
      } catch (e) {
        debugPrint('⚠️ [PONTO] Localização indisponível, usando fallback (Desktop)');
        latitude = -23.5505;
        longitude = -46.6333;
        endereco = 'Desktop - Localização simulada';
      }

      // 🔥 VERIFICAR SE JÁ EXISTE REGISTRO DO MESMO TIPO HOJE
      final hoje = DateTime.now();
      final inicioDia = DateTime(hoje.year, hoje.month, hoje.day);
      final fimDia = inicioDia.add(const Duration(days: 1));

      final registrosHoje = await _firestore
          .collection('registros_ponto')
          .where('funcionarioId', isEqualTo: funcionarioId)
          .where('dataHora', isGreaterThanOrEqualTo: inicioDia.toIso8601String())
          .where('dataHora', isLessThan: fimDia.toIso8601String())
          .where('tipo', isEqualTo: tipo.name)
          .get();

      // 🔥 SE JÁ EXISTIR REGISTRO
      if (registrosHoje.docs.isNotEmpty) {
        if (sobrescrever) {
          // ✅ SOBRESCREVER: DELETAR REGISTRO ANTIGO
          debugPrint('📝 [PONTO] Registro antigo encontrado, deletando para sobrescrever...');
          for (var doc in registrosHoje.docs) {
            await doc.reference.delete();
          }
          debugPrint('✅ [PONTO] Registro antigo deletado com sucesso!');
        } else {
          // ❌ NÃO SOBRESCREVER: LANÇAR ERRO
          throw Exception('${tipo.label} já registrado hoje!');
        }
      }

      // 🔥 CRIAR REGISTRO
      final registro = RegistroPonto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        funcionarioId: funcionarioId,
        funcionarioNome: funcionarioNome,
        dataHora: DateTime.now(),
        tipo: tipo,
        latitude: latitude,
        longitude: longitude,
        endereco: endereco,
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

  Future<List<RegistroPonto>> buscarRegistrosPorFuncionario(String funcionarioId) async {
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
}