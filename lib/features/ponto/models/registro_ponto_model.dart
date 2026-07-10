import 'package:flutter/material.dart';

enum TipoPonto { entrada, saidaAlmoco, retornoAlmoco, saida }

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
  final String metodoAutenticacao;
  final String? fotoURL;
  final bool sincronizado;
  final DateTime dataCriacao;
  final bool enderecoPendente;

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
    this.enderecoPendente = false,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Map<String, dynamic> toFirestore() {
    return {
      'funcionarioId': funcionarioId,
      'funcionarioNome': funcionarioNome,
      // 🔥 SALVAR EM UTC
      'dataHora': dataHora.toUtc().toIso8601String(),
      'tipo': tipo.name,
      'latitude': latitude,
      'longitude': longitude,
      'endereco': endereco,
      'metodoAutenticacao': metodoAutenticacao,
      'fotoURL': fotoURL,
      'sincronizado': sincronizado,
      'dataCriacao': dataCriacao.toUtc().toIso8601String(),
      'enderecoPendente': enderecoPendente,
    };
  }

  factory RegistroPonto.fromFirestore(Map<String, dynamic> data, String id) {
    return RegistroPonto(
      id: id,
      funcionarioId: data['funcionarioId'] ?? '',
      funcionarioNome: data['funcionarioNome'] ?? '',
      // 🔥 CONVERTER PARA LOCAL
      dataHora: DateTime.parse(data['dataHora']).toLocal(),
      tipo: TipoPontoExtension.fromString(data['tipo'] ?? 'entrada'),
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      endereco: data['endereco'] ?? 'Local não identificado',
      metodoAutenticacao: data['metodoAutenticacao'] ?? 'senha',
      fotoURL: data['fotoURL'],
      sincronizado: data['sincronizado'] ?? true,
      dataCriacao: DateTime.parse(data['dataCriacao']).toLocal(),
      enderecoPendente: data['enderecoPendente'] ?? false,
    );
  }

  String get horaFormatada {
    return '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
  }

  String get dataFormatada {
    return '${dataHora.day.toString().padLeft(2, '0')}/'
        '${dataHora.month.toString().padLeft(2, '0')}/'
        '${dataHora.year}';
  }
}