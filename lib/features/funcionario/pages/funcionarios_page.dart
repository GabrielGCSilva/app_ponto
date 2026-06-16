import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_layout.dart';
import '../providers/funcionario_provider.dart';

class FuncionariosPage extends StatelessWidget {
  const FuncionariosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuncionarioProvider>();

    return AppLayout(
      titulo: 'Funcionários',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABEÇALHO ULTRA SEGURO (Sem Row para evitar conflito de largura)
            SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Funcionários (${provider.funcionarios.length})',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 180, // FORÇAMOS UMA LARGURA FIXA
                      child: ElevatedButton.icon(
                        // O styleFrom abaixo ignora o erro do seu AppTheme
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(100, 45), 
                          maximumSize: const Size(180, 45),
                        ),
                        onPressed: () => context.go('/cadastrar-funcionario'),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 30),

            Expanded(
              child: provider.funcionarios.isEmpty
                  ? const Center(child: Text('Nenhum funcionário cadastrado.'))
                  : ListView.builder(
                      itemCount: provider.funcionarios.length,
                      itemBuilder: (context, index) {
                        final f = provider.funcionarios[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(f.nome.isNotEmpty ? f.nome[0] : '?')),
                            title: Text(f.nome),
                            subtitle: Text(f.cargo),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
