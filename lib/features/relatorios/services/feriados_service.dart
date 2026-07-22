class Feriado {
  final int dia;
  final int mes;
  final String nome;

  Feriado({required this.dia, required this.mes, required this.nome});

  bool isFeriado(DateTime data) {
    return data.day == dia && data.month == mes;
  }
}

class FeriadosService {
  static final List<Feriado> _feriados = [
    // 🔥 FERIADOS NACIONAIS
    Feriado(dia: 1, mes: 1, nome: 'Confraternização Universal'),
    Feriado(dia: 21, mes: 4, nome: 'Tiradentes'),
    Feriado(dia: 1, mes: 5, nome: 'Dia do Trabalho'),
    Feriado(dia: 7, mes: 9, nome: 'Independência do Brasil'),
    Feriado(dia: 12, mes: 10, nome: 'Nossa Senhora Aparecida'),
    Feriado(dia: 2, mes: 11, nome: 'Finados'),
    Feriado(dia: 15, mes: 11, nome: 'Proclamação da República'),
    Feriado(dia: 20, mes: 11, nome: 'Consciência Negra'),
    Feriado(dia: 25, mes: 12, nome: 'Natal'),

    // 🔥 FERIADO ESTADUAL (SÃO PAULO)
    Feriado(dia: 9, mes: 7, nome: 'Revolução Constitucionalista de 1932'),

    // 🔥 FERIADOS MUNICIPAIS (VOTORANTIM)
    Feriado(dia: 8, mes: 12, nome: 'Emancipação de Votorantim'),

    // 🔥 CORPUS CHRISTI - DATA FIXA (04/06)
    Feriado(dia: 4, mes: 6, nome: 'Corpus Christi'),
  ];

  // 🔥 FERIADO MÓVEL (Sexta-Feira Santa) - Mantido como cálculo automático
  static DateTime? _sextaFeiraSanta(int ano) {
    // Cálculo da Páscoa (algoritmo de Gauss)
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = ((h + l - 7 * m + 114) % 31) + 1;

    final pascoa = DateTime(ano, mes, dia);
    // Sexta-Feira Santa = Páscoa - 2 dias
    return pascoa.subtract(const Duration(days: 2));
  }

  static bool isFeriado(DateTime data, {bool incluirMoveis = true}) {
    // 🔥 VERIFICAR FERIADOS FIXOS
    for (var feriado in _feriados) {
      if (feriado.isFeriado(data)) {
        return true;
      }
    }

    // 🔥 VERIFICAR FERIADOS MÓVEIS (apenas Sexta-Feira Santa)
    if (incluirMoveis) {
      final sextaSanta = _sextaFeiraSanta(data.year);
      if (sextaSanta != null &&
          sextaSanta.day == data.day &&
          sextaSanta.month == data.month) {
        return true;
      }
    }

    return false;
  }

  static String? getNomeFeriado(DateTime data) {
    // 🔥 VERIFICAR FERIADOS FIXOS
    for (var feriado in _feriados) {
      if (feriado.isFeriado(data)) {
        return feriado.nome;
      }
    }

    // 🔥 VERIFICAR FERIADOS MÓVEIS (apenas Sexta-Feira Santa)
    final sextaSanta = _sextaFeiraSanta(data.year);
    if (sextaSanta != null &&
        sextaSanta.day == data.day &&
        sextaSanta.month == data.month) {
      return 'Sexta-Feira Santa';
    }

    return null;
  }
}