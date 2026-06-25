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
  final String? fotoPath;
  final DateTime? dataExclusao;
  final bool isAdmin;
  final bool primeiroLogin; // 🔥 NOVO

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
    this.fotoPath,
    this.dataExclusao,
    this.isAdmin = false,
    this.primeiroLogin = true, // 🔥 NOVO - PADRÃO TRUE
  });

  Map<String, dynamic> toFirestore() {
    return {
      'empresaId': empresaId,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cargo': cargo,
      'matricula': matricula,
      'rg': rg,
      'cpf': cpf,
      'dataNascimento': dataNascimento.toIso8601String(),
      'dataAdmissao': dataAdmissao.toIso8601String(),
      'ativo': ativo,
      'fotoPath': fotoPath,
      'dataExclusao': dataExclusao?.toIso8601String(),
      'isAdmin': isAdmin,
      'primeiroLogin': primeiroLogin, // 🔥 ADICIONAR
    };
  }

  factory Funcionario.fromFirestore(Map<String, dynamic> data, String id) {
    return Funcionario(
      id: id,
      empresaId: data['empresaId'] ?? '',
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      telefone: data['telefone'] ?? '',
      cargo: data['cargo'] ?? '',
      matricula: data['matricula'] ?? '',
      rg: data['rg'] ?? '',
      cpf: data['cpf'] ?? '',
      dataNascimento: DateTime.parse(data['dataNascimento']),
      dataAdmissao: DateTime.parse(data['dataAdmissao']),
      ativo: data['ativo'] ?? true,
      fotoPath: data['fotoPath'] ?? data['fotoURL'],
      dataExclusao: data['dataExclusao'] != null
          ? DateTime.parse(data['dataExclusao'])
          : null,
      isAdmin: data['isAdmin'] ?? false,
      primeiroLogin: data['primeiroLogin'] ?? true, // 🔥 ADICIONAR
    );
  }
}