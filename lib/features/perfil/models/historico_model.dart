import '../../ponto/models/registro_ponto_model.dart';

class HistoricoMes {
  final int ano;
  final int mes;
  final List<HistoricoDia> dias;
  final Duration totalHoras;

  HistoricoMes({required this.ano, required this.mes, required this.dias})
    : totalHoras = dias.fold(Duration.zero, (sum, dia) => sum + dia.totalHoras);

  String get label => _nomeMes(mes);

  String _nomeMes(int mes) {
    const meses = [
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
    return meses[mes - 1];
  }

  String get totalHorasFormatado {
    final horas = totalHoras.inHours;
    final minutos = totalHoras.inMinutes.remainder(60);
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }
}

class HistoricoDia {
  final DateTime data;
  final List<RegistroPonto> registros;
  final Duration totalHoras;

  HistoricoDia({required this.data, required this.registros})
    : totalHoras = Duration.zero;

  String get label {
    // 🔥 ORDEM CORRETA: começa com Segunda (weekday = 1)
    final diasSemana = [
      'Segunda', // weekday = 1 → índice 0
      'Terça', // weekday = 2 → índice 1
      'Quarta', // weekday = 3 → índice 2
      'Quinta', // weekday = 4 → índice 3
      'Sexta', // weekday = 5 → índice 4
      'Sábado', // weekday = 6 → índice 5
      'Domingo', // weekday = 7 → índice 6
    ];
    return '${diasSemana[data.weekday - 1]}, ${data.day} de ${_nomeMes(data.month)}';
  }

  String _nomeMes(int mes) {
    const meses = [
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
    return meses[mes - 1];
  }
}
