import 'package:flutter/material.dart';
import '../../ponto/models/registro_ponto_model.dart';
import 'package:intl/intl.dart';

class HistoricoRegistroWidget extends StatelessWidget {
  final RegistroPonto registro;

  const HistoricoRegistroWidget({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    final cor = registro.tipo.color;
    final icon = registro.tipo.icon;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 🔥 Ícone do tipo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cor, size: 20),
          ),
          const SizedBox(width: 12),
          
          // 🔥 Tipo e local
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registro.tipo.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  registro.endereco,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // 🔥 Horário
          Text(
            DateFormat('HH:mm').format(registro.dataHora),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}