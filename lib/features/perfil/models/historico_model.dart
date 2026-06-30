import '../../ponto/models/registro_ponto_model.dart';

class HistoricoMes {
  final int ano;
  final int mes;
  final List<HistoricoDia> dias;
  final Duration totalHoras;

  HistoricoMes({
    required this.ano,
    required this.mes,
    required this.dias,
  }) : totalHoras = dias.fold(
          Duration.zero,
          (sum, dia) => sum + dia.totalHoras,
        );

  String get label => _nomeMes(mes);

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril',
      'Maio', 'Junho', 'Julho', 'Agosto',
      'Setembro', 'Outubro', 'Novembro', 'Dezembro'
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

  HistoricoDia({
    required this.data,
    required this.registros,
  }) : totalHoras = registros.fold(
          Duration.zero,
          (sum, r) => sum + _calcularDuracao(r),
        );

  static Duration _calcularDuracao(RegistroPonto r) {
    // Calcula a duração baseada no tipo (entrada/saída)
    // Simplificado: só mostra o registro, não a duração
    return Duration.zero;
  }

  String get label {
    final diasSemana = [
      'Domingo', 'Segunda', 'Terça', 'Quarta',
      'Quinta', 'Sexta', 'Sábado'
    ];
    return '${diasSemana[data.weekday]}, ${data.day} de ${_nomeMes(data.month)}';
  }

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril',
      'Maio', 'Junho', 'Julho', 'Agosto',
      'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[mes - 1];
  }
}