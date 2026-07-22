import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../services/relatorio_service.dart';
import '../services/excel_export_service.dart';
import '../services/excel_export_helper.dart';
import '../models/relatorio_model.dart';
import '../../funcionario/providers/funcionario_provider.dart';

// ============================================================
// 📊 PÁGINA PRINCIPAL DE RELATÓRIOS
// ============================================================
class RelatoriosPage extends StatefulWidget {
  final String? funcionarioId;
  final int? mes;
  final int? ano;

  const RelatoriosPage({super.key, this.funcionarioId, this.mes, this.ano});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

// ============================================================
// 📊 STATE DA PÁGINA DE RELATÓRIOS
// ============================================================
class _RelatoriosPageState extends State<RelatoriosPage> {
  // 🔥 VARIÁVEIS DE ESTADO
  String? _funcionarioSelecionado;
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;
  bool _carregando = false;
  RelatorioMensal? _relatorio;
  bool _mostrarRelatorio = false;

  // 🔥 SERVIÇOS
  final RelatorioService _service = RelatorioService();

  // ============================================================
  // 🔥 CICLO DE VIDA
  // ============================================================
  @override
  void initState() {
    super.initState();

    if (widget.funcionarioId != null && widget.funcionarioId!.isNotEmpty) {
      _funcionarioSelecionado = widget.funcionarioId;
    }
    _mesSelecionado = widget.mes ?? DateTime.now().month;
    _anoSelecionado = widget.ano ?? DateTime.now().year;

    if (_funcionarioSelecionado != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gerarRelatorio();
      });
    }
  }

  // ============================================================
  // 🔥 BUILD PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final funcionarioProvider = context.watch<FuncionarioProvider>();

    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCabecalho(),
            const SizedBox(height: 20),
            _buildFiltros(funcionarioProvider),
            const SizedBox(height: 16),
            _buildBotoesAcao(),
            const SizedBox(height: 20),
            _buildConteudoPrincipal(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 COMPONENTES DA UI
  // ============================================================

  // 📱 APP BAR
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('📊 Relatórios'),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/dashboard'),
        tooltip: 'Voltar ao Dashboard',
      ),
      actions: [
        if (_relatorio != null && _mostrarRelatorio) ...[
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportarExcel,
            tooltip: 'Exportar Excel',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _compartilharLink,
            tooltip: 'Compartilhar link da tabela',
          ),
        ],
      ],
    );
  }

  // 📝 CABEÇALHO
  Widget _buildCabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gerar Relatório Mensal',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione o funcionário e o período para gerar o espelho de ponto.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // 🎯 FILTROS (SEM CARD)
  Widget _buildFiltros(FuncionarioProvider funcionarioProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdownFuncionario(funcionarioProvider),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdownMes()),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdownAno()),
              const SizedBox(width: 12),
              _buildBotaoGerar(),
            ],
          );
        } else {
          return Column(
            children: [
              _buildDropdownFuncionario(funcionarioProvider),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildDropdownMes()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildDropdownAno()),
                ],
              ),
              const SizedBox(height: 8),
              _buildBotaoGerar(),
            ],
          );
        }
      },
    );
  }

  // 👤 DROPDOWN FUNCIONÁRIO
  Widget _buildDropdownFuncionario(FuncionarioProvider funcionarioProvider) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Funcionário *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      initialValue: _funcionarioSelecionado,
      items: funcionarioProvider.funcionarios.map((f) {
        return DropdownMenuItem(value: f.id, child: Text(f.nome));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _funcionarioSelecionado = value;
          _mostrarRelatorio = false;
          _relatorio = null;
        });
      },
    );
  }

  // 📅 DROPDOWN MÊS
  Widget _buildDropdownMes() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Mês',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_month),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      initialValue: _mesSelecionado,
      items: List.generate(12, (i) => i + 1).map((mes) {
        return DropdownMenuItem(value: mes, child: Text(_getNomeMes(mes)));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _mesSelecionado = value!;
          _mostrarRelatorio = false;
          _relatorio = null;
        });
      },
    );
  }

  // 📆 DROPDOWN ANO
  Widget _buildDropdownAno() {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Ano',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      initialValue: _anoSelecionado,
      items: List.generate(10, (i) => DateTime.now().year - i).map((ano) {
        return DropdownMenuItem(value: ano, child: Text(ano.toString()));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _anoSelecionado = value!;
          _mostrarRelatorio = false;
          _relatorio = null;
        });
      },
    );
  }

  // 🔍 BOTÃO GERAR
  Widget _buildBotaoGerar() {
    return ElevatedButton.icon(
      onPressed: _funcionarioSelecionado == null ? null : _gerarRelatorio,
      icon: _carregando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.search),
      label: Text(_carregando ? 'Gerando...' : 'Gerar'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 🎯 BOTÕES DE AÇÃO (SEM CARD)
  Widget _buildBotoesAcao() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildActionButton(
          icon: Icons.picture_as_pdf,
          label: 'Espelho de Ponto',
          color: Colors.blue,
          onTap: _funcionarioSelecionado == null ? null : _gerarRelatorio,
        ),
        _buildActionButton(
          icon: Icons.table_chart,
          label: 'Exportar Excel',
          color: Colors.green,
          onTap: _relatorio == null ? null : _exportarExcel,
        ),
        _buildActionButton(
          icon: Icons.ios_share,
          label: 'Compartilhar Link',
          color: Colors.purple,
          onTap: _relatorio == null ? null : _compartilharLink,
        ),
      ],
    );
  }

  // 🔘 BOTÃO DE AÇÃO GENÉRICO
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // 📊 CONTEÚDO PRINCIPAL
  Widget _buildConteudoPrincipal() {
    if (_carregando) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Gerando relatório...'),
            ],
          ),
        ),
      );
    }

    if (_mostrarRelatorio && _relatorio != null) {
      return Expanded(child: _buildRelatorio(_relatorio!));
    }

    if (_funcionarioSelecionado != null) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Clique em "Gerar" para visualizar o relatório',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Selecione um funcionário para começar',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 MÉTODOS DE NEGÓCIO
  // ============================================================

  // 📅 NOME DO MÊS
  String _getNomeMes(int mes) {
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

  // 🔍 GERAR RELATÓRIO
  Future<void> _gerarRelatorio() async {
    if (_funcionarioSelecionado == null) return;

    setState(() {
      _carregando = true;
      _mostrarRelatorio = false;
    });

    try {
      final relatorio = await _service.gerarRelatorioMensal(
        funcionarioId: _funcionarioSelecionado!,
        mes: _mesSelecionado,
        ano: _anoSelecionado,
      );

      if (mounted) {
        setState(() {
          _relatorio = relatorio;
          _mostrarRelatorio = true;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        _mostrarErro('Erro ao gerar relatório', e.toString());
      }
    }
  }

  // 📊 EXIBIR RELATÓRIO
  Widget _buildRelatorio(RelatorioMensal relatorio) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCabecalhoRelatorio(relatorio),
              const SizedBox(height: 16),
              _buildTabelaRelatorio(relatorio),
              const SizedBox(height: 16),
              _buildTotaisRelatorio(relatorio),
            ],
          ),
        ),
      ),
    );
  }

  // 📋 CABEÇALHO DO RELATÓRIO
  Widget _buildCabecalhoRelatorio(RelatorioMensal relatorio) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  relatorio.funcionarioNome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(relatorio.cargo),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_getNomeMes(relatorio.mes)}/${relatorio.ano}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Horas Mensais: ${relatorio.horasMensais}'),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 TABELA DO RELATÓRIO
  Widget _buildTabelaRelatorio(RelatorioMensal relatorio) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 10,
          horizontalMargin: 8,
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          border: TableBorder.all(color: Colors.grey.shade400, width: 1),
          columns: _buildColunasTabela(),
          rows: relatorio.dias.map((dia) => _buildLinhaTabela(dia)).toList(),
        ),
      ),
    );
  }

  // 📋 COLUNAS DA TABELA
  List<DataColumn> _buildColunasTabela() {
    return const [
      DataColumn(
        label: Text(
          'DATA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'D.SEMANA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'EVENTO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'ENTRADA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'S.ALMOÇO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'TOTAL',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'R.ALMOÇO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'SAÍDA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'TOTAL',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'TOTAL PREVISTO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'TOTAL EFETIVO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'HORAS DEVIDAS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'HORAS EXTRAS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'EXTRA 60%',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'EXTRA 100%',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'LOCALIZAÇÃO.E',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      DataColumn(
        label: Text(
          'LOCALIZAÇÃO.S',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    ];
  }

  // 📝 LINHA DA TABELA
  DataRow _buildLinhaTabela(RelatorioDiario dia) {
  final totalPrevisto = dia.totalPrevisto;
  final totalEfetivo = dia.total;
  final diff = _calcularDiferenca(totalEfetivo, totalPrevisto);

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

  // 🔥 CALCULAR TOTAL 1 (ENTRADA → S.ALMOÇO)
  final total1 = _calcularDiferencaEntreHorarios(dia.entrada, dia.saidaAlmoco);

  // 🔥 CALCULAR TOTAL 2 (R.ALMOÇO → SAÍDA)
  final total2 = _calcularDiferencaEntreHorarios(dia.retornoAlmoco, dia.saida);

  // 🔥 TOTAL EFETIVO DO DIA (TOTAL1 + TOTAL2)
  final totalEfetivoDia = _somarTempos(total1, total2);

  return DataRow(
    color: _getCorLinha(dia.evento),
    cells: [
      DataCell(
        Text(_formatarData(dia.data), style: const TextStyle(fontSize: 11)),
      ),
      DataCell(
        Text(
          dia.diaSemana,
          style: TextStyle(
            fontSize: 11,
            fontWeight: dia.evento == 'FOLGA' ? FontWeight.bold : FontWeight.normal,
            color: dia.evento == 'FOLGA' ? Colors.green : Colors.black,
          ),
        ),
      ),
      DataCell(Text(dia.evento ?? '', style: const TextStyle(fontSize: 11))),
      DataCell(Text(dia.entrada, style: const TextStyle(fontSize: 11))),
      DataCell(Text(dia.saidaAlmoco, style: const TextStyle(fontSize: 11))),
      DataCell(
        Text(
          total1,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: total1 != '00:00' ? Colors.blue.shade700 : Colors.grey,
          ),
        ),
      ),
      DataCell(Text(dia.retornoAlmoco, style: const TextStyle(fontSize: 11))),
      DataCell(Text(dia.saida, style: const TextStyle(fontSize: 11))),
      DataCell(
        Text(
          total2,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: total2 != '00:00' ? Colors.blue.shade700 : Colors.grey,
          ),
        ),
      ),
      DataCell(Text(totalPrevisto, style: const TextStyle(fontSize: 11))),
      DataCell(
        Text(
          totalEfetivoDia,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: totalEfetivoDia != '00:00' ? Colors.green.shade700 : Colors.grey,
          ),
        ),
      ),
      DataCell(
        Text(
          horasDevidasDia,
          style: TextStyle(
            fontSize: 11,
            color: horasDevidasDia != '00:00' ? Colors.red : Colors.grey,
          ),
        ),
      ),
      DataCell(
        Text(
          horasExtrasDia,
          style: TextStyle(
            fontSize: 11,
            color: horasExtrasDia != '00:00' ? Colors.green : Colors.grey,
          ),
        ),
      ),
      DataCell(
        Text(
          extra60Dia,
          style: TextStyle(
            fontSize: 11,
            color: extra60Dia != '00:00' ? Colors.orange : Colors.grey,
          ),
        ),
      ),
      DataCell(
        Text(
          extra100Dia,
          style: TextStyle(
            fontSize: 11,
            color: extra100Dia != '00:00' ? Colors.purple : Colors.grey,
          ),
        ),
      ),
      DataCell(
        Container(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            dia.localizacaoEntrada,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      DataCell(
        Container(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            dia.localizacaoSaida,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ],
  );
}

  // 🎨 COR DA LINHA
  WidgetStateProperty<Color?> _getCorLinha(String? evento) {
    if (evento == 'FALTA') {
      return WidgetStateProperty.all<Color?>(Colors.red.shade50);
    } else if (evento == 'FOLGA') {
      return WidgetStateProperty.all<Color?>(Colors.green.shade50);
    }
    return WidgetStateProperty.all<Color?>(null);
  }

  // 💰 TOTAIS DO RELATÓRIO
  Widget _buildTotaisRelatorio(RelatorioMensal relatorio) {
    final corHorasDevidas = relatorio.horasDevidas != '00:00'
        ? Colors.red
        : Colors.grey;
    final corHorasExtras = relatorio.horasExtrasTrabalhadas != '00:00'
        ? Colors.green
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildTotalItem(
                'Total Previsto',
                relatorio.totalPrevisto,
                Colors.blue,
              ),
              _buildTotalItem(
                'Total Efetivo',
                relatorio.totalEfetivo,
                Colors.green,
              ),
              _buildTotalItem(
                'Horas Devidas',
                relatorio.horasDevidas,
                corHorasDevidas,
              ),
              _buildTotalItem(
                'Horas Extras',
                relatorio.horasExtrasTrabalhadas,
                corHorasExtras,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTotalItem(
                'Extra 60%',
                relatorio.horasExtras60,
                Colors.orange,
              ),
              _buildTotalItem(
                'Extra 100%',
                relatorio.horasExtras100,
                Colors.purple,
              ),
              _buildTotalItem(
                'Subtotal',
                relatorio.subtotal,
                Colors.blue.shade700,
              ),
              _buildTotalItem('Total', relatorio.total, Colors.blue.shade900),
            ],
          ),
        ],
      ),
    );
  }

  // 🏷️ ITEM DE TOTAL
  Widget _buildTotalItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 UTILITÁRIOS
  // ============================================================

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
  }

  Duration _calcularDiferenca(String efetivo, String previsto) {
    final efetivoDur = _stringToDuration(efetivo);
    final previstoDur = _stringToDuration(previsto);
    return efetivoDur - previstoDur;
  }

  Duration _stringToDuration(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
      );
    }
    return Duration.zero;
  }

  String _durationToString(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // 🔥 CALCULAR DIFERENÇA ENTRE DOIS HORÁRIOS
  String _calcularDiferencaEntreHorarios(String inicio, String fim) {
    if (inicio.isEmpty || fim.isEmpty) return '00:00';
    try {
      final inicioDur = _stringToDuration(inicio);
      final fimDur = _stringToDuration(fim);
      final diff = fimDur - inicioDur;
      if (diff.isNegative) return '00:00';
      return _durationToString(diff);
    } catch (e) {
      return '00:00';
    }
  }

  // 🔥 SOMAR DOIS TEMPOS
  String _somarTempos(String tempo1, String tempo2) {
    final dur1 = _stringToDuration(tempo1);
    final dur2 = _stringToDuration(tempo2);
    final soma = dur1 + dur2;
    return _durationToString(soma);
  }

  // ============================================================
  // 🔥 EXPORTAR EXCEL - MULTIPLATAFORMA
  // ============================================================
  void _exportarExcel() async {
    if (_relatorio == null) return;

    try {
      final bytes = ExcelExportService.gerarExcelRelatorio(_relatorio!);
      if (bytes == null) {
        throw Exception('Erro ao gerar Excel');
      }

      final nomeArquivo =
          'espelho_ponto_${_relatorio!.funcionarioNome}_${_relatorio!.mes}_${_relatorio!.ano}.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([
          bytes,
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)..download = nomeArquivo;
        anchor.click();
        html.Url.revokeObjectUrl(url);
      } else {
        await ExcelExportHelper.salvarECompartilhar(bytes, nomeArquivo);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? '✅ Excel exportado com sucesso!'
                  : '✅ Excel salvo e compartilhado!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // 🔥 COMPARTILHAR LINK
  // ============================================================
  void _compartilharLink() {
    if (_relatorio == null) return;

    final nome = _relatorio!.funcionarioNome;
    final mes = _getNomeMes(_relatorio!.mes);
    final ano = _relatorio!.ano;
    final funcionarioId = _relatorio!.funcionarioId;
    final mesNum = _relatorio!.mes;
    final anoNum = _relatorio!.ano;

    final linkLocal =
        '${Uri.base.origin}/#/relatorios?funcionarioId=$funcionarioId&mes=$mesNum&ano=$anoNum';
    final linkProducao =
        'https://app-ponto-ggc.web.app/relatorios?funcionarioId=$funcionarioId&mes=$mesNum&ano=$anoNum';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🔗 Compartilhar Relatório'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relatório de $nome - $mes/$ano',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '📋 Selecione o tipo de link:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLinkOption(
              titulo: '🖥️ Desenvolvimento (Local)',
              link: linkLocal,
              cor: Colors.blue,
              detalhe: '✅ Funciona agora (porta ${Uri.base.port})',
            ),
            const SizedBox(height: 12),
            _buildLinkOption(
              titulo: '🚀 Produção (Publicado)',
              link: linkProducao,
              cor: Colors.green,
              detalhe: '✅ Funciona quando o app estiver publicado em produção',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '💡 Use o link de "Desenvolvimento" para testar agora.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _copiarLink(linkLocal);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar Link Local'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _copiarLink(linkProducao);
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar Link Produção'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _abrirLink(linkLocal);
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir Local'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 🔗 OPÇÃO DE LINK
  Widget _buildLinkOption({
    required String titulo,
    required String link,
    required Color cor,
    required String detalhe,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(link, style: TextStyle(fontSize: 11, color: cor)),
          const SizedBox(height: 4),
          Text(
            detalhe,
            style: TextStyle(fontSize: 10, color: cor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  // 📋 COPIAR LINK
  void _copiarLink(String link) async {
    try {
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Link copiado para a área de transferência!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarErro('Erro ao copiar', e.toString());
      }
    }
  }

  // 🌐 ABRIR LINK
  void _abrirLink(String link) async {
    try {
      final Uri url = Uri.parse(link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Não foi possível abrir o link';
      }
    } catch (e) {
      if (mounted) {
        _mostrarErro('Erro ao abrir', e.toString());
      }
    }
  }

  // ❌ MOSTRAR ERRO
  void _mostrarErro(String titulo, String detalhe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $titulo: $detalhe'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}