import 'package:flutter/material.dart';

enum TipoAlerta { entradaAusente, saidaAusente, almocoAusente, retornoAusente }

extension TipoAlertaExtension on TipoAlerta {
  String get label {
    switch (this) {
      case TipoAlerta.entradaAusente:
        return 'Entrada Ausente';
      case TipoAlerta.saidaAusente:
        return 'Saída Ausente';
      case TipoAlerta.almocoAusente:
        return 'Almoço Ausente';
      case TipoAlerta.retornoAusente:
        return 'Retorno Ausente';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoAlerta.entradaAusente:
        return Icons.login;
      case TipoAlerta.saidaAusente:
        return Icons.logout;
      case TipoAlerta.almocoAusente:
      case TipoAlerta.retornoAusente:
        return Icons.restaurant;
    }
  }

  Color get color {
    switch (this) {
      case TipoAlerta.entradaAusente:
        return Colors.orange;
      case TipoAlerta.saidaAusente:
        return Colors.red;
      case TipoAlerta.almocoAusente:
      case TipoAlerta.retornoAusente:
        return Colors.blue;
    }
  }
}

// 🔥 Função auxiliar para converter String para Enum
TipoAlerta tipoAlertaFromString(String value) {
  switch (value) {
    case 'entradaAusente':
      return TipoAlerta.entradaAusente;
    case 'saidaAusente':
      return TipoAlerta.saidaAusente;
    case 'almocoAusente':
      return TipoAlerta.almocoAusente;
    case 'retornoAusente':
      return TipoAlerta.retornoAusente;
    default:
      return TipoAlerta.entradaAusente;
  }
}

class AlertaPonto {
  final String id;
  final String funcionarioId;
  final String funcionarioNome;
  final DateTime data;
  final TipoAlerta tipo;
  final String? justificativa;
  final bool resolvido;
  final DateTime dataCriacao;

  AlertaPonto({
    required this.id,
    required this.funcionarioId,
    required this.funcionarioNome,
    required this.data,
    required this.tipo,
    this.justificativa,
    this.resolvido = false,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  // 🔥 Converter para Map (Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'funcionarioId': funcionarioId,
      'funcionarioNome': funcionarioNome,
      'data': data.toIso8601String(),
      'tipo': tipo.name,
      'justificativa': justificativa,
      'resolvido': resolvido,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  // 🔥 Criar a partir do Map (Firestore)
  factory AlertaPonto.fromFirestore(Map<String, dynamic> data, String id) {
    return AlertaPonto(
      id: id,
      funcionarioId: data['funcionarioId'] ?? '',
      funcionarioNome: data['funcionarioNome'] ?? '',
      data: DateTime.parse(data['data']),
      tipo: tipoAlertaFromString(data['tipo'] ?? 'entradaAusente'),
      justificativa: data['justificativa'],
      resolvido: data['resolvido'] ?? false,
      dataCriacao: DateTime.parse(data['dataCriacao']),
    );
  }

  // 🔥 Formatar data para exibição
  String get dataFormatada {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String get horaFormatada {
    return '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  String get dataHoraFormatada {
    return '$dataFormatada $horaFormatada';
  }
}
