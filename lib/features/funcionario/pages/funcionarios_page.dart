import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_layout.dart';
import '../providers/funcionario_provider.dart';

// 🔥 ENUM PARA FILTRO
enum FiltroFuncionario { todos, ativos, inativos }

class FuncionariosPage extends StatefulWidget {
  const FuncionariosPage({super.key});

  @override
  State<FuncionariosPage> createState() => _FuncionariosPageState();
}

class _FuncionariosPageState extends State<FuncionariosPage> {
  FiltroFuncionario _filtroAtual = FiltroFuncionario.ativos;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FuncionarioProvider>();

    // 🔥 Filtrar funcionários
    List<dynamic> funcionariosFiltrados;
    switch (_filtroAtual) {
      case FiltroFuncionario.ativos:
        funcionariosFiltrados = provider.funcionariosAtivos;
        break;
      case FiltroFuncionario.inativos:
        funcionariosFiltrados = provider.funcionariosInativos;
        break;
      case FiltroFuncionario.todos:
        funcionariosFiltrados = provider.funcionarios;
        break;
    }

    return AppLayout(
      titulo: 'Funcionários',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CABEÇALHO
            SizedBox(
              height: 60,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Funcionários (${funcionariosFiltrados.length})',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 180,
                      child: ElevatedButton.icon(
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

            const Divider(height: 20),

            // 🔥 FILTRO DE STATUS
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Text(
                    'Filtrar:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<FiltroFuncionario>(
                      segments: const [
                        ButtonSegment(
                          value: FiltroFuncionario.ativos,
                          label: Text('Ativos'),
                          icon: Icon(Icons.check_circle, size: 16),
                        ),
                        ButtonSegment(
                          value: FiltroFuncionario.inativos,
                          label: Text('Inativos'),
                          icon: Icon(Icons.block, size: 16),
                        ),
                        ButtonSegment(
                          value: FiltroFuncionario.todos,
                          label: Text('Todos'),
                          icon: Icon(Icons.people, size: 16),
                        ),
                      ],
                      selected: {_filtroAtual},
                      onSelectionChanged: (Set<FiltroFuncionario> selection) {
                        setState(() {
                          _filtroAtual = selection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 10),

            Expanded(
              child: funcionariosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _filtroAtual == FiltroFuncionario.inativos
                                ? Icons.block
                                : Icons.people_outline,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filtroAtual == FiltroFuncionario.inativos
                                ? 'Nenhum funcionário inativo.'
                                : 'Nenhum funcionário cadastrado.',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filtroAtual == FiltroFuncionario.inativos
                                ? 'Funcionários desativados aparecem aqui.'
                                : 'Clique em "Novo" para começar',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: funcionariosFiltrados.length,
                      itemBuilder: (context, index) {
                        final f = funcionariosFiltrados[index];
                        return InkWell(
                          onTap: () {
                            context.push(
                              '/funcionario-detalhes/${f.id}',
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: _buildFuncionarioCard(f),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuncionarioCard(dynamic funcionario) {
    final isAtivo = funcionario.ativo;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isAtivo ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAtivo 
            ? BorderSide.none 
            : BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      color: isAtivo ? Colors.white : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: isAtivo 
                  ? Colors.blue.shade100 
                  : Colors.grey.shade300,
              child: Text(
                funcionario.nome.isNotEmpty 
                    ? funcionario.nome[0].toUpperCase() 
                    : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isAtivo 
                      ? Colors.blue.shade800 
                      : Colors.grey.shade600,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Informações principais
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    funcionario.nome,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isAtivo ? Colors.black : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 16,
                        color: isAtivo 
                            ? Colors.grey.shade600 
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        funcionario.cargo,
                        style: TextStyle(
                          color: isAtivo 
                              ? Colors.grey.shade700 
                              : Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: isAtivo 
                            ? Colors.grey.shade500 
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        funcionario.email,
                        style: TextStyle(
                          color: isAtivo 
                              ? Colors.grey.shade500 
                              : Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Status + Seta
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAtivo 
                        ? Colors.green.shade50 
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAtivo 
                          ? Colors.green.shade200 
                          : Colors.red.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAtivo 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAtivo ? 'Ativo' : 'Inativo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAtivo 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.chevron_right,
                  color: isAtivo 
                      ? Colors.grey.shade400 
                      : Colors.grey.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}