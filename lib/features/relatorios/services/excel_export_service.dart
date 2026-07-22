import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/relatorio_model.dart';

class ExcelExportService {
  // 🔥 GERAR EXCEL NO FORMATO DO MODELO COM ESTILOS
  static Uint8List? gerarExcelRelatorio(RelatorioMensal relatorio) {
    final excel = Excel.createExcel();
    final sheet = excel['Espelho de Ponto'];

    // 🔥 ===== CONFIGURAÇÕES GERAIS =====
    _configurarPlanilha(sheet);

    // 🔥 ===== TÍTULO =====
    _adicionarTitulo(sheet);

    // 🔥 ===== MÊS E FUNCIONÁRIO =====
    _adicionarCabecalhoInfo(sheet, relatorio);

    // 🔥 ===== TOTAIS =====
    _adicionarTotais(sheet, relatorio);

    // 🔥 ===== TABELA =====
    _adicionarTabela(sheet, relatorio);

    // 🔥 ===== RODAPÉ =====
    _adicionarRodape(sheet, relatorio);

    final List<int>? encoded = excel.encode();
    if (encoded == null) return null;
    return Uint8List.fromList(encoded);
  }

  // ============================================================
  // 🔥 CONFIGURAÇÕES DA PLANILHA
  // ============================================================
  static void _configurarPlanilha(Sheet sheet) {
    // 🔥 LARGURA DAS COLUNAS (converter para double)
    sheet.setColumnWidth(0, 12.0);  // DATA
    sheet.setColumnWidth(1, 10.0);  // D.SEMANA
    sheet.setColumnWidth(2, 10.0);  // EVENTO
    sheet.setColumnWidth(3, 9.0);   // ENTRADA
    sheet.setColumnWidth(4, 9.0);   // S.ALMOÇO
    sheet.setColumnWidth(5, 9.0);   // TOTAL 1
    sheet.setColumnWidth(6, 9.0);   // R.ALMOÇO
    sheet.setColumnWidth(7, 9.0);   // SAÍDA
    sheet.setColumnWidth(8, 9.0);   // TOTAL 2
    sheet.setColumnWidth(9, 12.0);  // TOTAL PREVISTO
    sheet.setColumnWidth(10, 12.0); // TOTAL EFETIVO
    sheet.setColumnWidth(11, 12.0); // HORAS DEVIDAS
    sheet.setColumnWidth(12, 12.0); // HORAS EXTRAS
    sheet.setColumnWidth(13, 12.0); // EXTRA 60%
    sheet.setColumnWidth(14, 12.0); // EXTRA 100%
    sheet.setColumnWidth(15, 35.0); // LOCALIZAÇÃO.E
    sheet.setColumnWidth(16, 35.0); // LOCALIZAÇÃO.S

    // 🔥 ALTURA DAS LINHAS
    sheet.setRowHeight(0, 30.0);
    sheet.setRowHeight(1, 30.0);
    sheet.setRowHeight(16, 24.0);
    sheet.setRowHeight(17, 24.0);

    for (int i = 18; i < 50; i++) {
      sheet.setRowHeight(i, 20.0);
    }
  }

  // ============================================================
  // 🔥 ESTILOS (sem bordas para evitar erros)
  // ============================================================
  static CellStyle _estiloTitulo() {
    return CellStyle(
      bold: true,
      fontSize: 16,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _estiloCabecalho() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.grey300,
    );
  }

  static CellStyle _estiloDados() {
    return CellStyle(
      fontSize: 10,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _estiloDadosNegrito() {
    return CellStyle(
      fontSize: 10,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      bold: true,
    );
  }

  static CellStyle _estiloTotal() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _estiloAssinatura() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _estiloFalta() {
  return CellStyle(
    fontSize: 10,
    fontFamily: getFontFamily(FontFamily.Calibri),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    backgroundColorHex: ExcelColor.red50,
  );
}

static CellStyle _estiloFolga() {
  return CellStyle(
    fontSize: 10,
    fontFamily: getFontFamily(FontFamily.Calibri),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    backgroundColorHex: ExcelColor.green50,
  );
}

  // ============================================================
  // 🔥 TÍTULO
  // ============================================================
  static void _adicionarTitulo(Sheet sheet) {
    // Mesclar título
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 0),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
      CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: 1),
    );

    final cell1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    cell1.value = TextCellValue('RELATÓRIO DE ACOMPANHAMENTO MENSAL DE FREQUÊNCIA,');
    cell1.cellStyle = _estiloTitulo();

