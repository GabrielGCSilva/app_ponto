import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica se o dispositivo suporta autenticação biométrica
  Future<bool> isBiometricSupported() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o dispositivo tem biometria cadastrada
  Future<bool> hasBiometrics() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o dispositivo tem autenticação por senha (PIN, padrão, etc.)
  Future<bool> hasDevicePassword() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Lista os tipos de autenticação disponíveis no dispositivo
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Autentica usando biometria (digital ou facial)
  Future<AuthResult> authenticateWithBiometrics({
    required String motivo,
    bool stickyAuth = true,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: motivo,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return AuthResult(
        success: authenticated,
        method: 'Biometrica',
        errorMessage: authenticated ? null : 'Autenticação biométrica falhou',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        method: 'Biometrica',
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Autentica usando senha do dispositivo (PIN, padrão, etc.)
  Future<AuthResult> authenticateWithPassword({
    required String motivo,
  }) async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(
          biometricOnly: false,
        ),
      );

      return AuthResult(
        success: authenticated,
        method: 'Senha',
        errorMessage: authenticated ? null : 'Autenticação por senha falhou',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        method: 'Senha',
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Autentica usando qualquer método disponível (biometria ou senha)
  Future<AuthResult> authenticateWithAny({
    required String motivo,
  }) async {
    try {
      // Primeiro tenta biometria
      final hasBio = await isBiometricSupported();
      if (hasBio) {
        final result = await authenticateWithBiometrics(motivo: motivo);
        if (result.success) return result;
      }

      // Se falhar ou não tiver biometria, tenta senha
      return await authenticateWithPassword(motivo: motivo);
    } catch (e) {
      return AuthResult(
        success: false,
        method: 'Nenhum',
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  /// Método unificado de autenticação
  Future<AuthResult> authenticate({
    required String metodo,
    required String motivo,
  }) async {
    switch (metodo.toLowerCase()) {
      case 'biometrica':
      case 'digital':
      case 'facial':
        return await authenticateWithBiometrics(motivo: motivo);
      case 'senha':
        return await authenticateWithPassword(motivo: motivo);
      default:
        return await authenticateWithAny(motivo: motivo);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final errorStr = error.toString();
      if (errorStr.contains('NotEnrolled')) {
        return 'Nenhuma biometria cadastrada no dispositivo. Cadastre uma nas configurações.';
      }
      if (errorStr.contains('Lockout')) {
        return 'Muitas tentativas. Tente novamente mais tarde.';
      }
      if (errorStr.contains('NotAvailable')) {
        return 'Este método não está disponível no seu dispositivo.';
      }
    }
    return 'Erro ao autenticar: ${error.toString()}';
  }
}

/// Resultado da autenticação
class AuthResult {
  final bool success;
  final String method;
  final String? errorMessage;

  AuthResult({
    required this.success,
    required this.method,
    this.errorMessage,
  });
}