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
  String? _enderecoAtual;
  bool _localizacaoDisponivel = false;
  bool _isOnline = false;
  bool _permicaoNegada = false;
  bool _buscando = false;

  bool _cardExpandido = false;
  late AnimationController _animationController;

  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final AuthService _authService = AuthService();

  TipoPonto? _tipoSelecionado;
  bool _registrando = false;

  // 🔥 CENTRO PADRÃO (SÃO PAULO) - FIXO
  static const LatLng _centroPadrao = LatLng(-23.5505, -46.6333);

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
    _isOnline = await _verificarInternet();

    if (_isOnline) {
      await _obterLocalizacaoCompleta();
    } else {
      setState(() {
        _enderecoAtual = '📍 Modo offline - Conecte-se para ver o mapa';
        _localizacaoDisponivel = false;
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

  // 🔥 OBTER LOCALIZAÇÃO COMPLETA
  Future<void> _obterLocalizacaoCompleta() async {
    if (_buscando) {
      debugPrint('⚠️ [HOME] Já está buscando localização');
      return;
    }

    try {
      _buscando = true;

      // 🔥 PASSO 1: Verificar permissão
      final disponivel = await _localizacaoService.isLocationAvailable();

      if (!disponivel) {
        setState(() {
          _permicaoNegada = true;
          _enderecoAtual = '📍 Permissão de localização negada';
          _localizacaoDisponivel = false;
          _buscando = false;
        });
        return;
      }

      setState(() {
        _permicaoNegada = false;
      });

      // 🔥 PASSO 2: Última posição conhecida (INSTANTÂNEO)
      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        debugPrint('📍 [HOME] Última posição: ${lastPosition.latitude}, ${lastPosition.longitude}');
        _atualizarMapa(lastPosition);
      }

      // 🔥 PASSO 3: Stream de posição (mais suave que getCurrentPosition)
      _escutarStreamPosicao();

    } catch (e) {
      debugPrint('❌ [HOME] Erro ao obter localização: $e');
      setState(() {
        _enderecoAtual = 'Erro ao obter localização';
        _localizacaoDisponivel = false;
        _buscando = false;
      });
    }
  }

  // 🔥 ESCUTAR STREAM DE POSIÇÃO (EM TEMPO REAL)
  Future<void> _escutarStreamPosicao() async {
    try {
      // 🔥 Verificar se o GPS está disponível
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [HOME] GPS desativado');
        setState(() {
          _enderecoAtual = '📍 Ative o GPS para obter localização';
          _localizacaoDisponivel = false;
          _buscando = false;
        });
        return;
      }

      // 🔥 Criar stream com timeout
      final stream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10, // Atualiza a cada 10 metros
        ),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: (sink) => sink.close(),
      );

      bool primeiraPosicao = true;

      // 🔥 Escutar a stream
      await for (final position in stream) {
        if (!mounted) break;

        debugPrint('📍 [HOME] Stream posição: ${position.latitude}, ${position.longitude}');

        if (primeiraPosicao) {
          primeiraPosicao = false;
          _buscando = false;
        }

        _atualizarMapa(position);

        // 🔥 Buscar endereço (apenas na primeira vez)
        if (_enderecoAtual == null || _enderecoAtual!.contains('Buscando') || _enderecoAtual!.contains('Localização')) {
          _buscarEnderecoEmBackground(position);
        }

        // 🔥 Sair do loop após receber a primeira posição boa
        if (_localizacaoDisponivel && position.accuracy < 100) {
          break;
        }
      }

      // 🔥 Se saiu do loop sem posição, tentar fallback
      if (!_localizacaoDisponivel && mounted) {
        _buscando = false;
        _enderecoAtual = 'Não foi possível obter localização';
        setState(() {});
      }

    } catch (e) {
      debugPrint('⚠️ [HOME] Erro na stream: $e');
      
      // 🔥 FALLBACK: tentar getCurrentPosition
      if (mounted) {
        _buscando = false;
        await _buscarPosicaoAtualFallback();
      }
    }
  }

  // 🔥 FALLBACK: BUSCAR POSIÇÃO ATUAL
  Future<void> _buscarPosicaoAtualFallback() async {
    try {
      debugPrint('🔄 [HOME] Fallback: getCurrentPosition');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      if (mounted) {
        _atualizarMapa(position);
        _buscarEnderecoEmBackground(position);
      }
    } catch (e) {
      debugPrint('⚠️ [HOME] Fallback falhou: $e');
      if (mounted) {
        setState(() {
          _enderecoAtual = 'Não foi possível obter localização';
          _localizacaoDisponivel = false;
          _buscando = false;
        });
      }
    }
  }

  // 🔥 ATUALIZAR MAPA COM NOVA POSIÇÃO
  void _atualizarMapa(Position position) {
    if (!mounted) return;

    setState(() {
      _localizacaoAtual = position;
      _localizacaoDisponivel = true;
    });

    // 🔥 Mover o mapa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16,
        );
      }
    });
  }

  // 🔥 BUSCAR ENDEREÇO EM BACKGROUND
  Future<void> _buscarEnderecoEmBackground(Position position) async {
    try {
      final endereco = await _localizacaoService.getEnderecoCompleto(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _enderecoAtual = endereco;
        });
        debugPrint('📍 [HOME] Endereço obtido: $endereco');
      }
    } catch (e) {
      debugPrint('⚠️ [HOME] Erro ao buscar endereço: $e');
      if (mounted) {
        setState(() {
          _enderecoAtual = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    }
  }

  // 🔥 SOLICITAR PERMISSÃO NOVAMENTE
  Future<void> _solicitarPermissaoNovamente() async {
    final disponivel = await _localizacaoService.isLocationAvailable();

    if (disponivel) {
      _buscando = false;
      await _obterLocalizacaoCompleta();
    } else {
      setState(() {
        _permicaoNegada = true;
        _enderecoAtual = '📍 Permissão de localização negada';
        _localizacaoDisponivel = false;
      });
    }
  }

  Future<void> _refreshLocalizacao() async {
    debugPrint('🔄 [HOME] Refresh manual');
    _isOnline = await _verificarInternet();

    if (_isOnline) {
      _buscando = false;
      await _obterLocalizacaoCompleta();
    } else {
      setState(() {
        _localizacaoDisponivel = false;
        _enderecoAtual = '📍 Modo offline';
      });
    }
  }

  Future<void> _carregarDadosUsuario() async {
    final usuario = await _authService.getUsuarioSalvo();
    debugPrint('🔍 [HOME] Dados do usuário: $usuario');
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
          // 🔥 MAPA - ÚNICO, NUNCA É DESTRUÍDO
          Positioned.fill(
            child: _permicaoNegada
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 60,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '📍 Permissão de Localização',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'O app precisa acessar sua localização para registrar os pontos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _solicitarPermissaoNovamente,
                          icon: const Icon(Icons.gps_fixed),
                          label: const Text('Conceder Permissão'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centroPadrao, // 🔥 FIXO
                      initialZoom: 14,
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
                      // 🔥 MARCADOR DINÂMICO
                      MarkerLayer(
                        markers: [
                          if (_localizacaoDisponivel && _localizacaoAtual != null)
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
                          if (!_localizacaoDisponivel && _isOnline)
                            Marker(
                              width: 40,
                              height: 40,
                              point: _centroPadrao,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          // 🔥 OVERLAY DE CARREGAMENTO (LEVE)
          if (_isOnline && !_localizacaoDisponivel && !_permicaoNegada && _buscando)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Buscando localização...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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