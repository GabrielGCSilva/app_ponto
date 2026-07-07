import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/localizacao_service.dart';
import '../../ponto/models/registro_ponto_model.dart';
import '../../perfil/pages/perfil_page.dart';
import 'metodo_autenticacao_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late MapController _mapController;
  Position? _localizacaoAtual;
  bool _carregando = true;
  bool _carregandoMapa = true;
  String? _enderecoAtual;
  bool _localizacaoDisponivel = false;
  bool _isOnline = false;

  bool _cardExpandido = false;
  late AnimationController _animationController;

  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final AuthService _authService = AuthService();

  TipoPonto? _tipoSelecionado;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _carregarDadosUsuario();
    _inicializar();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _inicializar() async {
    // 🔥 VERIFICA INTERNET
    _isOnline = await _verificarInternet();

    if (_isOnline) {
      // 🔥 ONLINE: CARREGA MAPA E LOCALIZAÇÃO
      await _carregarLocalizacao();
    } else {
      // 🔥 OFFLINE: MOSTRA TELA SIMPLES
      setState(() {
        _carregando = false;
        _carregandoMapa = false;
        _localizacaoDisponivel = false;
        _enderecoAtual = '📍 Modo offline';
      });
    }
  }

  Future<bool> _verificarInternet() async {
    try {
      await FirebaseFirestore.instance
          .collection('configuracoes')
          .doc('check')
          .get()
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      debugPrint('📡 [HOME] Sem internet: $e');
      return false;
    }
  }

  Future<void> _carregarLocalizacao() async {
    setState(() => _carregandoMapa = true);

    try {
      // 🔥 TIMEOUT DE 6 SEGUNDOS
      await Future.any([
        _obterLocalizacao(),
        Future.delayed(const Duration(seconds: 6), () {
          debugPrint('⚠️ [HOME] Timeout ao obter localização');
          if (mounted) {
            setState(() {
              _localizacaoDisponivel = false;
              _enderecoAtual = 'Timeout ao obter localização';
              _carregando = false;
              _carregandoMapa = false;
            });
          }
        }),
      ]);
    } catch (e) {
      debugPrint('❌ [HOME] Erro ao obter localização: $e');
      if (mounted) {
        setState(() {
          _localizacaoDisponivel = false;
          _enderecoAtual = 'Erro ao obter localização';
          _carregando = false;
          _carregandoMapa = false;
        });
      }
    }
  }

  Future<void> _obterLocalizacao() async {
    setState(() => _carregando = true);

    try {
      final position = await _localizacaoService.getLocalizacaoAtual();
      
      if (position != null) {
        setState(() {
          _localizacaoAtual = position;
          _localizacaoDisponivel = true;
        });

        final endereco = await _localizacaoService.getEnderecoCompleto(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _enderecoAtual = endereco;
        });
      } else {
        setState(() {
          _localizacaoDisponivel = false;
          _enderecoAtual = 'Localização não disponível';
        });
      }
    } catch (e) {
      debugPrint('⚠️ Localização não disponível: $e');
      setState(() {
        _localizacaoDisponivel = false;
        _enderecoAtual = 'Localização não disponível';
      });
    } finally {
      setState(() {
        _carregando = false;
        _carregandoMapa = false;
      });
    }
  }

  Future<void> _refreshLocalizacao() async {
    debugPrint('🔄 [HOME] Refresh manual da localização');
    _isOnline = await _verificarInternet();
    if (_isOnline) {
      await _carregarLocalizacao();
    } else {
      setState(() {
        _localizacaoDisponivel = false;
        _enderecoAtual = '📍 Modo offline';
      });
    }
  }

  Future<void> _carregarDadosUsuario() async {
    final usuario = await _authService.getUsuarioSalvo();
    debugPrint('🔍 [HOME] Dados do usuário carregados: $usuario');
  }

  void _toggleCard() {
    setState(() {
      _cardExpandido = !_cardExpandido;
      if (_cardExpandido) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _tipoSelecionado = null;
      }
    });
  }

  Future<void> _selecionarTipoPonto(TipoPonto tipo) async {
    _toggleCard();

    final messenger = ScaffoldMessenger.of(context);
    final currentContext = context;

    final usuario = await _authService.getUsuarioSalvo();

    if (usuario == null) {
      if (currentContext.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('❌ Usuário não encontrado. Faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (currentContext.mounted) {
      Navigator.push(
        currentContext,
        MaterialPageRoute(
          builder: (context) => MetodoAutenticacaoPage(
            tipoPonto: tipo,
            funcionarioId: usuario['id'] ?? '',
            funcionarioNome: usuario['nome'] ?? 'Funcionário',
          ),
        ),
      );
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
          Positioned.fill(
            child: _carregando || _carregandoMapa
                ? const Center(child: CircularProgressIndicator())
                : _isOnline && _localizacaoDisponivel && _localizacaoAtual != null
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _localizacaoAtual!.latitude,
                        _localizacaoAtual!.longitude,
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
                              _localizacaoAtual!.latitude,
                              _localizacaoAtual!.longitude,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withValues(alpha: 0.3),
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
                        Icon(
                          _isOnline ? Icons.location_off : Icons.wifi_off,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isOnline
                              ? (_enderecoAtual ?? 'Localização indisponível')
                              : '📴 Modo offline',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isOnline
                              ? 'Ative o GPS e tente novamente'
                              : 'Conecte-se à internet para ver o mapa',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _refreshLocalizacao,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_cardExpandido)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleCard,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _cardExpandido ? 0 : -400,
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
                  Icon(
                    _isOnline ? Icons.location_on : Icons.wifi_off,
                    color: _isOnline ? Colors.blue : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _enderecoAtual ?? 'Buscando localização...',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOnline ? Colors.black : Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _refreshLocalizacao,
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

  Widget _buildOpcaoPonto({
    required TipoPonto tipo,
    required IconData icon,
    required Color cor,
    required String descricao,
  }) {
    final isSelected = _tipoSelecionado == tipo;

    return GestureDetector(
      onTap: _registrando ? null : () => _selecionarTipoPonto(tipo),
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
                child: CircularProgressIndicator(strokeWidth: 2),
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
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarLogout() {
    final messenger = ScaffoldMessenger.of(context);
    final currentContext = context;

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
              Navigator.pop(dialogContext);

              try {
                await _authService.logout();

                if (currentContext.mounted) {
                  currentContext.go('/login');
                }
              } catch (e) {
                if (currentContext.mounted) {
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