import 'package:flutter/material.dart';
import '../models/alerta_ponto_model.dart';
import '../services/alerta_service.dart';

class AlertaProvider extends ChangeNotifier {
  final AlertaService _alertaService = AlertaService();
  
  List<AlertaPonto> _alertas = [];
  bool _carregando = false;
  String? _erro;

  List<AlertaPonto> get alertas => _alertas;
  bool get carregando => _carregando;
  String? get erro => _erro;
  int get totalAlertas => _alertas.where((a) => !a.resolvido).length;

  // 🔥 Carregar alertas não resolvidos
  Future<void> carregarAlertas() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _alertas = await _alertaService.buscarAlertasNaoResolvidos();
      _carregando = false;
      notifyListeners();
      debugPrint('✅ Alertas carregados: ${_alertas.length}');
    } catch (e) {
      _carregando = false;
      _erro = e.toString();
      notifyListeners();
      debugPrint('❌ Erro ao carregar alertas: $e');
    }
  }

  // 🔥 Verificar alertas para todos os funcionários
  Future<void> verificarAlertas(
    List<Map<String, dynamic>> funcionarios,
  ) async {
    try {
      final novosAlertas = await _alertaService.verificarTodosAlertas(
        funcionarios,
      );
      
      // Recarregar lista
      await carregarAlertas();
      
      debugPrint('✅ Novos alertas encontrados: ${novosAlertas.length}');
    } catch (e) {
      debugPrint('❌ Erro ao verificar alertas: $e');
      rethrow;
    }
  }

  // 🔥 Resolver alerta
  Future<void> resolverAlerta(String alertaId, String justificativa) async {
    try {
      await _alertaService.marcarComoResolvido(alertaId, justificativa);
      await carregarAlertas();
    } catch (e) {
      debugPrint('❌ Erro ao resolver alerta: $e');
      rethrow;
    }
  }
}