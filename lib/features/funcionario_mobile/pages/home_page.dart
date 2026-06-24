import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/localizacao_service.dart';
import '../../ponto/providers/ponto_provider.dart';
import '../../ponto/models/registro_ponto_model.dart';
import 'perfil_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  LocationData? _localizacaoAtual;
  bool _carregando = true;
  String? _enderecoAtual;
  bool _localizacaoDisponivel = false;

  // 🔥 Controle do card animado
  bool _cardExpandido = false;
  late AnimationController _animationController;
  // ❌ REMOVIDO: Animation<double> _animation;

  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final AuthService _authService = AuthService();

  // Estado para o registro de ponto
  TipoPonto? _tipoSelecionado;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _obterLocalizacao();

    // 🔥 Configurar animação
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // ❌ REMOVIDO: _animation = CurvedAnimation(...)
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _obterLocalizacao() async {
    setState(() => _carregando = true);

    try {
      final location = await _localizacaoService.getLocalizacaoAtual();
      if (location != null) {
        setState(() {
          _localizacaoAtual = location;
          _localizacaoDisponivel = true;
        });

        final endereco = await _localizacaoService.getEnderecoCompleto(
          location.latitude ?? 0,
          location.longitude ?? 0,
        );
        setState(() {
          _enderecoAtual = endereco;
        });
      } else {
        setState(() {
          _localizacaoDisponivel = false;
          _enderecoAtual = 'Localização não disponível (Desktop)';
        });
      }
    } catch (e) {
      debugPrint('⚠️ Localização não disponível: $e');
      setState(() {
        _localizacaoDisponivel = false;
        _enderecoAtual = 'Localização não disponível (Desktop)';
      });
    } finally {
      setState(() => _carregando = false);
    }
  }

  // 🔥 Alternar card
  void _toggleCard() {
    setState(() {
      _cardExpandido = !_cardExpandido;
      if (_cardExpandido) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        // Resetar seleção ao fechar
        _tipoSelecionado = null;
      }
    });
  }

  // 🔥 Registrar ponto
  Future<void> _registrarPonto(TipoPonto tipo) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<PontoProvider>(context, listen: false);

    setState(() {
      _tipoSelecionado = tipo;
      _registrando = true;
    });

    try {
      final usuario = await _authService.getUsuarioSalvo();

      if (usuario == null) {
        throw Exception('Usuário não encontrado. Faça login novamente.');
      }

      await provider.registrarPonto(
        funcionarioId: usuario['id'] ?? '',
        funcionarioNome: usuario['nome'] ?? 'Funcionário',
        tipo: tipo,
        metodoAutenticacao: 'Senha',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ ${tipo.label} registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Fechar card após registro
        _toggleCard();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content:
                Text('❌ Erro: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _registrando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📍 Meu Ponto'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmarLogout,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🔥 Mapa (fundo)
          Positioned.fill(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _localizacaoDisponivel && _localizacaoAtual != null
                    ? FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            _localizacaoAtual!.latitude ?? 0,
                            _localizacaoAtual!.longitude ?? 0,
                          ),
                          initialZoom: 16,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.seu.app_ponto',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: LatLng(
                                  _localizacaoAtual!.latitude ?? 0,
                                  _localizacaoAtual!.longitude ?? 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Colors.blue.withValues(alpha: 0.3),
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off,
                                size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Localização indisponível',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use o app no celular para GPS',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),

          // 🔥 Overlay escuro quando card está expandido
          if (_cardExpandido)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleCard,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),

          // 🔥 Card animado (sobe de baixo para cima)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _cardExpandido ? 0 : -400, // Esconde abaixo da tela
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🔥 Handle (indicador de arraste)
                  GestureDetector(
                    onTap: _toggleCard,
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 🔥 Título
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📝 Registrar Ponto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleCard,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  const SizedBox(height: 8),

                  // 🔥 Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Selecione o tipo de ponto que deseja registrar',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔥 Botões de opções
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildOpcaoPonto(
                            tipo: TipoPonto.entrada,
                            icon: Icons.login,
                            cor: Colors.green,
                            descricao: 'Entrada',
                          ),
                          _buildOpcaoPonto(
                            tipo: TipoPonto.saidaAlmoco,
                            icon: Icons.restaurant,
                            cor: Colors.orange,
                            descricao: 'Saída para Almoço',
                          ),
                          _buildOpcaoPonto(
                            tipo: TipoPonto.retornoAlmoco,
                            icon: Icons.restaurant,
                            cor: Colors.blue,
                            descricao: 'Retorno do Almoço',
                          ),
                          _buildOpcaoPonto(
                            tipo: TipoPonto.saida,
                            icon: Icons.logout,
                            cor: Colors.red,
                            descricao: 'Saída',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 Botão flutuante "BATER PONTO" (sempre visível)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _cardExpandido ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _toggleCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text(
                    'BATER PONTO',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),

          // 🔥 Informações de localização (mini)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _enderecoAtual ?? 'Buscando localização...',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _obterLocalizacao,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Widget de opção do card
  Widget _buildOpcaoPonto({
    required TipoPonto tipo,
    required IconData icon,
    required Color cor,
    required String descricao,
  }) {
    final isSelected = _tipoSelecionado == tipo;

    return InkWell(
      onTap: _registrando ? null : () => _registrarPonto(tipo),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? cor.withValues(alpha: 0.15)
              : cor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cor : cor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_registrando && isSelected)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Icon(icon, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              tipo.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: cor,
              ),
            ),
            Text(
              descricao,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarLogout() {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sair do App'),
      content: const Text('Deseja realmente sair?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            // 🔥 Fechar dialog ANTES do async
            Navigator.pop(dialogContext);
            
            try {
              await _authService.logout();
              
              // 🔥 Verificar se o widget ainda está montado
              if (mounted) {
                // 🔥 Usar pushReplacementNamed para evitar voltar
                navigator.pushReplacementNamed('/login');
              }
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('❌ Erro ao sair: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sair'),
        ),
      ],
    ),
  );
}
}