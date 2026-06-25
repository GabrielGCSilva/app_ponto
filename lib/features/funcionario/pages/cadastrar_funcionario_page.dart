import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_layout.dart';
import '../models/funcionario_model.dart';
import '../providers/funcionario_provider.dart';

class CadastrarFuncionarioPage extends StatefulWidget {
  const CadastrarFuncionarioPage({super.key});

  @override
  State<CadastrarFuncionarioPage> createState() =>
      _CadastrarFuncionarioPageState();
}

class _CadastrarFuncionarioPageState extends State<CadastrarFuncionarioPage> {
  final _formKey = GlobalKey<FormState>();

  // ============================================================
  // 1️⃣ CONTROLLERS
  // ============================================================
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final cargoController = TextEditingController();
  final rgController = TextEditingController();
  final cpfController = TextEditingController();
  final matriculaController = TextEditingController();
  final empresaIdController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController(); // 🔥 NOVO

  // ============================================================
  // 2️⃣ VARIÁVEIS DE ESTADO
  // ============================================================
  DateTime? dataNascimento;
  DateTime? dataAdmissao;
  bool ativo = true;
  bool _isAdmin = false;
  bool _carregando = false;

  // ============================================================
  // 3️⃣ GETTERS
  // ============================================================
  String get _senhaPadrao {
    final iniciais = nomeController.text.isNotEmpty
        ? nomeController.text
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0].toLowerCase() : '')
            .join('')
        : 'func';
    final ano = DateTime.now().year;
    return '$iniciais@$ano';
  }

  // ============================================================
  // 4️⃣ VALIDADORES
  // ============================================================
  String? campoObrigatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe $campo';
    }
    return null;
  }

  // 🔥 NOVO: Validador de matrícula (não pode repetir)
  String? _validarMatricula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe a matrícula';
    }
    final provider = context.read<FuncionarioProvider>();
    if (provider.matriculaExiste(value.trim())) {
      return '❌ Matrícula já cadastrada';
    }
    return null;
  }

  // 🔥 NOVO: Validador de confirmação de senha
  String? _validarConfirmarSenha(String? value) {
    final senha = senhaController.text.trim();
    
    // Se a senha está vazia, confirmar senha é opcional
    if (senha.isEmpty) {
      return null;
    }
    
    // Se a senha foi preenchida, a confirmação é obrigatória
    if (value == null || value.trim().isEmpty) {
      return 'Confirme a senha';
    }
    if (value.trim() != senha) {
      return 'As senhas não coincidem';
    }
    return null;
  }


  // ============================================================
  // 5️⃣ MÉTODOS DE DATA
  // ============================================================
  Future selecionarDataNascimento() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() => dataNascimento = data);
    }
  }

  Future selecionarDataAdmissao() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (data != null) {
      setState(() => dataAdmissao = data);
    }
  }

  String formatarData(DateTime? data) {
    if (data == null) return 'Selecionar';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  // ============================================================
  // 6️⃣ MÉTODO SALVAR
  // ============================================================
  Future<void> _salvarFuncionario() async {
    if (!_formKey.currentState!.validate()) return;

    if (dataNascimento == null || dataAdmissao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha a data de nascimento e a data de admissão.'),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final provider = context.read<FuncionarioProvider>();
    final email = emailController.text.trim();

    String senha = senhaController.text.trim();
    bool senhaGerada = false;

    if (senha.isEmpty) {
      senha = _senhaPadrao;
      senhaGerada = true;
    }

    setState(() => _carregando = true);

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final userId = userCredential.user?.uid ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final funcionario = Funcionario(
        id: userId,
        empresaId: empresaIdController.text,
        nome: nomeController.text,
        email: email,
        telefone: telefoneController.text,
        cargo: cargoController.text,
        matricula: matriculaController.text,
        rg: rgController.text,
        cpf: cpfController.text,
        dataNascimento: dataNascimento!,
        dataAdmissao: dataAdmissao!,
        ativo: ativo,
        fotoPath: null,
        dataExclusao: null,
        isAdmin: _isAdmin,
      );

      await FirebaseFirestore.instance
          .collection('funcionarios')
          .doc(userId)
          .set(funcionario.toFirestore());

      provider.adicionar(funcionario);

      if (mounted) {
        if (senhaGerada) {
          messenger.showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Funcionário cadastrado com sucesso!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('📧 Email: $email', style: const TextStyle(fontSize: 13)),
                  Text('🔑 Senha: $senha', style: const TextStyle(fontSize: 13)),
                  Text(
                    '👤 Perfil: ${_isAdmin ? "ADMIN" : "Funcionário"}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('✅ Funcionário cadastrado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        _limparFormulario();
        router.go('/funcionarios');
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao criar usuário: ';
      if (e.code == 'email-already-in-use') {
        mensagem = '❌ Este email já está em uso.';
      } else if (e.code == 'invalid-email') {
        mensagem = '❌ Email inválido.';
      } else if (e.code == 'weak-password') {
        mensagem = '❌ A senha deve ter pelo menos 6 caracteres.';
      } else {
        mensagem += e.message ?? e.code;
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao cadastrar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _limparFormulario() {
    nomeController.clear();
    emailController.clear();
    telefoneController.clear();
    cargoController.clear();
    rgController.clear();
    cpfController.clear();
    matriculaController.clear();
    empresaIdController.clear();
    senhaController.clear();
    confirmarSenhaController.clear(); // 🔥 NOVO
    setState(() {
      dataNascimento = null;
      dataAdmissao = null;
      ativo = true;
      _isAdmin = false;
    });
  }

  // ============================================================
  // 7️⃣ BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      titulo: 'Cadastrar Funcionário',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'Dados do Funcionário',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• Email e senha serão usados para login.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                Text(
                                  '• Se não preencher a senha, será gerada automaticamente.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // LINHA 1: Nome + Email
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                campoObrigatorio(value, 'o nome'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email (login)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o email';
                              }
                              if (!value.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LINHA 2: Senha + Confirmar Senha
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: senhaController,
                            decoration: InputDecoration(
                              labelText: 'Senha (opcional)',
                              hintText: 'Deixe em branco para gerar',
                              border: const OutlineInputBorder(),
                              helperText: 'Mínimo 6 caracteres',
                              helperMaxLines: 2,
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value != null &&
                                  value.trim().isNotEmpty &&
                                  value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: confirmarSenhaController, // 🔥 NOVO
                            decoration: const InputDecoration(
                              labelText: 'Confirmar Senha',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: _validarConfirmarSenha, // 🔥 NOVO
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LINHA 3: Telefone + Cargo
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: telefoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                campoObrigatorio(value, 'o telefone'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: cargoController,
                            decoration: const InputDecoration(
                              labelText: 'Cargo',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                campoObrigatorio(value, 'o cargo'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LINHA 4: Matrícula + RG
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: matriculaController,
                            decoration: const InputDecoration(
                              labelText: 'Matrícula',
                              border: OutlineInputBorder(),
                            ),
                            validator: _validarMatricula, // 🔥 NOVO
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: rgController,
                            decoration: const InputDecoration(
                              labelText: 'RG',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                campoObrigatorio(value, 'o RG'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LINHA 5: CPF + Empresa ID
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cpfController,
                            decoration: const InputDecoration(
                              labelText: 'CPF',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                campoObrigatorio(value, 'o CPF'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: empresaIdController,
                            decoration: const InputDecoration(
                              labelText: 'Empresa ID',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                campoObrigatorio(value, 'o ID da empresa'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // DATAS
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: selecionarDataNascimento,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data de Nascimento',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(formatarData(dataNascimento)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: selecionarDataAdmissao,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data de Admissão',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(formatarData(dataAdmissao)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // SWITCH PARA ADMIN
                    SwitchListTile(
                      title: const Text(
                        'Usuário Admin',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _isAdmin
                            ? 'Acesso total ao sistema (Dashboard)'
                            : 'Acesso de funcionário (App mobile)',
                        style: TextStyle(
                          color: _isAdmin
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                      value: _isAdmin,
                      onChanged: (value) {
                        setState(() {
                          _isAdmin = value;
                        });
                      },
                      secondary: Icon(
                        _isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: _isAdmin ? Colors.blue : Colors.grey,
                      ),
                      tileColor: _isAdmin
                          ? Colors.blue.shade50
                          : Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text(
                        'Funcionário Ativo',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(ativo ? 'Ativo' : 'Inativo'),
                      value: ativo,
                      onChanged: (value) {
                        setState(() {
                          ativo = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // BOTÃO SALVAR
                    SizedBox(
                      height: 50,
                      child: _carregando
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _salvarFuncionario,
                              icon: const Icon(Icons.save),
                              label: const Text('Cadastrar Funcionário'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 8️⃣ DISPOSE
  // ============================================================
  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose(); // 🔥 NOVO
    telefoneController.dispose();
    cargoController.dispose();
    rgController.dispose();
    cpfController.dispose();
    matriculaController.dispose();
    empresaIdController.dispose();
    super.dispose();
  }
}