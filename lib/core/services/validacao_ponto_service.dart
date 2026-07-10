import '../../features/ponto/models/registro_ponto_model.dart';

class ValidacaoPontoService {
  /// Valida se o funcionário pode registrar um ponto
  static ValidationResult validar({
    required TipoPonto tipo,
    required List<RegistroPonto> registrosHoje,
    required bool isAdmin,
    required bool isSobrescrevendo,
  }) {
    // 🔥 Verificar se já existe este tipo de ponto hoje
    final jaExiste = registrosHoje.any((r) => r.tipo == tipo);

    // 🔥 1. PRIMEIRO: Se for admin e estiver sobrescrevendo, permitir DIRETO!
    if (isAdmin && isSobrescrevendo) {
      return ValidationResult(
        permitido: true,
        mensagem: '✅ ${tipo.label} sobrescrita com sucesso!',
        precisaConfirmar: false,
      );
    }

    // 🔥 2. SEGUNDO: Se for admin e já existe, perguntar se quer sobrescrever
    if (isAdmin && jaExiste) {
      return ValidationResult(
        permitido: true, // 🔥 MUDANÇA: permite (antes era false)
        mensagem:
            '⚠️ Atenção: Este ponto já foi registrado hoje. '
            'Deseja sobrescrever o registro anterior?',
        precisaConfirmar: true,
      );
    }

    // 🔥 3. TERCEIRO: Se não for admin e já existe, bloquear
    if (jaExiste && !isAdmin) {
      return ValidationResult(
        permitido: false,
        mensagem: '❌ ${tipo.label} já foi registrado hoje!',
        precisaConfirmar: false,
      );
    }

    // 🔥 Buscar registros existentes
    final temEntrada = registrosHoje.any((r) => r.tipo == TipoPonto.entrada);
    final temSaidaAlmoco = registrosHoje.any(
      (r) => r.tipo == TipoPonto.saidaAlmoco,
    );
    final temRetornoAlmoco = registrosHoje.any(
      (r) => r.tipo == TipoPonto.retornoAlmoco,
    );

    // 🔥 Regra 1: Só pode bater "Saída para Almoço" se já bateu "Entrada"
    if (tipo == TipoPonto.saidaAlmoco && !temEntrada) {
      return ValidationResult(
        permitido: false,
        mensagem:
            '❌ Para registrar "Saída para Almoço", você precisa primeiro registrar a "Entrada".',
        precisaConfirmar: false,
      );
    }

    // 🔥 Regra 2: Só pode bater "Retorno do Almoço" se já bateu "Saída para Almoço"
    if (tipo == TipoPonto.retornoAlmoco && !temSaidaAlmoco) {
      return ValidationResult(
        permitido: false,
        mensagem:
            '❌ Para registrar "Retorno do Almoço", você precisa primeiro registrar a "Saída para Almoço".',
        precisaConfirmar: false,
      );
    }

    // 🔥 Regra 3: Só pode bater "Saída" se já bateu "Entrada"
    if (tipo == TipoPonto.saida && !temEntrada) {
      return ValidationResult(
        permitido: false,
        mensagem:
            '❌ Para registrar "Saída", você precisa primeiro registrar a "Entrada".',
        precisaConfirmar: false,
      );
    }

    // 🔥 Regra 4: Se bateu "Saída para Almoço", precisa bater "Retorno" antes da "Saída"
    if (tipo == TipoPonto.saida && temSaidaAlmoco && !temRetornoAlmoco) {
      return ValidationResult(
        permitido: false,
        mensagem:
            '❌ Você registrou "Saída para Almoço" mas ainda não registrou o "Retorno do Almoço". '
            'Registre o retorno antes de bater a "Saída".',
        precisaConfirmar: false,
      );
    }

    // 🔥 Tudo certo!
    return ValidationResult(
      permitido: true,
      mensagem: '✅ ${tipo.label} permitida!',
      precisaConfirmar: false,
    );
  }
}

/// Resultado da validação
class ValidationResult {
  final bool permitido;
  final String mensagem;
  final bool precisaConfirmar;

  ValidationResult({
    required this.permitido,
    required this.mensagem,
    required this.precisaConfirmar,
  });
}
