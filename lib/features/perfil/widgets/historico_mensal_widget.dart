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
        // 🔥 CABEÇALHO DO MÊS (SEM TOTAL DE HORAS)
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
              // 🔥 REMOVIDO O TOTAL DE HORAS
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...mes.dias.map((d) => HistoricoDiaWidget(dia: d)),
        const SizedBox(height: 16),
      ],
    );
  }
}