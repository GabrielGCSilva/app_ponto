import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/relatorio_model.dart';
import '../../ponto/models/registro_ponto_model.dart';

class RelatorioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Dias da semana
  final Map<int, String> diasSemana = {
    1: 'Seg',
    2: 'Ter',
    3: 'Qua',
    4: 'Qui',
    5: 'Sex',
    6: 'Sáb',
    7: 'Dom',
  };

  // 🔥 Horário previsto por dia
  String getHorarioPrevisto(int diaSemana) {
    if (diaSemana == 5) return '08:00'; // Sexta
    if (diaSemana == 6 || diaSemana == 7) return '00:00'; // Sáb/Dom
    return '09:00'; // Seg-Qui
  }

  // 🔥 Gerar relatório mensal
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

  // 🔥 BUSCAR REGISTROS DO FUNCIONÁRIO
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

  // 🔥 BUSCAR DADOS DO FUNCIONÁRIO
  Future<Map<String, dynamic>> _buscarFuncionario(String funcionarioId) async {
    final doc = await _firestore
        .collection('funcionarios')
        .doc(funcionarioId)
        .get();
    return doc.data() ?? {};
  }

  // 🔥 GERAR DIAS DO RELATÓRIO
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

      // 🔥 BUSCAR OS 4 TIPOS DE REGISTRO
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

      // 🔥 Verificar se é FALTA
      String? evento;
      if (entrada.id.isEmpty && diaSemana != 6 && diaSemana != 7) {
        evento = 'FALTA';
      }

      // 🔥 Verificar se é FOLGA
      if (diaSemana == 6 || diaSemana == 7) {
        evento = 'FOLGA';
      }

      // 🔥 CALCULAR TOTAL DO DIA
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

      // 🔥 TOTAL PREVISTO DO DIA
      final previsto = getHorarioPrevisto(diaSemana);

      // 🔥 LOCALIZAÇÃO
      String localizacao = '';
      if (entrada.id.isNotEmpty) {
        localizacao = entrada.endereco;
      } else if (saida.id.isNotEmpty) {
        localizacao = saida.endereco;
      } else if (saidaAlmoco.id.isNotEmpty) {
        localizacao = saidaAlmoco.endereco;
      } else if (retornoAlmoco.id.isNotEmpty) {
        localizacao = retornoAlmoco.endereco;
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
          localizacao: localizacao,
        ),
      );
    }

    return dias;
  }

  String _formatarHora(DateTime data) {
    return '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  // 🔥 CALCULAR TOTAIS
  // 🔥 MÉTODO CORRIGIDO
  RelatorioMensal _calcularTotais(
    List<RelatorioDiario> dias,
    Map<String, dynamic> funcionario,
    int mes,
    int ano,
  ) {
    // 🔥 VERIFICAR SE HÁ REGISTROS
    final temRegistros = dias.any(
      (dia) =>
          dia.entrada.isNotEmpty ||
          dia.saida.isNotEmpty ||
          dia.saidaAlmoco.isNotEmpty ||
          dia.retornoAlmoco.isNotEmpty,
    );

    // 🔥 TOTAL PREVISTO FIXO = 194:00
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

      // 🔥 SÓ CALCULAR PARA DIAS QUE JÁ PASSARAM
      final hoje = DateTime.now();
      final dataDia = dia.data;
      if (dataDia.isBefore(hoje) || dataDia.isAtSameMomentAs(hoje)) {
        if (dia.diaSemana != 'Sáb' && dia.diaSemana != 'Dom') {
          final diffDia = efetivo - previsto;
          if (diffDia > Duration.zero) {
            totalHorasExtras += diffDia;
          }
        }

        if (dia.diaSemana == 'Sáb') {
          final extra60 = (efetivo.inMinutes * 0.6).round();
          totalExtras60 += Duration(minutes: extra60);
          totalHorasExtrasFimSemana += efetivo;
        } else if (dia.diaSemana == 'Dom') {
          totalExtras100 += efetivo;
          totalHorasExtrasFimSemana += efetivo;
        }

        totalEfetivo += efetivo;
      }
    }

    // 🔥 HORAS DEVIDAS
    final totalHorasDevidas = totalPrevistoFixo - totalEfetivo;
    final horasDevidas = totalHorasDevidas.isNegative
        ? '00:00'
        : CalculadoraHoras.durationToString(totalHorasDevidas);

    // 🔥 HORAS EXTRAS
    final totalExtrasTotal = totalHorasExtras + totalHorasExtrasFimSemana;
    final horasExtras = CalculadoraHoras.durationToString(totalExtrasTotal);

    // 🔥 HORAS MENSAIS
    final horasMensais = Duration(hours: 220);
    final horasMensaisStr = CalculadoraHoras.durationToString(horasMensais);

    // 🔥 🔥 CORREÇÃO: SUBTOTAL SÓ SE HOUVER REGISTROS
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

    debugPrint('📊 ===== RELATÓRIO =====');
    debugPrint('  Tem registros? $temRegistros');
    debugPrint('  Total Previsto FIXO: 194:00');
    debugPrint(
      '  Total Efetivo: ${CalculadoraHoras.durationToString(totalEfetivo)}',
    );
    debugPrint('  Horas Devidas: $horasDevidas');
    debugPrint(
      '  Horas Extras (dias úteis): ${CalculadoraHoras.durationToString(totalHorasExtras)}',
    );
    debugPrint(
      '  Horas Extras (fim de semana): ${CalculadoraHoras.durationToString(totalHorasExtrasFimSemana)}',
    );
    debugPrint('  Horas Extras TOTAL: $horasExtras');
    debugPrint(
      '  Extra 60%: ${CalculadoraHoras.durationToString(totalExtras60)}',
    );
    debugPrint(
      '  Extra 100%: ${CalculadoraHoras.durationToString(totalExtras100)}',
    );
    debugPrint('  Subtotal: ${CalculadoraHoras.durationToString(subtotal)}');

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
