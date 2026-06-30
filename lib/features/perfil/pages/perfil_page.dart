import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../funcionario/providers/funcionario_provider.dart';
import '../providers/historico_provider.dart';
import '../widgets/historico_mensal_widget.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await context.read<HistoricoProvider>().carregarHistorico(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final funcionarioProvider = context.watch<FuncionarioProvider>();
    final historicoProvider = context.watch<HistoricoProvider>();
    final funcionario = funcionarioProvider.buscarPorId(currentUser?.uid ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarHistorico,
            tooltip: 'Atualizar histórico',
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 CABEÇALHO DO PERFIL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    funcionario?.nome.isNotEmpty == true
                        ? funcionario!.nome[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  funcionario?.nome ?? 'Usuário',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  funcionario?.email ?? 'Email não disponível',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (funcionario?.isAdmin ?? false) ? 'ADMIN' : 'FUNCIONÁRIO',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 🔥 HISTÓRICO DE PONTOS
          Expanded(
            child: historicoProvider.carregando
                ? const Center(child: CircularProgressIndicator())
                : historicoProvider.erro != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              historicoProvider.erro!,
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _carregarHistorico,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : historicoProvider.historico.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Nenhum registro de ponto encontrado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Bata seu primeiro ponto para começar!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: historicoProvider.historico.length,
                            itemBuilder: (context, index) {
                              final mes = historicoProvider.historico[index];
                              return HistoricoMensalWidget(mes: mes);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}