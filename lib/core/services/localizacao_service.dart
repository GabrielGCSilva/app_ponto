import 'package:flutter/material.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart';

class LocalizacaoService {
  final location.Location _location = location.Location();

  // 🔥 Verificar se o serviço de localização está disponível
  Future<bool> isLocationAvailable() async {
    try {
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
    } catch (e) {
      debugPrint('❌ Erro ao verificar localização: $e');
      return false;
    }
  }

  // 🔥 Obter localização atual
  Future<location.LocationData?> getLocalizacaoAtual() async {
    try {
      final disponivel = await isLocationAvailable();
      if (!disponivel) {
        debugPrint('⚠️ Localização não disponível');
        return null;
      }

      final locationData = await _location.getLocation();
      debugPrint('📍 Localização obtida: ${locationData.latitude}, ${locationData.longitude}');
      return locationData;
    } catch (e) {
      debugPrint('❌ Erro ao obter localização: $e');
      return null;
    }
  }

  // 🔥 Converter Lat/Long em endereço completo (com FALLBACK)
  Future<String> getEnderecoCompleto(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
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

        debugPrint('📍 Endereço encontrado: $endereco');
        return endereco;
      }

      // 🔥 FALLBACK: retornar coordenadas formatadas
      debugPrint('⚠️ Nenhum endereço encontrado, retornando coordenadas');
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      
    } catch (e) {
      debugPrint('❌ Erro na geocodificação: $e');
      
      // 🔥 FALLBACK: retornar coordenadas formatadas
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    }
  }

  // 🔥 Buscar endereço completo a partir da localização atual (com FALLBACK)
  Future<String> getEnderecoAtual() async {
    final location = await getLocalizacaoAtual();
    if (location == null) {
      // 🔥 FALLBACK: coordenadas padrão (São Paulo)
      debugPrint('⚠️ Localização indisponível, usando fallback (São Paulo)');
      return await getEnderecoCompleto(-23.5505, -46.6333);
    }

    if (location.latitude == null || location.longitude == null) {
      // 🔥 FALLBACK: coordenadas padrão (São Paulo)
      debugPrint('⚠️ Coordenadas nulas, usando fallback (São Paulo)');
      return await getEnderecoCompleto(-23.5505, -46.6333);
    }

    return await getEnderecoCompleto(
      location.latitude!,
      location.longitude!,
    );
  }

  // 🔥 Buscar localização com endereço (tudo em um, com FALLBACK)
  Future<Map<String, dynamic>?> getLocalizacaoCompleta() async {
    try {
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
      
      // 🔥 FALLBACK: coordenadas padrão (São Paulo)
      debugPrint('⚠️ Usando fallback de emergência (São Paulo)');
      return {
        'latitude': -23.5505,
        'longitude': -46.6333,
        'endereco': 'Localização não disponível - São Paulo',
      };
    }
  }

  // 🔥 NOVO: Obter coordenadas formatadas para exibição
  String getCoordenadasFormatadas(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}