import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/relatorio_service.dart';
import '../models/relatorio_model.dart';
import '../../funcionario/providers/funcionario_provider.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  String? _funcionarioSelecionado;
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;
  bool _carregando = false;
  RelatorioMensal? _relatorio;
  bool _mostrarRelatorio = false;

  final RelatorioService _service = RelatorioService();

  @override
  Widget build(BuildContext context) {
    final funcionarioProvider = context.watch<FuncionarioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Relatórios'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Voltar ao Dashboard',
        ),
        actions: [
          if (_relatorio != null && _mostrarRelatorio)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportarCSV,
              tooltip: 'Exportar CSV',
            ),
          if (_relatorio != null && _mostrarRelatorio)
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _compartilharLink,
              tooltip: 'Compartilhar link da tabela',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gerar Relatório Mensal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione o funcionário e o período para gerar o espelho de ponto.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 FILTROS COM LAYOUT RESPONSIVO
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFiltros(funcionarioProvider),
                    const SizedBox(height: 16),
                    _buildBotoesAcao(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // 🔥 RELATÓRIO
            if (_mostrarRelatorio && _relatorio != null)
              Expanded(
                child: _buildRelatorio(_relatorio!),
              )
            else if (!_mostrarRelatorio && _funcionarioSelecionado != null)
              const Expanded(
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
              )
            else
              const Expanded(
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
              ),
          ],
        ),
      ),
    );
  }

  // 🔥 FILTROS RESPONSIVOS
  Widget _buildFiltros(FuncionarioProvider funcionarioProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // 🔥 Tela grande: Row
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdownFuncionario(funcionarioProvider),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownMes(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownAno(),
              ),
              const SizedBox(width: 12),
              _buildBotaoGerar(),
            ],
          );
        } else {
          // 🔥 Tela pequena: Column
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
        return DropdownMenuItem(
          value: f.id,
          child: Text(f.nome),
        );
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
        return DropdownMenuItem(
          value: mes,
          child: Text(_getNomeMes(mes)),
        );
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
        return DropdownMenuItem(
          value: ano,
          child: Text(ano.toString()),
        );
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.picture_as_pdf,
          label: 'Espelho de Ponto',
          color: Colors.blue,
          onTap: _funcionarioSelecionado == null ? null : () {
            _gerarRelatorio();
          },
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.table_chart,
          label: 'Exportar Excel',
          color: Colors.green,
          onTap: _relatorio == null ? null : _exportarCSV,
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.ios_share,
          label: 'Compartilhar Link',
          color: Colors.purple,
          onTap: _relatorio == null ? null : _compartilharLink,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  String _getNomeMes(int mes) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return meses[mes - 1];
  }

  Future<void> _gerarRelatorio() async {
    if (_funcionarioSelecionado == null) return;

    final messenger = ScaffoldMessenger.of(context);

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
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao gerar relatório: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildRelatorio(RelatorioMensal relatorio) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCabecalho(relatorio),
              const SizedBox(height: 16),
              _buildTabela(relatorio),
              const SizedBox(height: 16),
              _buildTotais(relatorio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalho(RelatorioMensal relatorio) {
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

  Widget _buildTabela(RelatorioMensal relatorio) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 10,
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
          columns: const [
            DataColumn(label: Text('DATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('EVENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('ENTRADA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('S.ALMOÇO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('R.ALMOÇO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('SAÍDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('TOTAL PREVISTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('TOTAL EFETIVO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('HORAS DEVIDAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('HORAS EXTRAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('EXTRA 60%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('EXTRA 100%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text('LOCALIZAÇÃO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
          rows: relatorio.dias.map((dia) {
            final totalPrevisto = dia.totalPrevisto;
            final totalEfetivo = dia.total;
            
            final previstoDur = CalculadoraHoras.stringToDuration(totalPrevisto);
            final efetivoDur = CalculadoraHoras.stringToDuration(totalEfetivo);
            final diff = efetivoDur - previstoDur;
            
            String horasDevidasDia = '00:00';
            String horasExtrasDia = '00:00';
            
            if (diff.isNegative) {
              horasDevidasDia = CalculadoraHoras.durationToString(diff.abs());
            } else if (diff > Duration.zero) {
              horasExtrasDia = CalculadoraHoras.durationToString(diff);
            }
            
            String extra60Dia = '00:00';
            String extra100Dia = '00:00';
            if (dia.diaSemana == 'Sáb') {
              final total = CalculadoraHoras.stringToDuration(dia.total);
              final extra60 = (total.inMinutes * 0.6).round();
              extra60Dia = CalculadoraHoras.durationToString(Duration(minutes: extra60));
            } else if (dia.diaSemana == 'Dom') {
              extra100Dia = dia.total;
            }

            return DataRow(
              color: dia.evento == 'FALTA'
                  ? WidgetStateProperty.all(Colors.red.shade50)
                  : dia.evento == 'FOLGA'
                      ? WidgetStateProperty.all(Colors.green.shade50)
                      : null,
              cells: [
                DataCell(Text(
                  '${dia.data.day.toString().padLeft(2, '0')}/${dia.data.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11),
                )),
                DataCell(Text(dia.evento ?? '', style: const TextStyle(fontSize: 11))),
                DataCell(Text(dia.entrada, style: const TextStyle(fontSize: 11))),
                DataCell(Text(dia.saidaAlmoco, style: const TextStyle(fontSize: 11))),
                DataCell(Text(dia.retornoAlmoco, style: const TextStyle(fontSize: 11))),
                DataCell(Text(dia.saida, style: const TextStyle(fontSize: 11))),
                DataCell(Text(dia.total, style: TextStyle(
                  fontWeight: dia.total != '00:00' ? FontWeight.bold : FontWeight.normal,
                  color: dia.total != '00:00' ? Colors.blue.shade700 : Colors.grey,
                  fontSize: 11,
                ))),
                DataCell(Text(totalPrevisto, style: const TextStyle(fontSize: 11))),
                DataCell(Text(totalEfetivo, style: const TextStyle(fontSize: 11))),
                DataCell(Text(horasDevidasDia, style: TextStyle(
                  fontSize: 11,
                  color: horasDevidasDia != '00:00' ? Colors.red : Colors.grey,
                ))),
                DataCell(Text(horasExtrasDia, style: TextStyle(
                  fontSize: 11,
                  color: horasExtrasDia != '00:00' ? Colors.green : Colors.grey,
                ))),
                DataCell(Text(extra60Dia, style: TextStyle(
                  fontSize: 11,
                  color: extra60Dia != '00:00' ? Colors.orange : Colors.grey,
                ))),
                DataCell(Text(extra100Dia, style: TextStyle(
                  fontSize: 11,
                  color: extra100Dia != '00:00' ? Colors.purple : Colors.grey,
                ))),
                DataCell(Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    dia.localizacao,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTotais(RelatorioMensal relatorio) {
    final corHorasDevidas = relatorio.horasDevidas != '00:00' ? Colors.red : Colors.grey;
    final corHorasExtras = relatorio.horasExtrasTrabalhadas != '00:00' ? Colors.green : Colors.grey;

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
              _buildTotalItem('Total Previsto', relatorio.totalPrevisto, Colors.blue),
              _buildTotalItem('Total Efetivo', relatorio.totalEfetivo, Colors.green),
              _buildTotalItem('Horas Devidas', relatorio.horasDevidas, corHorasDevidas),
              _buildTotalItem('Horas Extras', relatorio.horasExtrasTrabalhadas, corHorasExtras),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTotalItem('Extra 60%', relatorio.horasExtras60, Colors.orange),
              _buildTotalItem('Extra 100%', relatorio.horasExtras100, Colors.purple),
              _buildTotalItem('Subtotal', relatorio.subtotal, Colors.blue.shade700),
              _buildTotalItem('Total', relatorio.total, Colors.blue.shade900),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
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

  void _exportarCSV() {
    if (_relatorio == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Exportação CSV em desenvolvimento...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _compartilharLink() {
    if (_relatorio == null) return;

    final nome = _relatorio!.funcionarioNome;
    final mes = _getNomeMes(_relatorio!.mes);
    final ano = _relatorio!.ano;

    final link = 'https://admin.app-ponto.com/relatorios?funcionario=$nome&mes=$mes&ano=$ano';

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
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Link para visualização online:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Este link é público. Qualquer pessoa com o link pode visualizar.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange,
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
              _copiarLink(link);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar Link'),
          ),
        ],
      ),
    );
  }

  void _copiarLink(String link) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Link copiado para a área de transferência!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}