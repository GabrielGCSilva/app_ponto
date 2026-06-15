import 'package:flutter/material.dart';

import 'package:app_ponto/shared/widgets/app_layout.dart';

class FuncionariosPage extends StatelessWidget {
  const FuncionariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      titulo: 'Funcionários',

      body: Column(
        children: [

          // Botão de Novo Funcionário
          Padding(
            padding: const EdgeInsets.all(16),

            child: Align(
              alignment: Alignment.centerRight,

              child: ElevatedButton.icon(
                onPressed: () {
                  // Futuramente abrirá tela de cadastro
                },

                icon: const Icon(Icons.add),

                label: const Text('Novo Funcionário'),
              ),
            ),
          ),

          // Lista de funcionários
          Expanded(
            child: ListView(
              children: const [

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Gabriel Gimenez'),
                  subtitle: Text('Administrador'),
                ),

                Divider(),

                ListTile(
                  leading: Icon(Icons.person),
                  title: Text('João Silva'),
                  subtitle: Text('Colaborador'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
