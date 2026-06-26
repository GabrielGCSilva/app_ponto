import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/biometric_auth_service.dart';
import '../../ponto/providers/ponto_provider.dart';
import '../../ponto/models/registro_ponto_model.dart';

class MetodoAutenticacaoPage extends StatefulWidget {
  final TipoPonto tipoPonto;
  final String funcionarioId;
  final String funcionarioNome;

  const MetodoAutenticacaoPage({
    super.key,
    required this.tipoPonto,
    required this.funcionarioId,
    required this.funcionarioNome,
  });

  @override
  State<MetodoAutenticacaoPage> createState() => _MetodoAutenticacaoPageState();
}

class _MetodoAutenticacaoPageState extends State<MetodoAutenticacaoPage> {
  final BiometricAuthService _authService = BiometricAuthService();
  bool _carregando = false;
  List<MetodoAutenticacao> _metodosDisponiveis = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verificarMetodosDisponiveis();
  }

  Future<void> _verificarMetodosDisponiveis() async {
    final metodos = <MetodoAutenticacao>[];

    try {
      final hasBio = await _authService.isBiometricSupported();
      if (hasBio) {
        final biometrics = await _authService.getAvailableBiometrics();
        for (var bio in biometrics) {
          final bioStr = bio.toString();
          if (bioStr.contains('fingerprint') || bioStr.contains('Fingerprint')) {
            metodos.add(MetodoAutenticacao.digital);
          } else if (bioStr.contains('face') || bioStr.contains('Face')) {
            metodos.add(MetodoAutenticacao.facial);
          }
        }
      }

      final hasPassword = await _authService.hasDevicePassword();
      if (hasPassword) {
        metodos.add(MetodoAutenticacao.senha);
      }

      setState(() {
        _metodosDisponiveis = metodos;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao verificar métodos disponíveis: $e';
      });
    }
  }

  Future<void> _autenticar(MetodoAutenticacao metodo) async {
    setState(() {
      _carregando = true;
      _errorMessage = null;
    });

    String metodoStr;
    String motivo;

    switch (metodo) {
      case MetodoAutenticacao.senha:
        metodoStr = 'Senha';
        motivo = 'Digite a senha do dispositivo para confirmar o ponto';
        break;
      case MetodoAutenticacao.digital:
        metodoStr = 'Digital';
        motivo = 'Coloque o dedo no sensor para confirmar o ponto';
        break;
      case MetodoAutenticacao.facial:
        metodoStr = 'Facial';
        motivo = 'Olhe para a câmera para confirmar o ponto';
        break;
    }

    try {
      final result = await _authService.authenticate(
        metodo: metodoStr,
        motivo: motivo,
      );

      if (result.success) {
        await _registrarPonto(metodoStr);
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Autenticação falhou';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _registrarPonto(String metodo) async {
    final provider = context.read<PontoProvider>();

    try {
      await provider.registrarPonto(
        funcionarioId: widget.funcionarioId,
        funcionarioNome: widget.funcionarioNome,
        tipo: widget.tipoPonto,
        metodoAutenticacao: 'Biometria ($metodo)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${widget.tipoPonto.label} registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao registrar ponto: $e';
      });
    }
  }

  // 🔥 CORRIGIDO: Implementação do método para abrir configurações
  void _abrirConfiguracoesBiometria() {
    // 🔥 Usar url_launcher para abrir configurações de segurança
    // Import: import 'package:url_launcher/url_launcher.dart';
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configure a biometria nas configurações do seu dispositivo.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    
    // 🔥 Se quiser abrir as configurações do dispositivo:
    // launchUrl(Uri.parse('app-settings:'));
  }

  void _voltarSelecionarMetodo() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔐 Autenticação'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha o método de autenticação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione como deseja confirmar sua identidade',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.tipoPonto.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.tipoPonto.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.tipoPonto.icon,
                    color: widget.tipoPonto.color,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registrando:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          widget.tipoPonto.label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.tipoPonto.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.funcionarioNome,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            if (_metodosDisponiveis.isEmpty && !_carregando)
              _buildMetodosIndisponiveis()
            else
              Expanded(
                child: Column(
                  children: [
                    ..._metodosDisponiveis.map((metodo) => _buildMetodoButton(metodo)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _voltarSelecionarMetodo,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar e escolher outro tipo de ponto'),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoButton(MetodoAutenticacao metodo) {
    IconData icon;
    String label;
    String descricao;
    Color cor;

    switch (metodo) {
      case MetodoAutenticacao.senha:
        icon = Icons.lock_outline;
        label = 'Senha';
        descricao = 'Autenticar com a senha do dispositivo';
        cor = Colors.blue;
        break;
      case MetodoAutenticacao.digital:
        icon = Icons.fingerprint;
        label = 'Digital';
        descricao = 'Autenticar com a impressão digital';
        cor = Colors.green;
        break;
      case MetodoAutenticacao.facial:
        icon = Icons.face;
        label = 'Facial';
        descricao = 'Autenticar com o reconhecimento facial';
        cor = Colors.purple;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _carregando ? null : () => _autenticar(metodo),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                    ),
                    Text(
                      descricao,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_carregando)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetodosIndisponiveis() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.security,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        const Text(
          'Nenhum método de autenticação disponível',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure uma senha ou biometria nas configurações do dispositivo.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _voltarSelecionarMetodo,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar outro método'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _abrirConfiguracoesBiometria,
              icon: const Icon(Icons.settings),
              label: const Text('Configurar autenticação'),
            ),
          ],
        ),
      ],
    );
  }
}

enum MetodoAutenticacao {
  senha,
  digital,
  facial,
}