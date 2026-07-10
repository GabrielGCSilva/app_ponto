import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocalizacaoService {
  // 🔥 VERIFICAR SE O GPS ESTÁ ATIVO
  Future<bool> isLocationAvailable() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Serviço de localização desativado');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Permissão de localização negada');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Permissão de localização negada permanentemente');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Erro ao verificar localização: $e');
      return false;
    }
  }

  // 🔥 OBTER LOCALIZAÇÃO ATUAL (COM LAST KNOWN + TIMEOUT)
  Future<Position?> getLocalizacaoAtual() async {
    if (kIsWeb) {
      debugPrint('🖥️ [WEB] Localização simulada');
      return null;
    }

    try {
      final disponivel = await isLocationAvailable();
      if (!disponivel) {
        debugPrint('⚠️ Localização não disponível');
        return null;
      }

      // 🔥 TENTAR ÚLTIMA POSIÇÃO CONHECIDA (INSTANTÂNEA)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        debugPrint('📍 [GPS] Última posição conhecida: ${lastKnown.latitude}, ${lastKnown.longitude}');
        return lastKnown;
      }

      // 🔥 SE NÃO TIVER, BUSCAR NOVA POSIÇÃO
      debugPrint('📍 [GPS] Buscando nova posição...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint(
        '📍 [GPS] Posição obtida: ${position.latitude}, ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('❌ Erro ao obter localização: $e');
      return null;
    }
  }

  // 🔥 CONVERTER LAT/LONG EM ENDEREÇO (com FALLBACK)
  Future<String> getEnderecoCompleto(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('⚠️ Timeout na geocodificação');
              return <Placemark>[];
            },
          );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final endereco = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        if (endereco.isNotEmpty) {
          debugPrint('📍 Endereço encontrado: $endereco');
          return endereco;
        }
      }

      debugPrint('⚠️ Nenhum endereço encontrado, retornando coordenadas');
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      debugPrint('❌ Erro na geocodificação: $e');
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  // 🔥 BUSCAR ENDEREÇO ATUAL (com FALLBACK)
  Future<String> getEnderecoAtual() async {
    if (kIsWeb) {
      debugPrint('🖥️ [WEB] Usando localização simulada');
      return 'Desktop - Localização simulada';
    }

    final position = await getLocalizacaoAtual();
    if (position == null) {
      debugPrint('⚠️ Localização indisponível, usando fallback (São Paulo)');
      return 'Localização não disponível - São Paulo';
    }

    return await getEnderecoCompleto(position.latitude, position.longitude);
  }

  // 🔥 BUSCAR LOCALIZAÇÃO COMPLETA (com FALLBACK)
  Future<Map<String, dynamic>?> getLocalizacaoCompleta() async {
    try {
      if (kIsWeb) {
        debugPrint('🖥️ [WEB] Usando localização simulada');
        return {
          'latitude': -23.5505,
          'longitude': -46.6333,
          'endereco': 'Desktop - Localização simulada',
        };
      }

      final position = await getLocalizacaoAtual();

      if (position != null) {
        final endereco = await getEnderecoCompleto(
          position.latitude,
          position.longitude,
        );
        debugPrint(
          '📍 Localização real obtida: ${position.latitude}, ${position.longitude}',
        );
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'endereco': endereco,
        };
      } else {
        debugPrint('⚠️ Localização indisponível, usando fallback (São Paulo)');
        return {
          'latitude': -23.5505,
          'longitude': -46.6333,
          'endereco': 'Localização não disponível - São Paulo',
        };
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar localização completa: $e');
      return {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'endereco': 'Localização não disponível - São Paulo',
      };
    }
  }

  // 🔥 COORDENADAS FORMATADAS
  String getCoordenadasFormatadas(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}