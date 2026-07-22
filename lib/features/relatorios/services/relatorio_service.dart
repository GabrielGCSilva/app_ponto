// lib/features/relatorios/services/relatorio_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/relatorio_model.dart';
import 'package:app_ponto/features/relatorios/services/feriados_service.dart';
import '../../ponto/models/registro_ponto_model.dart';

class RelatorioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<int, String> diasSemana = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  String getHorarioPrevisto(int diaSemana) {
    if (diaSemana == 5) return '08:00';
    if (diaSemana == 6 || diaSemana == 7) return '00:00';
    return '09:00';
  }

  Future<RelatorioMensal> gerarRelatorioMensal({
    required String funcionarioId,
    required int mes,
    required int ano,
  }) async {
    final registros = await _buscarRegistros(funcionarioId, mes, ano);
    final funcionario = await _buscarFuncionario(funcionarioId);
    final dias = await _gerarDiasRelatorio(registros, mes, ano);
    return _calcularTotais(dias, funcionario, mes, ano);
  }

  Future<List<RegistroPonto>> _buscarRegistros(
    String funcionarioId,
    int mes,
    int ano,
  ) async {
    final inicio = DateTime(ano, mes, 1);
    final fim = DateTime(ano, mes + 1, 1);

    final snapshot = await _firestore
        .collection('registros_ponto')
        .where('funcionarioId', isEqualTo: funcionarioId)
        .where('dataHora', isGreaterThanOrEqualTo: inicio.toIso8601String())
        .where('dataHora', isLessThan: fim.toIso8601String())
        .get();

    return snapshot.docs.map((doc) {
      return RegistroPonto.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  Future<Map<String, dynamic>> _buscarFuncionario(String funcionarioId) async {
    final doc = await _firestore
        .collection('funcionarios')
        .doc(funcionarioId)
        .get();
    return doc.data() ?? {};
  }

  Future<List<RelatorioDiario>> _gerarDiasRelatorio(
    List<RegistroPonto> registros,
    int mes,
    int ano,
  ) async {
    final dias = <RelatorioDiario>[];
    final diasNoMes = DateTime(ano, mes + 1, 0).day;

    for (int dia = 1; dia <= diasNoMes; dia++) {
      final data = DateTime(ano, mes, dia);
      final diaSemana = data.weekday;

      final registrosDia = registros
          .where(
            (r) =>
                r.dataHora.year == ano &&
                r.dataHora.month == mes &&
                r.dataHora.day == dia,
          )
          .toList();

      final entrada = registrosDia.firstWhere(
        (r) => r.tipo == TipoPonto.entrada,
        orElse: () => RegistroPonto(
          id: '',
          funcionarioId: '',
          funcionarioNome: '',
          dataHora: data,
          tipo: TipoPonto.entrada,
          latitude: 0,
          longitude: 0,
          endereco: '',
          metodoAutenticacao: '',
        ),
      );

      final saidaAlmoco = registrosDia.firstWhere(
        (r) => r.tipo == TipoPonto.saidaAlmoco,
        orElse: () => RegistroPonto(
          id: '',
          funcionarioId: '',
          funcionarioNome: '',
          dataHora: data,
          tipo: TipoPonto.saidaAlmoco,
          latitude: 0,
          longitude: 0,
          endereco: '',
          metodoAutenticacao: '',
        ),
      );

      final retornoAlmoco = registrosDia.firstWhere(
        (r) => r.tipo == TipoPonto.retornoAlmoco,
        orElse: () => RegistroPonto(
          id: '',
          funcionarioId: '',
          funcionarioNome: '',
          dataHora: data,
          tipo: TipoPonto.retornoAlmoco,
          latitude: 0,
          longitude: 0,
          endereco: '',
          metodoAutenticacao: '',
        ),
      );

      final saida = registrosDia.firstWhere(
        (r) => r.tipo == TipoPonto.saida,
        orElse: () => RegistroPonto(
          id: '',
          funcionarioId: '',
          funcionarioNome: '',
          dataHora: data,
          tipo: TipoPonto.saida,
          latitude: 0,
          longitude: 0,
          endereco: '',
          metodoAutenticacao: '',
        ),
      );

      final isFeriado = FeriadosService.isFeriado(data);
      final nomeFeriado = isFeriado ? FeriadosService.getNomeFeriado(data) : null;

      String? evento;
      if (isFeriado) {
        evento = 'FERIADO';
      } else if (entrada.id.isEmpty && diaSemana != 6 && diaSemana != 7) {
        evento = 'FALTA';
      } else if (diaSemana == 6 || diaSemana == 7) {
        evento = 'FOLGA';
      }

      Duration totalDuration = Duration.zero;
      String total = '00:00';

      if (entrada.id.isNotEmpty && saida.id.isNotEmpty) {
        final entradaHora = entrada.dataHora;
        final saidaHora = saida.dataHora;

        totalDuration = saidaHora.difference(entradaHora);

        if (saidaAlmoco.id.isNotEmpty && retornoAlmoco.id.isNotEmpty) {
          final intervalo = retornoAlmoco.dataHora.difference(
            saidaAlmoco.dataHora,
          );
          totalDuration = totalDuration - intervalo;
        }

        final horas = totalDuration.inHours;
        final minutos = totalDuration.inMinutes.remainder(60);
        total =
            '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
      }

      String previsto;
      if (isFeriado) {
        previsto = '00:00';
      } else {
        previsto = getHorarioPrevisto(diaSemana);
      }

      String localizacaoEntrada = '';
      if (entrada.id.isNotEmpty) {
        localizacaoEntrada = entrada.endereco;
      }

      String localizacaoSaida = '';
      if (saida.id.isNotEmpty) {
        localizacaoSaida = saida.endereco;
      } else if (retornoAlmoco.id.isNotEmpty) {
        localizacaoSaida = retornoAlmoco.endereco;
      } else if (saidaAlmoco.id.isNotEmpty) {
        localizacaoSaida = saidaAlmoco.endereco;
      } else if (entrada.id.isNotEmpty) {
        localizacaoSaida = entrada.endereco;
      }

      dias.add(
        RelatorioDiario(
          data: data,
          diaSemana: diasSemana[diaSemana]!,
          evento: evento,
          entrada: entrada.id.isNotEmpty ? _formatarHora(entrada.dataHora) : '',
          saidaAlmoco: saidaAlmoco.id.isNotEmpty
              ? _formatarHora(saidaAlmoco.dataHora)
              : '',
          retornoAlmoco: retornoAlmoco.id.isNotEmpty
              ? _formatarHora(retornoAlmoco.dataHora)
              : '',
          saida: saida.id.isNotEmpty ? _formatarHora(saida.dataHora) : '',
          total: total,
          totalPrevisto: previsto,
          localizacaoEntrada: localizacaoEntrada,
          localizacaoSaida: localizacaoSaida,
          isFeriado: isFeriado,
          nomeFeriado: nomeFeriado,
        ),
      );
    }

    return dias;
  }

  String _formatarHora(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  RelatorioMensal _calcularTotais(
    List<RelatorioDiario> dias,
    Map<String, dynamic> funcionario,
    int mes,
    int ano,
  ) {
    final temRegistros = dias.any(
      (dia) =>
          dia.entrada.isNotEmpty ||
          dia.saida.isNotEmpty ||
          dia.saidaAlmoco.isNotEmpty ||
          dia.retornoAlmoco.isNotEmpty,
    );

    final totalPrevistoFixo = CalculadoraHoras.stringToDuration('194:00');

    Duration totalEfetivo = Duration.zero;
    Duration totalExtras60 = Duration.zero;
    Duration totalExtras100 = Duration.zero;
    Duration totalHorasExtras = Duration.zero;
    Duration totalHorasExtrasFimSemana = Duration.zero;

    for (var dia in dias) {
      final previsto = CalculadoraHoras.stringToDuration(
        getHorarioPrevisto(_diaSemanaNumero(dia.diaSemana)),
      );

      final entrada = CalculadoraHoras.stringToDuration(dia.entrada);
      final saidaAlmoco = CalculadoraHoras.stringToDuration(dia.saidaAlmoco);
      final retornoAlmoco = CalculadoraHoras.stringToDuration(
        dia.retornoAlmoco,
      );
      final saida = CalculadoraHoras.stringToDuration(dia.saida);

      Duration efetivo = Duration.zero;

      if (entrada > Duration.zero && saida > Duration.zero) {
        efetivo = saida - entrada;

        if (saidaAlmoco > Duration.zero && retornoAlmoco > Duration.zero) {
          final intervalo = retornoAlmoco - saidaAlmoco;
          efetivo = efetivo - intervalo;
        }
      }

      final hoje = DateTime.now();
      final dataDia = dia.data;
      if (dataDia.isBefore(hoje) || dataDia.isAtSameMomentAs(hoje)) {
        Duration diffDia = Duration.zero;
        if (dia.diaSemana != 'Sáb' && dia.diaSemana != 'Dom' && !dia.isFeriado) {
          diffDia = efetivo - previsto;
          if (diffDia > Duration.zero) {
            totalHorasExtras += diffDia;
          }
        }

        // 🔥 EXTRA 60% = HORAS EXTRAS * 0.6 (Segunda a Sábado)
        if (diffDia > Duration.zero) {
          final extra60 = (diffDia.inMinutes * 0.6).round();
          totalExtras60 += Duration(minutes: extra60);
        }

        // 🔥 EXTRA 100% = HORAS EXTRAS (Domingo ou Feriado)
        if (dia.isFeriado || dia.diaSemana == 'Dom') {
          if (efetivo > Duration.zero) {
            totalExtras100 += efetivo;
            totalHorasExtrasFimSemana += efetivo;
          }
        }

        totalEfetivo += efetivo;
      }
    }

    final totalHorasDevidas = totalPrevistoFixo - totalEfetivo;
    final horasDevidas = totalHorasDevidas.isNegative
        ? '00:00'
        : CalculadoraHoras.durationToString(totalHorasDevidas);

    final totalExtrasTotal = totalHorasExtras + totalHorasExtrasFimSemana;
    final horasExtras = CalculadoraHoras.durationToString(totalExtrasTotal);

    final horasMensais = Duration(hours: 220);
    final horasMensaisStr = CalculadoraHoras.durationToString(horasMensais);

    Duration subtotal;
    if (temRegistros) {
      final horasMensaisDur = CalculadoraHoras.stringToDuration(
        horasMensaisStr,
      );
      final horasDevidasDur = CalculadoraHoras.stringToDuration(horasDevidas);
      final horasExtrasDur = CalculadoraHoras.stringToDuration(horasExtras);

      subtotal =
          horasMensaisDur -
          horasDevidasDur +
          horasExtrasDur +
          totalExtras60 +
          totalExtras100;
    } else {
      subtotal = Duration.zero;
    }

    return RelatorioMensal(
      funcionarioId: funcionario['id'] ?? '',
      funcionarioNome: funcionario['nome'] ?? '',
      cargo: funcionario['cargo'] ?? '',
      mes: mes,
      ano: ano,
      dias: dias,
      horasMensais: horasMensaisStr,
      totalPrevisto: '194:00',
      totalEfetivo: CalculadoraHoras.durationToString(totalEfetivo),
      horasDevidas: horasDevidas,
      horasExtrasTrabalhadas: horasExtras,
      horasExtras60: CalculadoraHoras.durationToString(totalExtras60),
      horasExtras100: CalculadoraHoras.durationToString(totalExtras100),
      subtotal: CalculadoraHoras.durationToString(subtotal),
      total: CalculadoraHoras.durationToString(subtotal),
    );
  }

  int _diaSemanaNumero(String dia) {
    switch (dia) {
      case 'Seg':
        return 1;
      case 'Ter':
        return 2;
      case 'Qua':
        return 3;
      case 'Qui':
        return 4;
      case 'Sex':
        return 5;
      case 'Sáb':
        return 6;
      case 'Dom':
        return 7;
      default:
        return 1;
    }
  }
}