import 'package:flutter/material.dart';
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

  String? campoObrigatorio(
    String? valor,
    String campo,
  ) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe $campo';
    }

    return null;
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
                        onPressed: () {

                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          if (dataNascimento == null ||
                              dataAdmissao == null) {

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Preencha a data de nascimento e a data de admissão.',
                                ),
                              ),
                            );

                            return;
                          }

                          final funcionario = Funcionario(
                            id: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),

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
                          );

                          context
                              .read<FuncionarioProvider>()
                              .adicionar(funcionario);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Funcionário cadastrado com sucesso!',
                              ),
                            ),
                          );

                          context.go('/funcionarios');
                        },

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