import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // 🔥 Verificar se o dispositivo permite checar biometria
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('❌ Erro ao verificar canCheckBiometrics: $e');
      return false;
    }
  }

  // 🔥 Verificar se o dispositivo suporta biometria
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('❌ Erro ao verificar isDeviceSupported: $e');
      return false;
    }
  }

  // 🔥 Verificar se biometria é suportada
  Future<bool> isBiometricSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('❌ Erro ao verificar suporte a biometria: $e');
      return false;
    }
  }

  // 🔥 Obter biometrias disponíveis
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('❌ Erro ao obter biometrias disponíveis: $e');
      return [];
    }
  }

  // 🔥 Verificar se tem senha do dispositivo
  Future<bool> hasDevicePassword() async {
    try {
      // No Android, isDeviceSupported() retorna true se tem algum método
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      // Se não conseguir verificar, assume que tem senha
      debugPrint('⚠️ Erro ao verificar senha do dispositivo: $e');
      return true;
    }
  }

  // 🔥 Autenticar
  Future<BiometricAuthResult> authenticate({
    required String metodo,
    required String motivo,
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: motivo,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: metodo != 'Senha',
        ),
      );

      return BiometricAuthResult(
        success: isAuthenticated,
        errorMessage: isAuthenticated ? null : 'Autenticação falhou',
      );
    } catch (e) {
      return BiometricAuthResult(
        success: false,
        errorMessage: 'Erro na autenticação: $e',
      );
    }
  }
}

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;

  BiometricAuthResult({required this.success, this.errorMessage});
}
