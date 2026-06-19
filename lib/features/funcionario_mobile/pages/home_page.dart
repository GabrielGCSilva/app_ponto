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

class _HomePageState extends State<HomePage> {
  late MapController _mapController;
  LocationData? _localizacaoAtual;
  bool _carregando = true;
  String? _enderecoAtual;
  
  final LocalizacaoService _localizacaoService = LocalizacaoService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  Future<void> _obterLocalizacao() async {
    setState(() => _carregando = true);
    
    try {
      final location = await _localizacaoService.getLocalizacaoAtual();
      if (location != null) {
        setState(() {
          _localizacaoAtual = location;
        });
        
        final endereco = await _localizacaoService.getEnderecoCompleto(
          location.latitude ?? 0,
          location.longitude ?? 0,
        );
        setState(() {
          _enderecoAtual = endereco;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao obter localização: $e');
    } finally {
      setState(() => _carregando = false);
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
      body: Column(
        children: [
          // 🔥 Mapa (OpenStreetMap)
          Expanded(
            flex: 2,
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _localizacaoAtual == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Localização não disponível'),
                            SizedBox(height: 8),
                            Text(
                              'Ative o GPS e tente novamente',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : FlutterMap(
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
                          // 🔥 Camada do Mapa (OpenStreetMap)
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.seu.app_ponto',
                          ),
                          
                          // 🔥 Marcador da Localização
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
                      ),
          ),

          // 🔥 Informações e Botão Bater Ponto
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                // 🔥 Endereço atual
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _enderecoAtual ?? 'Buscando localização...',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _obterLocalizacao,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔥 Botão Bater Ponto
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _localizacaoAtual == null
                        ? null
                        : _mostrarOpcoesPonto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text(
                      'BATER PONTO',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Toque para registrar seu ponto',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Mostrar opções de ponto
  void _mostrarOpcoesPonto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildBottomSheet(),
    );
  }

  Widget _buildBottomSheet() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecione o tipo de registro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildOpcaoPonto(
                  tipo: 'Entrada',
                  icon: Icons.login,
                  cor: Colors.green,
                  onTap: () => _registrarPonto(TipoPonto.entrada),
                ),
                _buildOpcaoPonto(
                  tipo: 'Saída',
                  icon: Icons.logout,
                  cor: Colors.red,
                  onTap: () => _registrarPonto(TipoPonto.saida),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildOpcaoPonto(
                  tipo: 'Saída Almoço',
                  icon: Icons.restaurant,
                  cor: Colors.orange,
                  onTap: () => _registrarPonto(TipoPonto.saidaAlmoco),
                ),
                _buildOpcaoPonto(
                  tipo: 'Retorno Almoço',
                  icon: Icons.restaurant,
                  cor: Colors.blue,
                  onTap: () => _registrarPonto(TipoPonto.retornoAlmoco),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoPonto({
    required String tipo,
    required IconData icon,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: cor, size: 28),
                const SizedBox(height: 4),
                Text(
                  tipo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 Registrar ponto
  Future<void> _registrarPonto(TipoPonto tipo) async {
  // 🔥 Guardar referências ANTES do async
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final provider = context.read<PontoProvider>();
  final usuario = await _authService.getUsuarioSalvo();

  // 🔥 Usar navigator em vez de context
  navigator.pop();

  if (_localizacaoAtual == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Localização indisponível'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  try {
    await provider.registrarPonto(
      funcionarioId: usuario?['id'] ?? '',
      funcionarioNome: usuario?['nome'] ?? 'Funcionário',
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
    }
  } catch (e) {
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // Confirmar logout
  void _confirmarLogout() {
  final navigator = Navigator.of(context);

  showDialog(
    context: context,
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
            await _authService.logout();
            if (mounted) {
              navigator.pushReplacementNamed('/login');
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