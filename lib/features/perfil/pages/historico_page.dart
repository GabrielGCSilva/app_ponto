import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/historico_provider.dart';
import '../widgets/historico_mensal_widget.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarHistorico();
    });
  }

  Future<void> _carregarHistorico() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await context.read<HistoricoProvider>().carregarHistorico(currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historicoProvider = context.watch<HistoricoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Histórico de Pontos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarHistorico,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: historicoProvider.carregando
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
    );
  }
}