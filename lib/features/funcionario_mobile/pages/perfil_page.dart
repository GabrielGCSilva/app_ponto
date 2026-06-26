import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../funcionario/providers/funcionario_provider.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  // 🔥 CORRIGIDO: Implementação do método alterar senha
  Future<void> _alterarSenha() async {
    final messenger = ScaffoldMessenger.of(context);
    final currentContext = context;
    
    // 🔥 Dialog para nova senha
    final novaSenha = await _mostrarDialogNovaSenha(currentContext);
    if (novaSenha == null || novaSenha.isEmpty) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }
      
      await user.updatePassword(novaSenha);
      
      if (currentContext.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Senha alterada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (currentContext.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _mostrarDialogNovaSenha(BuildContext context) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == confirmController.text) {
                Navigator.pop(dialogContext, controller.text);
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('❌ As senhas não coincidem'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final funcionarioProvider = context.watch<FuncionarioProvider>();
    final funcionario = funcionarioProvider.buscarPorId(currentUser?.uid ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                funcionario?.nome.isNotEmpty == true
                    ? funcionario!.nome[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              funcionario?.nome ?? 'Usuário',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              funcionario?.email ?? 'Email não disponível',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: (funcionario?.isAdmin ?? false)
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (funcionario?.isAdmin ?? false)
                      ? Colors.blue.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Text(
                (funcionario?.isAdmin ?? false) ? 'ADMIN' : 'FUNCIONÁRIO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: (funcionario?.isAdmin ?? false)
                      ? Colors.blue.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Informações adicionais
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.badge_outlined,
                      'Matrícula',
                      funcionario?.matricula ?? 'N/A',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.work_outline,
                      'Cargo',
                      funcionario?.cargo ?? 'N/A',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      Icons.business_outlined,
                      'Empresa',
                      funcionario?.empresaId ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // 🔥 CORRIGIDO: Implementado o método alterar senha
                onPressed: _alterarSenha,
                icon: const Icon(Icons.lock_outline),
                label: const Text('Alterar Senha'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}