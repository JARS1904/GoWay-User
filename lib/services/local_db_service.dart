import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Servicio para manejar la caché asíncrona y ligera usando Hive.
/// Esto evita problemas de OutOfMemoryError al no cargar todo de forma síncrona
/// en la memoria principal como lo hacía SharedPreferences.
class LocalDbService {
  static const String _locationsBox = 'locations_cache';
  static const String _routesBox = 'routes_cache';

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox<String>(_locationsBox);
      await Hive.openBox<String>(_routesBox);
      debugPrint('Hive inicializado correctamente.');
    } catch (e) {
      debugPrint('Error inicializando Hive: $e');
    }
  }

  // ==========================================
  // CACHÉ DE UBICACIONES (Locations)
  // ==========================================
  
  static Future<void> cacheLocations(List<String> locations) async {
    try {
      final box = Hive.box<String>(_locationsBox);
      final jsonStr = json.encode(locations);
      await box.put('all_locations', jsonStr);
    } catch (e) {
      debugPrint('Error al cachear locations en Hive: $e');
    }
  }

  static List<String>? getCachedLocations() {
    try {
      final box = Hive.box<String>(_locationsBox);
      final jsonStr = box.get('all_locations');
      if (jsonStr != null) {
        final List<dynamic> decoded = json.decode(jsonStr);
        return decoded.cast<String>();
      }
    } catch (e) {
      debugPrint('Error al leer locations desde Hive: $e');
    }
    return null;
  }

  // ==========================================
  // CACHÉ DE RUTAS (Búsquedas)
  // ==========================================

  static Future<void> cacheRoutes(String origin, String destination, List<dynamic> routes) async {
    try {
      final box = Hive.box<String>(_routesBox);
      final key = '${origin}_$destination';
      final jsonStr = json.encode(routes);
      await box.put(key, jsonStr);
    } catch (e) {
      debugPrint('Error al cachear rutas en Hive: $e');
    }
  }

  static List<dynamic>? getCachedRoutes(String origin, String destination) {
    try {
      final box = Hive.box<String>(_routesBox);
      final key = '${origin}_$destination';
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        return json.decode(jsonStr) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error al leer rutas desde Hive: $e');
    }
    return null;
  }
}
