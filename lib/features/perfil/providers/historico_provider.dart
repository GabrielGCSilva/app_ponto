import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/historico_model.dart';
import '../../ponto/models/registro_ponto_model.dart';

class HistoricoProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<HistoricoMes> _historico = [];
  bool _carregando = false;
  String? _erro;

  List<HistoricoMes> get historico => _historico;
  bool get carregando => _carregando;
  String? get erro => _erro;

  // 🔥 CARREGAR HISTÓRICO DO FUNCIONÁRIO
  Future<void> carregarHistorico(String funcionarioId) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      // 🔥 Buscar todos os registros do funcionário (últimos 12 meses)
      final dataLimite = DateTime.now().subtract(const Duration(days: 365));
      
      final snapshot = await _firestore
          .collection('registros_ponto')
          .where('funcionarioId', isEqualTo: funcionarioId)
          .where('dataHora', isGreaterThanOrEqualTo: dataLimite.toIso8601String())
          .orderBy('dataHora', descending: true)
          .get();

      final registros = snapshot.docs.map((doc) {
        return RegistroPonto.fromFirestore(doc.data(), doc.id);
      }).toList();

      // 🔥 Agrupar por mês/ano
      final Map<String, List<RegistroPonto>> grupos = {};
      for (var r in registros) {
        final chave = '${r.dataHora.year}-${r.dataHora.month}';
        if (!grupos.containsKey(chave)) {
          grupos[chave] = [];
        }
        grupos[chave]!.add(r);
      }

      // 🔥 Criar lista de meses
      _historico = grupos.entries.map((entry) {
        final partes = entry.key.split('-');
        final ano = int.parse(partes[0]);
        final mes = int.parse(partes[1]);

        // Agrupar por dia dentro do mês
        final Map<String, List<RegistroPonto>> dias = {};
        for (var r in entry.value) {
          final diaChave = r.dataHora.toIso8601String().split('T')[0];
          if (!dias.containsKey(diaChave)) {
            dias[diaChave] = [];
          }
          dias[diaChave]!.add(r);
        }

        final listaDias = dias.entries.map((d) {
          return HistoricoDia(
            data: DateTime.parse(d.key),
            registros: d.value,
          );
        }).toList();

        // Ordenar dias (mais recente primeiro)
        listaDias.sort((a, b) => b.data.compareTo(a.data));

        return HistoricoMes(
          ano: ano,
          mes: mes,
          dias: listaDias,
        );
      }).toList();

      // Ordenar meses (mais recente primeiro)
      _historico.sort((a, b) {
        final dataA = DateTime(a.ano, a.mes);
        final dataB = DateTime(b.ano, b.mes);
        return dataB.compareTo(dataA);
      });

      _carregando = false;
      notifyListeners();
      
      debugPrint('✅ Histórico carregado: ${_historico.length} meses');
    } catch (e) {
      _carregando = false;
      _erro = e.toString();
      notifyListeners();
      debugPrint('❌ Erro ao carregar histórico: $e');
    }
  }
}