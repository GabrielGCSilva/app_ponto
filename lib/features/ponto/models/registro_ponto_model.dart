import 'package:flutter/material.dart';

enum TipoPonto {
  entrada,
  saidaAlmoco,
  retornoAlmoco,
  saida,
}

extension TipoPontoExtension on TipoPonto {
  String get label {
    switch (this) {
      case TipoPonto.entrada:
        return 'Entrada';
      case TipoPonto.saidaAlmoco:
        return 'Saída para Almoço';
      case TipoPonto.retornoAlmoco:
        return 'Retorno do Almoço';
      case TipoPonto.saida:
        return 'Saída';
    }
  }

  IconData get icon {
    switch (this) {
      case TipoPonto.entrada:
        return Icons.login;
      case TipoPonto.saidaAlmoco:
        return Icons.restaurant;
      case TipoPonto.retornoAlmoco:
        return Icons.restaurant;
      case TipoPonto.saida:
        return Icons.logout;
    }
  }

  Color get color {
    switch (this) {
      case TipoPonto.entrada:
        return Colors.green;
      case TipoPonto.saidaAlmoco:
        return Colors.orange;
      case TipoPonto.retornoAlmoco:
        return Colors.blue;
      case TipoPonto.saida:
        return Colors.red;
    }
  }

  // 🔥 Converter de String para Enum
  static TipoPonto fromString(String value) {
    switch (value) {
      case 'entrada':
        return TipoPonto.entrada;
      case 'saidaAlmoco':
        return TipoPonto.saidaAlmoco;
      case 'retornoAlmoco':
        return TipoPonto.retornoAlmoco;
      case 'saida':
        return TipoPonto.saida;
      default:
        return TipoPonto.entrada;
    }
  }
}

class RegistroPonto {
  final String id;
  final String funcionarioId;
  final String funcionarioNome;
  final DateTime dataHora;
  final TipoPonto tipo;
  final double latitude;
  final double longitude;
  final String endereco;
  final String metodoAutenticacao; // "digital", "facial", "senha"
  final String? fotoURL;
  final bool sincronizado;
  final DateTime dataCriacao;

  RegistroPonto({
    required this.id,
    required this.funcionarioId,
    required this.funcionarioNome,
    required this.dataHora,
    required this.tipo,
    required this.latitude,
    required this.longitude,
    required this.endereco,
    required this.metodoAutenticacao,
    this.fotoURL,
    this.sincronizado = true,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  // 🔥 Converter para Map (Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'funcionarioId': funcionarioId,
      'funcionarioNome': funcionarioNome,
      'dataHora': dataHora.toIso8601String(),
      'tipo': tipo.name,
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'metodoAutenticacao': metodoAutenticacao,
      'fotoURL': fotoURL,
      'sincronizado': sincronizado,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  // 🔥 Criar a partir do Map (Firestore)
  factory RegistroPonto.fromFirestore(Map<String, dynamic> data, String id) {
    return RegistroPonto(
      id: id,
      funcionarioId: data['funcionarioId'] ?? '',
      funcionarioNome: data['funcionarioNome'] ?? '',
      dataHora: DateTime.parse(data['dataHora']),
      tipo: TipoPontoExtension.fromString(data['tipo'] ?? 'entrada'),
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      endereco: data['endereco'] ?? 'Local não identificado',
      metodoAutenticacao: data['metodoAutenticacao'] ?? 'senha',
      fotoURL: data['fotoURL'],
      sincronizado: data['sincronizado'] ?? true,
      dataCriacao: DateTime.parse(data['dataCriacao']),
    );
  }

  // 🔥 Formatar hora para exibição
  String get horaFormatada {
    return '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
  }

  // 🔥 Formatar data para exibição
  String get dataFormatada {
    return '${dataHora.day.toString().padLeft(2, '0')}/'
        '${dataHora.month.toString().padLeft(2, '0')}/'
        '${dataHora.year}';
  }
}