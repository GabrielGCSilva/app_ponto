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

  // 🔥 Converter Lat/Long em endereço completo
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

      return 'Localização não encontrada';
    } catch (e) {
      debugPrint('❌ Erro na geocodificação: $e');
      return '$latitude, $longitude';
    }
  }

  // 🔥 Buscar endereço completo a partir da localização atual
  Future<String> getEnderecoAtual() async {
    final location = await getLocalizacaoAtual();
    if (location == null) return 'Localização indisponível';

    if (location.latitude == null || location.longitude == null) {
      return 'Coordenadas não disponíveis';
    }

    return await getEnderecoCompleto(
      location.latitude!,
      location.longitude!,
    );
  }

  // 🔥 Buscar localização com endereço (tudo em um)
  Future<Map<String, dynamic>?> getLocalizacaoCompleta() async {
    try {
      final location = await getLocalizacaoAtual();
      if (location == null) return null;

      final lat = location.latitude ?? 0.0;
      final lng = location.longitude ?? 0.0;

      final endereco = await getEnderecoCompleto(lat, lng);

      return {
        'latitude': lat,
        'longitude': lng,
        'endereco': endereco,
      };
    } catch (e) {
      debugPrint('❌ Erro ao buscar localização completa: $e');
      return null;
    }
  }
}