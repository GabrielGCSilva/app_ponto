import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/funcionario_model.dart';
import '../providers/funcionario_provider.dart';

class FuncionarioDetalhesPage extends StatefulWidget {
  final String funcionarioId;

  const FuncionarioDetalhesPage({
    super.key,
    required this.funcionarioId,
  });

  @override
  State<FuncionarioDetalhesPage> createState() =>
      _FuncionarioDetalhesPageState();
}

class _FuncionarioDetalhesPageState extends State<FuncionarioDetalhesPage> {
  late Funcionario _funcionario;
  bool _isEditing = false;

  // Controllers para todos os campos
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cargoController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _rgController = TextEditingController();
  final _cpfController = TextEditingController();
  
  // Datas
  DateTime? _dataNascimento;
  DateTime? _dataAdmissao;
  
  // Status e Foto
  bool _ativo = true;
  String? _fotoPath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _carregarFuncionario();
  }

  void _carregarFuncionario() {
    final provider = context.read<FuncionarioProvider>();
    _funcionario = provider.buscarPorId(widget.funcionarioId)!;
    
    // Inicializar controllers com todos os dados
    _nomeController.text = _funcionario.nome;
    _emailController.text = _funcionario.email;
    _telefoneController.text = _funcionario.telefone;
    _cargoController.text = _funcionario.cargo;
    _matriculaController.text = _funcionario.matricula;
    _rgController.text = _funcionario.rg;
    _cpfController.text = _funcionario.cpf;
    _dataNascimento = _funcionario.dataNascimento;
    _dataAdmissao = _funcionario.dataAdmissao;
    _ativo = _funcionario.ativo;
    _fotoPath = _funcionario.fotoPath;
  }

  // ============ MÉTODOS DE FOTO ============
  Future<void> _selecionarFoto() async {
    final XFile? imagem = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 80,
    );

    if (imagem != null) {
      setState(() {
        _fotoPath = imagem.path;
      });
    }
  }

  Future<void> _tirarFoto() async {
    final XFile? imagem = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 80,
    );

    if (imagem != null) {
      setState(() {
        _fotoPath = imagem.path;
      });
    }
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adicionar Foto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOpcaoFoto(
                    icon: Icons.photo_library,
                    label: 'Galeria',
                    onTap: () {
                      Navigator.pop(context);
                      _selecionarFoto();
                    },
                  ),
                  _buildOpcaoFoto(
                    icon: Icons.camera_alt,
                    label: 'Câmera',
                    onTap: () {
                      Navigator.pop(context);
                      _tirarFoto();
                    },
                  ),
                  _buildOpcaoFoto(
                    icon: Icons.delete_outline,
                    label: 'Remover',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _fotoPath = null;
                      });
                    },
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcaoFoto({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color ?? Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color ?? Colors.blue)),
          ],
        ),
      ),
    );
  }

  // ============ MÉTODOS DE EXCLUSÃO ============
  void _confirmarExclusao() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Excluir Funcionário',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir o funcionário?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _funcionario.nome.isNotEmpty
                          ? _funcionario.nome[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _funcionario.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _funcionario.cargo,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _funcionario.ativo 
                          ? Colors.green.shade100 
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _funcionario.ativo ? 'Ativo' : 'Inativo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _funcionario.ativo 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita!',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _excluirFuncionario();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Excluir',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _excluirFuncionario() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final provider = context.read<FuncionarioProvider>();
    final nomeFuncionario = _funcionario.nome;
    final idFuncionario = _funcionario.id;
    
    try {
      await provider.excluirTotal(idFuncionario);
      
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Funcionário "$nomeFuncionario" excluído com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          router.go('/funcionarios');
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ MÉTODOS DE DESATIVAÇÃO/REATIVAÇÃO ============
  void _confirmarAlteracaoStatus(BuildContext context) {
  final provider = context.read<FuncionarioProvider>();
  final isAtivo = _funcionario.ativo;
  final funcionarioId = _funcionario.id;
  final nomeFuncionario = _funcionario.nome;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(isAtivo ? '⚠️ Desativar Funcionário' : '✅ Reativar Funcionário'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAtivo
                ? 'Deseja DESATIVAR $nomeFuncionario?'
                : 'Deseja REATIVAR $nomeFuncionario?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (isAtivo) ...[
            const Text('• Não poderá mais bater ponto'),
            const Text('• Histórico de pontos será mantido'),
            const Text('• Pode ser reativado a qualquer momento'),
          ] else ...[
            const Text('• Voltará a poder bater ponto'),
            const Text('• Histórico de pontos permanece intacto'),
          ],
          const SizedBox(height: 12),
          Text(
            isAtivo 
                ? 'Esta ação NÃO exclui os registros de ponto.' 
                : 'Apenas reativa o acesso.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
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
          onPressed: () async {
            // 🔥 Fechar o dialog ANTES do async
            Navigator.pop(dialogContext);
            
            // 🔥 Guardar referências do messenger ANTES do async
            final messenger = ScaffoldMessenger.of(context);
            
            try {
              if (isAtivo) {
                await provider.desativar(funcionarioId);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('❌ $nomeFuncionario foi DESATIVADO'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } else {
                await provider.reativar(funcionarioId);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ $nomeFuncionario foi REATIVADO'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
              // 🔥 Recarregar dados
              if (mounted) {
                _carregarFuncionario();
                setState(() {});
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
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isAtivo ? Colors.orange : Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(isAtivo ? 'Desativar' : 'Reativar'),
        ),
      ],
    ),
  );
}

  // ============ MÉTODOS DE EDIÇÃO ============
  void _salvarEdicao() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataNascimento == null || _dataAdmissao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todas as datas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<FuncionarioProvider>();

    final funcionarioAtualizado = Funcionario(
      id: _funcionario.id,
      empresaId: _funcionario.empresaId,
      nome: _nomeController.text,
      email: _emailController.text,
      telefone: _telefoneController.text,
      cargo: _cargoController.text,
      matricula: _matriculaController.text,
      rg: _rgController.text,
      cpf: _cpfController.text,
      dataNascimento: _dataNascimento!,
      dataAdmissao: _dataAdmissao!,
      ativo: _ativo,
      fotoPath: _fotoPath ?? _funcionario.fotoPath,
    );
    
    try {
      provider.atualizar(
        _funcionario.id,
        nome: funcionarioAtualizado.nome,
        email: funcionarioAtualizado.email,
        telefone: funcionarioAtualizado.telefone,
        cargo: funcionarioAtualizado.cargo,
        matricula: funcionarioAtualizado.matricula,
        rg: funcionarioAtualizado.rg,
        cpf: funcionarioAtualizado.cpf,
        dataNascimento: funcionarioAtualizado.dataNascimento,
        dataAdmissao: funcionarioAtualizado.dataAdmissao,
        ativo: funcionarioAtualizado.ativo,
        fotoPath: funcionarioAtualizado.fotoPath,
      );
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _funcionario = funcionarioAtualizado;
        });

        messenger.showSnackBar(
          const SnackBar(
            content: Text('Funcionário atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Funcionário' : 'Detalhes do Funcionário'),
        actions: [
          // Botão Editar
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _nomeController.text = _funcionario.nome;
                  _emailController.text = _funcionario.email;
                  _telefoneController.text = _funcionario.telefone;
                  _cargoController.text = _funcionario.cargo;
                  _matriculaController.text = _funcionario.matricula;
                  _rgController.text = _funcionario.rg;
                  _cpfController.text = _funcionario.cpf;
                  _dataNascimento = _funcionario.dataNascimento;
                  _dataAdmissao = _funcionario.dataAdmissao;
                  _ativo = _funcionario.ativo;
                  _fotoPath = _funcionario.fotoPath;
                });
              },
            ),
          
          // Botão Excluir (apenas se estiver inativo ou com confirmação)
          if (!_isEditing && !_funcionario.ativo)
            IconButton(
              icon: const Icon(
                Icons.delete_forever,
                color: Colors.red,
              ),
              onPressed: _confirmarExclusao,
              tooltip: 'Excluir permanentemente',
            ),
          
          // Botão Cancelar (modo edição)
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _carregarFuncionario();
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isEditing ? _buildFormEdicao() : _buildVisualizacao(),
      ),
    );
  }

  // ============ WIDGETS DE VISUALIZAÇÃO ============
  Widget _buildVisualizacao() {
    return Column(
      children: [
        // Card com Foto e Nome
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildAvatarVisualizacao(),
                const SizedBox(height: 16),
                Text(
                  _funcionario.nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _funcionario.ativo 
                        ? Colors.green.shade50 
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _funcionario.ativo 
                          ? Colors.green.shade200 
                          : Colors.red.shade200,
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
                          color: _funcionario.ativo 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _funcionario.ativo ? 'ATIVO' : 'INATIVO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _funcionario.ativo 
                              ? Colors.green.shade700 
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Card com todos os dados
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações Completas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person_outline, 'Nome', _funcionario.nome),
                const Divider(),
                _buildInfoRow(Icons.work_outline, 'Cargo', _funcionario.cargo),
                const Divider(),
                _buildInfoRow(Icons.email_outlined, 'Email', _funcionario.email),
                const Divider(),
                _buildInfoRow(Icons.phone_outlined, 'Telefone', _funcionario.telefone),
                const Divider(),
                _buildInfoRow(Icons.badge_outlined, 'Matrícula', _funcionario.matricula),
                const Divider(),
                _buildInfoRow(Icons.credit_card_outlined, 'CPF', _funcionario.cpf),
                const Divider(),
                _buildInfoRow(Icons.assignment_ind_outlined, 'RG', _funcionario.rg),
                const Divider(),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Data de Nascimento',
                  _formatarData(_funcionario.dataNascimento),
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.calendar_month_outlined,
                  'Data de Admissão',
                  _formatarData(_funcionario.dataAdmissao),
                ),
                const Divider(),
                _buildInfoRow(
                  Icons.business_outlined,
                  'Empresa ID',
                  _funcionario.empresaId,
                ),
                if (_funcionario.dataExclusao != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    Icons.history,
                    'Data de Desativação',
                    _formatarData(_funcionario.dataExclusao!),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 🔥 BOTÃO DE DESATIVAR/REATIVAR
        if (!_isEditing)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmarAlteracaoStatus(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _funcionario.ativo ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(_funcionario.ativo ? Icons.block : Icons.check_circle),
              label: Text(
                _funcionario.ativo 
                    ? 'DESATIVAR FUNCIONÁRIO' 
                    : 'REATIVAR FUNCIONÁRIO',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Botão Editar
        if (!_isEditing)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _nomeController.text = _funcionario.nome;
                  _emailController.text = _funcionario.email;
                  _telefoneController.text = _funcionario.telefone;
                  _cargoController.text = _funcionario.cargo;
                  _matriculaController.text = _funcionario.matricula;
                  _rgController.text = _funcionario.rg;
                  _cpfController.text = _funcionario.cpf;
                  _dataNascimento = _funcionario.dataNascimento;
                  _dataAdmissao = _funcionario.dataAdmissao;
                  _ativo = _funcionario.ativo;
                  _fotoPath = _funcionario.fotoPath;
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar Todos os Dados'),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarVisualizacao() {
    if (_funcionario.fotoPath != null && _funcionario.fotoPath!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 60,
          backgroundImage: FileImage(File(_funcionario.fotoPath!)),
          child: _funcionario.ativo 
              ? null 
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Icon(
                    Icons.visibility_off,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
        );
      } catch (e) {
        return _buildAvatarFallback();
      }
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        _funcionario.nome.isNotEmpty
            ? _funcionario.nome[0].toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 2),
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

  // ============ FORMULÁRIO DE EDIÇÃO ============
  Widget _buildFormEdicao() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Editar Todos os Dados',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          _buildFotoEdicao(),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _nomeController,
            label: 'Nome Completo',
            icon: Icons.person_outline,
            validator: (v) => v?.isEmpty ?? true ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _cargoController,
            label: 'Cargo',
            icon: Icons.work_outline,
            validator: (v) => v?.isEmpty ?? true ? 'Informe o cargo' : null,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Informe o email';
              if (!v!.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _telefoneController,
            label: 'Telefone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty ?? true ? 'Informe o telefone' : null,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _matriculaController,
            label: 'Matrícula',
            icon: Icons.badge_outlined,
            validator: (v) => v?.isEmpty ?? true ? 'Informe a matrícula' : null,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _rgController,
            label: 'RG',
            icon: Icons.assignment_ind_outlined,
            validator: (v) => v?.isEmpty ?? true ? 'Informe o RG' : null,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _cpfController,
            label: 'CPF',
            icon: Icons.credit_card_outlined,
            validator: (v) => v?.isEmpty ?? true ? 'Informe o CPF' : null,
          ),
          const SizedBox(height: 16),

          _buildDataPicker(
            label: 'Data de Nascimento',
            data: _dataNascimento,
            onTap: () async {
              final data = await showDatePicker(
                context: context,
                initialDate: _dataNascimento ?? DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (data != null) {
                setState(() => _dataNascimento = data);
              }
            },
          ),
          const SizedBox(height: 16),

          _buildDataPicker(
            label: 'Data de Admissão',
            data: _dataAdmissao,
            onTap: () async {
              final data = await showDatePicker(
                context: context,
                initialDate: _dataAdmissao ?? DateTime.now(),
                firstDate: DateTime(1980),
                lastDate: DateTime(2100),
              );
              if (data != null) {
                setState(() => _dataAdmissao = data);
              }
            },
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            title: const Text(
              'Status do Funcionário',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _ativo ? 'Ativo' : 'Inativo',
              style: TextStyle(
                color: _ativo ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            value: _ativo,
            onChanged: (value) {
              setState(() => _ativo = value);
            },
            tileColor: _ativo ? Colors.green.shade50 : Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _carregarFuncionario();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _salvarEdicao,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDataPicker({
    required String label,
    required DateTime? data,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          data != null ? _formatarData(data) : 'Selecionar data',
          style: TextStyle(
            color: data != null ? Colors.black : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildFotoEdicao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto de Perfil',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _mostrarOpcoesFoto,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              border: Border.all(
                color: Colors.blue.shade300,
                width: 2,
              ),
            ),
            child: _fotoPath != null && _fotoPath!.isNotEmpty
                ? ClipOval(
                    child: Image.file(
                      File(_fotoPath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: Colors.blue.shade300,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adicionar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade300,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toque para adicionar/alterar foto',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}