    final cell2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    cell2.value = TextCellValue('HORAS EXTRAS E JORNADA ESPECIAL');
    cell2.cellStyle = _estiloTitulo();
  }

  // ============================================================
  // 🔥 CABEÇALHO DE INFORMAÇÕES
  // ============================================================
  static void _adicionarCabecalhoInfo(Sheet sheet, RelatorioMensal relatorio) {
    final mesNome = _nomeMes(relatorio.mes);
    final row = 3;

    // Linha "MÊS" e "FUNCIONÁRIO"
    final cellMesLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cellMesLabel.value = TextCellValue('MÊS');
    cellMesLabel.cellStyle = _estiloDadosNegrito();

    final cellMesValor = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row + 1));
    cellMesValor.value = TextCellValue(mesNome);
    cellMesValor.cellStyle = _estiloDados();

    final cellFuncLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
    cellFuncLabel.value = TextCellValue('FUNCIONÁRIO');
    cellFuncLabel.cellStyle = _estiloDadosNegrito();

    final cellFuncValor = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row + 1));
    cellFuncValor.value = TextCellValue(relatorio.funcionarioNome);
    cellFuncValor.cellStyle = _estiloDados();

    // Linha "CARGO"
    final rowCargo = row + 3;
    final cellCargoLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowCargo));
    cellCargoLabel.value = TextCellValue('CARGO');
    cellCargoLabel.cellStyle = _estiloDadosNegrito();

    final cellCargoValor = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowCargo + 1));
    cellCargoValor.value = TextCellValue(relatorio.cargo);
    cellCargoValor.cellStyle = _estiloDados();

    // Mesclagens
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row + 1),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row + 1),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row + 1),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowCargo),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowCargo),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowCargo + 1),
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowCargo + 1),
    );
  }

  // ============================================================
  // 🔥 TOTAIS
  // ============================================================
  static void _adicionarTotais(Sheet sheet, RelatorioMensal relatorio) {
    final row = 9;
    final totais = [
      ['HORAS MENSAIS', relatorio.horasMensais],
      ['HORAS DEVIDAS', relatorio.horasDevidas],
      ['HORAS EXTRAS TRABALHADA', relatorio.horasExtrasTrabalhadas],
      ['HORAS EXTRAS - 60%', relatorio.horasExtras60],
      ['HORAS EXTRAS - 100%', relatorio.horasExtras100],
      ['SUBTOTAL', relatorio.subtotal],
      ['TOTAL', relatorio.total],
    ];

    for (int i = 0; i < totais.length; i++) {
      final labelCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row + i));
      labelCell.value = TextCellValue(totais[i][0]);
      labelCell.cellStyle = _estiloDadosNegrito();

      final valorCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row + i));
      valorCell.value = TextCellValue(totais[i][1]);
      valorCell.cellStyle = i == totais.length - 1 ? _estiloTotal() : _estiloDadosNegrito();
    }
  }

  // ============================================================
  // 🔥 TABELA
  // ============================================================
  static void _adicionarTabela(Sheet sheet, RelatorioMensal relatorio) {
    final headers = [
      'DATA',
      'D.SEMANA',
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
      'LOCALIZAÇÃO.E',
      'LOCALIZAÇÃO.S',
    ];
    final subHeaders = [
      '',
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
      '',
    ];

    final headerRow = 16;
    final subHeaderRow = 17;

    // 🔥 ADICIONAR LINHAS DE CABEÇALHO
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = _estiloCabecalho();
    }

    for (int col = 0; col < subHeaders.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: subHeaderRow));
      if (subHeaders[col].isNotEmpty) {
        cell.value = TextCellValue(subHeaders[col]);
      }
      cell.cellStyle = _estiloCabecalho();
    }

    // 🔥 MESCLAR CABEÇALHOS
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow),
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: headerRow),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: headerRow),
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: headerRow),
    );

    // 🔥 ADICIONAR DADOS
    int rowIndex = subHeaderRow + 1;

    for (var dia in relatorio.dias) {
      final dataStr = DateFormat('dd MMM').format(dia.data).toLowerCase();
      final temRegistro = dia.entrada.isNotEmpty || dia.saida.isNotEmpty;

      // 🔥 CÁLCULOS
      Duration totalExp1 = Duration.zero;
      if (dia.entrada.isNotEmpty && dia.saidaAlmoco.isNotEmpty) {
        totalExp1 = _stringToDuration(dia.saidaAlmoco) - _stringToDuration(dia.entrada);
      }
      final totalExp1Str = _durationToString(totalExp1);

      Duration totalExp2 = Duration.zero;
      if (dia.retornoAlmoco.isNotEmpty && dia.saida.isNotEmpty) {
        totalExp2 = _stringToDuration(dia.saida) - _stringToDuration(dia.retornoAlmoco);
      }
      final totalExp2Str = _durationToString(totalExp2);

      final totalEfetivoDia = _somarTempos(totalExp1Str, totalExp2Str);

      final totalPrevisto = _stringToDuration(dia.totalPrevisto);
      final totalEfetivo = _stringToDuration(totalEfetivoDia);
      final diff = totalEfetivo - totalPrevisto;

      String horasDevidasDia = '00:00';
      String horasExtrasDia = '00:00';

      if (diff.isNegative) {
        horasDevidasDia = _durationToString(diff.abs());
      } else if (diff > Duration.zero) {
        horasExtrasDia = _durationToString(diff);
      }

      String extra60Dia = '00:00';
      String extra100Dia = '00:00';

      // 🔥 🔥 🔥 CORREÇÃO: EXTRA 60% = HORAS EXTRAS * 0.6 (Segunda a Sábado)
      // 🔥 EXTRA 100% = HORAS EXTRAS (Domingo)
      if (dia.diaSemana == 'Dom') {
        // 🔥 EXTRA 100% = HORAS EXTRAS (Domingo)
        if (horasExtrasDia != '00:00') {
          extra100Dia = horasExtrasDia;
        }
      } else {
        // 🔥 EXTRA 60% = HORAS EXTRAS * 0.6 (Segunda a Sábado)
        if (horasExtrasDia != '00:00') {
          final horasExtrasDur = _stringToDuration(horasExtrasDia);
          final extra60 = (horasExtrasDur.inMinutes * 0.6).round();
          extra60Dia = _durationToString(Duration(minutes: extra60));
        }
      }

      String totalPrevistoFinal = dia.totalPrevisto;
      if (dia.diaSemana == 'Sex') {
        totalPrevistoFinal = '08:00';
      }

      List<String> linhaDados;

      // D.SEMANA abreviado
      final diaSemanaAbreviado = dia.diaSemana.substring(0, 3);

      if (temRegistro) {
        linhaDados = [
          dataStr,
          diaSemanaAbreviado,
          dia.evento ?? '',
          dia.entrada,
          dia.saidaAlmoco,
          totalExp1Str,
          dia.retornoAlmoco,
          dia.saida,
          totalExp2Str,
          totalPrevistoFinal,
          totalEfetivoDia,
          horasDevidasDia,
          horasExtrasDia,
          extra60Dia,
          extra100Dia,
          dia.localizacaoEntrada,
          dia.localizacaoSaida,
        ];
      } else {
        linhaDados = [
          dataStr,
          diaSemanaAbreviado,
          dia.evento ?? '',
          '',
          '',
          '',
          '',
          '',
          '',
          totalPrevistoFinal,
          '',
          '',
          '',
          '',
          '',
          dia.localizacaoEntrada,
          dia.localizacaoSaida,
        ];
      }

      for (int col = 0; col < linhaDados.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));
        if (linhaDados[col].isNotEmpty) {
          cell.value = TextCellValue(linhaDados[col]);
        }
        // 🔥 APLICAR CORES POR EVENTO
        if (dia.evento == 'FALTA') {
          cell.cellStyle = _estiloFalta();
        } else if (dia.evento == 'FOLGA') {
          cell.cellStyle = _estiloFolga();
        } else {
          // 🔥 DESTAQUES
          if (col == 5 || col == 8) {
            // Colunas TOTAL
            cell.cellStyle = _estiloDadosNegrito();
          } else if (col == 10 && linhaDados[10].isNotEmpty && linhaDados[10] != '00:00') {
            // TOTAL EFETIVO
            cell.cellStyle = _estiloDadosNegrito();
          } else if (col == 11 && linhaDados[11].isNotEmpty && linhaDados[11] != '00:00') {
            // HORAS DEVIDAS
            cell.cellStyle = _estiloDadosNegrito();
          } else if (col == 12 && linhaDados[12].isNotEmpty && linhaDados[12] != '00:00') {
            // HORAS EXTRAS
            cell.cellStyle = _estiloDadosNegrito();
          } else if (col == 13 && linhaDados[13].isNotEmpty && linhaDados[13] != '00:00') {
            // EXTRA 60%
            cell.cellStyle = _estiloDadosNegrito();
          } else if (col == 14 && linhaDados[14].isNotEmpty && linhaDados[14] != '00:00') {
            // EXTRA 100%
            cell.cellStyle = _estiloDadosNegrito();
          } else {
            cell.cellStyle = _estiloDados();
          }
        }
      }
      rowIndex++;
    }
  }

  // ============================================================
  // 🔥 RODAPÉ
  // ============================================================
  static void _adicionarRodape(Sheet sheet, RelatorioMensal relatorio) {
    final row = 50;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row),
      CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: row),
    );

    final cellAssinaturaLabel = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row));
    cellAssinaturaLabel.value = TextCellValue('ASSINATURA');
    cellAssinaturaLabel.cellStyle = _estiloAssinatura();

    final cellAssinaturaLinha = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row + 1));
    cellAssinaturaLinha.value = TextCellValue('______________________________________');
    cellAssinaturaLinha.cellStyle = _estiloAssinatura();

    final cellAssinaturaNome = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: row + 2));
    cellAssinaturaNome.value = TextCellValue(relatorio.funcionarioNome);
    cellAssinaturaNome.cellStyle = _estiloAssinatura();

    // Data
    final cellData = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row));
    cellData.value = TextCellValue('/    /');
    cellData.cellStyle = _estiloAssinatura();
  }

  // ============================================================
  // 🔥 HELPERS
  // ============================================================

  static String _somarTempos(String tempo1, String tempo2) {
    final dur1 = _stringToDuration(tempo1);
    final dur2 = _stringToDuration(tempo2);
    final soma = dur1 + dur2;
    return _durationToString(soma);
  }

  static String _durationToString(Duration duration) {
    final hours = duration.inHours;
    final minutos = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
  }

  static Duration _stringToDuration(String time) {
    if (time.isEmpty || time == '00:00') return Duration.zero;
    final parts = time.split(':');
    if (parts.length == 2) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
      );
    }
    return Duration.zero;
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