class RelatorioDiario {
  final DateTime data;
  final String diaSemana;
  final String? evento; // "FALTA", "FOLGA", null
  final String entrada;
  final String saidaAlmoco;
  final String retornoAlmoco;
  final String saida;
  final String total;
  final String totalPrevisto; // 🔥 NOVO
  final String localizacao;

  RelatorioDiario({
    required this.data,
    required this.diaSemana,
    this.evento,
    required this.entrada,
    required this.saidaAlmoco,
    required this.retornoAlmoco,
    required this.saida,
    required this.total,
    required this.totalPrevisto,
    required this.localizacao,
  });
}

class RelatorioMensal {
  final String funcionarioId;
  final String funcionarioNome;
  final String cargo;
  final int mes;
  final int ano;
  final List<RelatorioDiario> dias;
  
  // Totais
  final String horasMensais;
  final String totalPrevisto;
  final String totalEfetivo;
  final String horasDevidas;
  final String horasExtrasTrabalhadas;
  final String horasExtras60;
  final String horasExtras100;
  final String subtotal;
  final String total;

  RelatorioMensal({
    required this.funcionarioId,
    required this.funcionarioNome,
    required this.cargo,
    required this.mes,
    required this.ano,
    required this.dias,
    required this.horasMensais,
    required this.totalPrevisto,
    required this.totalEfetivo,
    required this.horasDevidas,
    required this.horasExtrasTrabalhadas,
    required this.horasExtras60,
    required this.horasExtras100,
    required this.subtotal,
    required this.total,
  });
}

// 🔥 Utilitário para calcular horas
class CalculadoraHoras {
  static Duration stringToDuration(String str) {
    if (str.isEmpty || str == '00:00') return Duration.zero;
    final parts = str.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
    );
  }

  static String durationToString(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  static String somarHoras(String a, String b) {
    final durA = stringToDuration(a);
    final durB = stringToDuration(b);
    return durationToString(durA + durB);
  }

  static String subtrairHoras(String a, String b) {
    final durA = stringToDuration(a);
    final durB = stringToDuration(b);
    if (durA < durB) return '00:00';
    return durationToString(durA - durB);
  }
}