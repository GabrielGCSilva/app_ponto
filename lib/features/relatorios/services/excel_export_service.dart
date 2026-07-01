import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/relatorio_model.dart';

class ExcelExportService {
  // 🔥 GERAR EXCEL NO FORMATO DO MODELO
  static Uint8List? gerarExcelRelatorio(RelatorioMensal relatorio) {
    final excel = Excel.createExcel();
    final sheet = excel['Espelho de Ponto'];

    // 🔥 ===== TÍTULO =====
    _adicionarLinha(sheet, [
      'RELATÓRIO DE ACOMPANHAMENTO MENSAL DE FREQUÊNCIA,',
    ]);
    _adicionarLinha(sheet, ['HORAS EXTRAS E JORNADA ESPECIAL']);
    _adicionarLinha(sheet, []);

    // 🔥 ===== MÊS E FUNCIONÁRIO =====
    final mesNome = _nomeMes(relatorio.mes);
    _adicionarLinha(sheet, ['MÊS', '', '', '', 'FUNCIONÁRIO', '', '', '']);
    _adicionarLinha(sheet, [
      mesNome,
      '',
      '',
      '',
      relatorio.funcionarioNome,
      '',
      '',
      '',
    ]);
    _adicionarLinha(sheet, ['', '', '', '', 'CARGO', '', '', '']);
    _adicionarLinha(sheet, ['', '', '', '', relatorio.cargo, '', '', '']);
    _adicionarLinha(sheet, []);

    // 🔥 ===== TOTAIS (LADO DIREITO) =====
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'HORAS MENSAIS',
      relatorio.horasMensais,
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'HORAS DEVIDAS',
      relatorio.horasDevidas,
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'HORAS EXTRAS TRABALHADA',
      relatorio.horasExtrasTrabalhadas,
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'HORAS EXTRAS - 60%',
      relatorio.horasExtras60,
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'HORAS EXTRAS - 100%',
      relatorio.horasExtras100,
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'SUBTOTAL',
      relatorio.subtotal,
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      'TOTAL',
      relatorio.total,
    ]);
    _adicionarLinha(sheet, []);

    // 🔥 ===== CABEÇALHO DA TABELA =====
    final headers = [
      'DATA',
      'EVENTO',
      'EXPEDIENTE 1',
      '',
      '',
      'EXPEDIENTE 2',
      '',
      '',
      'TOTAL PREVISTO',
      'TOTAL EFETIVO',
      'HORAS DEVIDAS',
      'HORAS EXTRAS',
      'EXTRA 60%',
      'EXTRA 100%',
      'LOCALIZAÇÃO',
    ];
    final subHeaders = [
      '',
      '',
      'ENTRADA',
      'S.ALMOÇO',
      'TOTAL',
      'R.ALMOÇO',
      'SAÍDA',
      'TOTAL',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ];

    _adicionarLinha(sheet, headers);
    _adicionarLinha(sheet, subHeaders);

    // 🔥 ===== DADOS =====
    for (var dia in relatorio.dias) {
      final dataStr = DateFormat('dd MMM').format(dia.data).toLowerCase();
      final isDiaUtil = dia.diaSemana != 'Sáb' && dia.diaSemana != 'Dom';
      final temRegistro = dia.entrada.isNotEmpty || dia.saida.isNotEmpty;

      // 🔥 CORRIGIDO: Removido o operador '?.' desnecessário
      final localizacao = dia.localizacao;

      if (temRegistro) {
        final linha = [
          dataStr,
          dia.diaSemana,
          dia.entrada,
          dia.saidaAlmoco,
          _calcularTotal(dia.entrada, dia.saidaAlmoco),
          dia.retornoAlmoco,
          dia.saida,
          _calcularTotal(dia.retornoAlmoco, dia.saida),
          isDiaUtil ? '09:00' : '00:00',
          dia.total,
          '',
          '',
          '',
          '',
          localizacao,
        ];
        _adicionarLinha(sheet, linha);
      } else {
        final linha = [
          dataStr,
          dia.diaSemana,
          '',
          '',
          '',
          '',
          '',
          '',
          isDiaUtil ? '09:00' : '00:00',
          '',
          '',
          '',
          '',
          '',
          localizacao,
        ];
        _adicionarLinha(sheet, linha);
      }
    }

    // 🔥 ===== RODAPÉ =====
    _adicionarLinha(sheet, []);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '/    /',
      '',
      'ASSINATURA',
      '',
      '',
      '',
      '',
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '______________________________________',
      '',
      '',
      '',
      '',
    ]);
    _adicionarLinha(sheet, [
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      relatorio.funcionarioNome,
      '',
      '',
      '',
      '',
    ]);

    // 🔥 CORRIGIDO: encode() retorna List<int>, convertemos para Uint8List
    final List<int>? encoded = excel.encode();
    if (encoded == null) return null;
    return Uint8List.fromList(encoded);
  }

  // 🔥 HELPERS
  static void _adicionarLinha(Sheet sheet, List<dynamic> linha) {
    final List<CellValue?> convertedLine = linha.map((item) {
      if (item is String) {
        return TextCellValue(item);
      } else if (item is int) {
        return IntCellValue(item);
      } else if (item is double) {
        return DoubleCellValue(item);
      } else if (item == null) {
        return null;
      }
      return TextCellValue(item.toString());
    }).toList();
    sheet.appendRow(convertedLine);
  }

  static String _calcularTotal(String entrada, String saida) {
    if (entrada.isEmpty || saida.isEmpty) return '';
    try {
      final parts1 = entrada.split(':').map(int.parse).toList();
      final parts2 = saida.split(':').map(int.parse).toList();
      final totalMin =
          (parts2[0] * 60 + parts2[1]) - (parts1[0] * 60 + parts1[1]);
      if (totalMin < 0) return '';
      final h = totalMin ~/ 60;
      final m = totalMin % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  static String _nomeMes(int mes) {
    const meses = [
      'JANEIRO',
      'FEVEREIRO',
      'MARÇO',
      'ABRIL',
      'MAIO',
      'JUNHO',
      'JULHO',
      'AGOSTO',
      'SETEMBRO',
      'OUTUBRO',
      'NOVEMBRO',
      'DEZEMBRO',
    ];
    return meses[mes - 1];
  }
}
