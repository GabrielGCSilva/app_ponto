import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart';

class LocalizacaoService {
  final location.Location _location = location.Location();

  // 🔥 Verificar se o serviço de localização está disponível (com timeout)
  Future<bool> isLocationAvailable() async {
    try {
      // 🔥 TIMEOUT DE 3 SEGUNDOS PARA NÃO TRAVAR
      final result = await Future.any([
        _isLocationAvailableInternal(),
        Future.delayed(const Duration(seconds: 3), () => false),
      ]);
      return result;
    } catch (e) {
      debugPrint('❌ Erro ao verificar localização: $e');
      return false;
    }
  }

  Future<bool> _isLocationAvailableInternal() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    location.PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == location.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != location.PermissionStatus.granted) return false;
    }

    return true;
  }

  // 🔥 Obter localização atual (com timeout)
  Future<location.LocationData?> getLocalizacaoAtual() async {
    // 🔥 SE FOR WEB, RETORNA NULL DIRETO
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

      // 🔥 TIMEOUT DE 5 SEGUNDOS PARA OBTER LOCALIZAÇÃO
      final locationData = await Future.any([
        _location.getLocation(),
        Future.delayed(const Duration(seconds: 5), () => null),
      ]);

      if (locationData != null) {
        debugPrint('📍 Localização obtida: ${locationData.latitude}, ${locationData.longitude}');
      } else {
        debugPrint('⚠️ Timeout ao obter localização');
      }
      return locationData;
    } catch (e) {
      debugPrint('❌ Erro ao obter localização: $e');
      return null;
    }
  }

  // 🔥 Converter Lat/Long em endereço completo (com FALLBACK)
  Future<String> getEnderecoCompleto(double latitude, double longitude) async {
    try {
      // 🔥 TIMEOUT DE 5 SEGUNDOS PARA GEOCODIFICAÇÃO
      final placemarks = await Future.any([
        placemarkFromCoordinates(latitude, longitude),
        Future.delayed(const Duration(seconds: 5), () => <Placemark>[]),
      ]);

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

      // 🔥 FALLBACK: retornar coordenadas formatadas
      debugPrint('⚠️ Nenhum endereço encontrado, retornando coordenadas');
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      
    } catch (e) {
      debugPrint('❌ Erro na geocodificação: $e');
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  // 🔥 Buscar endereço completo a partir da localização atual (com FALLBACK)
  Future<String> getEnderecoAtual() async {
    // 🔥 SE FOR WEB, RETORNA TEXTO FIXO
    if (kIsWeb) {
      debugPrint('🖥️ [WEB] Usando localização simulada');
      return 'Desktop - Localização simulada';
    }

    final location = await getLocalizacaoAtual();
    if (location == null) {
      debugPrint('⚠️ Localização indisponível, usando fallback (São Paulo)');
      return 'Localização não disponível - São Paulo';
    }

    if (location.latitude == null || location.longitude == null) {
      debugPrint('⚠️ Coordenadas nulas, usando fallback (São Paulo)');
      return 'Localização não disponível - São Paulo';
    }

    return await getEnderecoCompleto(
      location.latitude!,
      location.longitude!,
    );
  }

  // 🔥 Buscar localização com endereço (tudo em um, com FALLBACK)
  Future<Map<String, dynamic>?> getLocalizacaoCompleta() async {
    try {
      // 🔥 SE FOR WEB, RETORNA TEXTO FIXO
      if (kIsWeb) {
        debugPrint('🖥️ [WEB] Usando localização simulada');
        return {
          'latitude': -23.5505,
          'longitude': -46.6333,
          'endereco': 'Desktop - Localização simulada',
        };
      }

      // 🔥 TENTAR OBTER LOCALIZAÇÃO REAL
      final location = await getLocalizacaoAtual();
      
      double lat;
      double lng;
      
      if (location != null && location.latitude != null && location.longitude != null) {
        lat = location.latitude!;
        lng = location.longitude!;
        debugPrint('📍 Localização real obtida: $lat, $lng');
      } else {
        // 🔥 FALLBACK: coordenadas padrão (São Paulo)
        debugPrint('⚠️ Localização indisponível, usando fallback (São Paulo)');
        lat = -23.5505;
        lng = -46.6333;
      }

      final endereco = await getEnderecoCompleto(lat, lng);

      return {
        'latitude': lat,
        'longitude': lng,
        'endereco': endereco,
      };
    } catch (e) {
      debugPrint('❌ Erro ao buscar localização completa: $e');
      
      // 🔥 FALLBACK DE EMERGÊNCIA
      return {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'endereco': 'Localização não disponível - São Paulo',
      };
    }
  }

  // 🔥 Obter coordenadas formatadas para exibição
  String getCoordenadasFormatadas(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}