import 'package:flutter/material.dart';

class FuncionariosPage extends StatelessWidget {
  const FuncionariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
      ),

      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Gabriel Gimenez'),
            subtitle: Text('Administrador'),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('João Silva'),
            subtitle: Text('Colaborador'),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Futuramente abrirá tela de cadastro
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}