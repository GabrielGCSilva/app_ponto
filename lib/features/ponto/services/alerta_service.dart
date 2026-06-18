import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alerta_ponto_model.dart';

class AlertaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Verificar alertas de um funcionário
  Future<List<AlertaPonto>> verificarAlertas(
    String funcionarioId,
    String funcionarioNome,
    DateTime data,
  ) async {
    final alertas = <AlertaPonto>[];
    
    try {
      final inicioDia = DateTime(data.year, data.month, data.day);
      final fimDia = inicioDia.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('registros_ponto')
          .where('funcionarioId', isEqualTo: funcionarioId)
          .where('dataHora', isGreaterThanOrEqualTo: inicioDia.toIso8601String())
          .where('dataHora', isLessThan: fimDia.toIso8601String())
          .get();

      final tiposRegistrados = snapshot.docs
          .map((doc) => doc['tipo'] as String)
          .toList();

      final tiposEsperados = ['entrada', 'saidaAlmoco', 'retornoAlmoco', 'saida'];
      final mapeamento = {
        'entrada': TipoAlerta.entradaAusente,
        'saidaAlmoco': TipoAlerta.almocoAusente,
        'retornoAlmoco': TipoAlerta.retornoAusente,
        'saida': TipoAlerta.saidaAusente,
      };

      for (var tipo in tiposEsperados) {
        if (!tiposRegistrados.contains(tipo)) {
          final alertaId = '${funcionarioId}_${data.toIso8601String()}_$tipo';
          
          final alertaExistente = await _firestore
              .collection('alertas')
              .doc(alertaId)
              .get();

          if (!alertaExistente.exists) {
            final alerta = AlertaPonto(
              id: alertaId,
              funcionarioId: funcionarioId,
              funcionarioNome: funcionarioNome,
              data: data,
              tipo: mapeamento[tipo]!,
            );
            
            await _firestore
                .collection('alertas')
                .doc(alertaId)
                .set(alerta.toFirestore());
            
            alertas.add(alerta);
          } else {
            alertas.add(
              AlertaPonto.fromFirestore(
                alertaExistente.data()!,
                alertaExistente.id,
              )
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao verificar alertas: $e');
    }

    return alertas;
  }

  // 🔥 Verificar alertas para todos os funcionários
  Future<List<AlertaPonto>> verificarTodosAlertas(
    List<Map<String, dynamic>> funcionarios,
  ) async {
    final todosAlertas = <AlertaPonto>[];
    final hoje = DateTime.now();

    for (var func in funcionarios) {
      final alertas = await verificarAlertas(
        func['id'],
        func['nome'],
        hoje,
      );
      todosAlertas.addAll(alertas);
    }

    return todosAlertas;
  }

  // 🔥 Buscar alertas não resolvidos
  Future<List<AlertaPonto>> buscarAlertasNaoResolvidos() async {
    try {
      final snapshot = await _firestore
          .collection('alertas')
          .where('resolvido', isEqualTo: false)
          .orderBy('data', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        return AlertaPonto.fromFirestore(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Erro ao buscar alertas: $e');
      return [];
    }
  }

  // 🔥 Marcar alerta como resolvido
  Future<void> marcarComoResolvido(String alertaId, String justificativa) async {
    try {
      await _firestore
          .collection('alertas')
          .doc(alertaId)
          .update({
            'resolvido': true,
            'justificativa': justificativa,
          });
      debugPrint('✅ Alerta resolvido: $alertaId');
    } catch (e) {
      debugPrint('❌ Erro ao resolver alerta: $e');
      rethrow;
    }
  }
}