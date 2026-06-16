class Funcionario {
  final String id;
  final String empresaId;

  final String nome;
  final String email;
  final String telefone;

  final String cargo;
  final String matricula;

  final String rg;
  final String cpf;

  final DateTime dataNascimento;
  final DateTime dataAdmissao;

  final bool ativo;
  final String ?fotoPath;

  Funcionario({
    required this.id,
    required this.empresaId,

    required this.nome,
    required this.email,
    required this.telefone,

    required this.cargo,
    required this.matricula,

    required this.rg,
    required this.cpf,

    required this.dataNascimento,
    required this.dataAdmissao,

    required this.ativo,
    this.fotoPath
  });
}