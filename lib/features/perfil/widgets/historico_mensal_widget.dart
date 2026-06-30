import 'package:flutter/material.dart';
import '../models/historico_model.dart';
import 'historico_dia_widget.dart';

class HistoricoMensalWidget extends StatelessWidget {
  final HistoricoMes mes;

  const HistoricoMensalWidget({super.key, required this.mes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔥 Cabeçalho do mês
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                mes.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: ${mes.totalHorasFormatado}h',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // 🔥 Dias do mês
        ...mes.dias.map((d) => HistoricoDiaWidget(dia: d)),
        
        const SizedBox(height: 16),
      ],
    );
  }
}