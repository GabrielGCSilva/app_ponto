import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/app_layout.dart';
import '../models/funcionario_model.dart';
import '../providers/funcionario_provider.dart';

class CadastrarFuncionarioPage extends StatefulWidget {
  const CadastrarFuncionarioPage({super.key});

  @override
  State<CadastrarFuncionarioPage> createState() =>
      _CadastrarFuncionarioPageState();
}

class _CadastrarFuncionarioPageState
    extends State<CadastrarFuncionarioPage> {

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();
  final cargoController = TextEditingController();
  final rgController = TextEditingController();
  final cpfController = TextEditingController();
  final matriculaController = TextEditingController();
  final empresaIdController = TextEditingController();

  // Datas
  DateTime? dataNascimento;
  DateTime? dataAdmissao;

  // Status
  bool ativo = true;

  // Foto
  String? _fotoPath;
  final ImagePicker _imagePicker = ImagePicker();

  String? campoObrigatorio(
    String? valor,
    String campo,
  ) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe $campo';
    }
    return null;
  }

  Future<void> _selecionarFoto() async {
    final XFile? imagem = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 80,
    );
    if (imagem != null) {
      setState(() => _fotoPath = imagem.path);
    }
  }

  Future<void> _tirarFoto() async {
    final XFile? imagem = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 80,
    );
    if (imagem != null) {
      setState(() => _fotoPath = imagem.path);
    }
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adicionar Foto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOpcaoFoto(
                    icon: Icons.photo_library,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarFoto();
                    },
                  ),
                  _buildOpcaoFoto(
                    icon: Icons.camera_alt,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      _tirarFoto();
                    },
                  ),
                  _buildOpcaoFoto(
                    icon: Icons.delete_outline,
                    label: 'Remover',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _fotoPath = null);
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcaoFoto({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color ?? Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color ?? Colors.blue)),
          ],
        ),
      ),
    );
  }

  Future selecionarDataNascimento() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (data != null) {
      setState(() {
        dataNascimento = data;
      });
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
      setState(() {
        dataAdmissao = data;
      });
    }
  }

  String formatarData(DateTime? data) {
    if (data == null) {
      return 'Selecionar';
    }

    return
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  Widget _buildFotoCadastro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto de Perfil',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _mostrarOpcoesFoto,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(
                color: Colors.blue.shade300,
                width: 2,
              ),
            ),
            child: _fotoPath != null && _fotoPath!.isNotEmpty
                ? ClipOval(
                    child: Image.file(
                      File(_fotoPath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.blue.shade300,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicionar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade300,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toque para adicionar/alterar foto',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // 🔥 MÉTODO PARA SALVAR COM CONTROLE DE ESTADO
  Future<void> _salvarFuncionario() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (dataNascimento == null || dataAdmissao == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preencha a data de nascimento e a data de admissão.',
        ),
      ),
    );
    return;
  }

  // 🔥 Guardar referências
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final provider = context.read<FuncionarioProvider>();

  // 🔥 Mostrar loading
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final funcionario = Funcionario(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      empresaId: empresaIdController.text,
      nome: nomeController.text,
      email: emailController.text,
      telefone: telefoneController.text,
      cargo: cargoController.text,
      matricula: matriculaController.text,
      rg: rgController.text,
      cpf: cpfController.text,
      dataNascimento: dataNascimento!,
      dataAdmissao: dataAdmissao!,
      ativo: ativo,
      fotoPath: _fotoPath,
    );

    debugPrint('📝 Salvando funcionário: ${funcionario.nome}');
    
    await provider.adicionar(funcionario);

    // 🔥 Fechar loading se o widget ainda estiver montado
    if (mounted) {
      Navigator.pop(context);
      
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Funcionário cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      router.go('/funcionarios');
    }
  } catch (e) {
    debugPrint('❌ Erro no cadastro: $e');
    
    // 🔥 Fechar loading em caso de erro
    if (mounted) {
      Navigator.pop(context);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      titulo: 'Cadastrar Funcionário',

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),

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

                    const SizedBox(height: 24),

                    // FOTO DE PERFIL
                    _buildFotoCadastro(),
                    
                    const SizedBox(height: 24),

                    // LINHA 1
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
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                campoObrigatorio(value, 'o email'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LINHA 2
                    Row(
                      children: [

                        Expanded(
                          child: TextFormField(
                            controller: telefoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone',
                              border: OutlineInputBorder(),
                            ),
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

                    // LINHA 3
                    Row(
                      children: [

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

                        const SizedBox(width: 16),

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
                      ],
                    ),

                    const SizedBox(height: 16),

                    // LINHA 4
                    Row(
                      children: [

                        Expanded(
                          child: TextFormField(
                            controller: matriculaController,
                            decoration: const InputDecoration(
                              labelText: 'Matrícula',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                campoObrigatorio(value, 'a matrícula'),
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

                              child: Text(
                                formatarData(dataNascimento),
                              ),
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

                              child: Text(
                                formatarData(dataAdmissao),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SwitchListTile(
                      title: const Text(
                        'Funcionário Ativo',
                      ),

                      subtitle: Text(
                        ativo
                            ? 'Ativo'
                            : 'Inativo',
                      ),

                      value: ativo,

                      onChanged: (value) {
                        setState(() {
                          ativo = value;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,

                      child: ElevatedButton.icon(
                        onPressed: _salvarFuncionario, // 🔥 Chamando o método
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Salvar Funcionário',
                        ),
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
}