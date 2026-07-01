import 'package:flutter/material.dart';
import '../models/historico_model.dart';
import 'historico_registro_widget.dart';

class HistoricoDiaWidget extends StatelessWidget {
  final HistoricoDia dia;

  const HistoricoDiaWidget({super.key, required this.dia});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                dia.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${dia.registros.length} registros',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        ...dia.registros.map((r) => HistoricoRegistroWidget(registro: r)),
        const Divider(height: 24, thickness: 0.5),
      ],
    );
  }
}