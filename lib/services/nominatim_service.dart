import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NominatimPlace {
  final String displayName;
  final LatLng location;

  NominatimPlace({required this.displayName, required this.location});

  factory NominatimPlace.fromJson(Map<String, dynamic> json) {
    return NominatimPlace(
      displayName: json['display_name'] ?? 'Ubicación desconocida',
      location: LatLng(
        double.parse(json['lat'].toString()),
        double.parse(json['lon'].toString()),
      ),
    );
  }
}

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Busca una dirección en OpenStreetMap y devuelve una lista de resultados
  static Future<List<NominatimPlace>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      // Parámetros: formato JSON, límite de 5 resultados y restringido a México (opcional pero recomendado)
      final uri = Uri.parse(
          '$_baseUrl?q=${Uri.encodeComponent(query)}&format=json&limit=8&countrycodes=mx');

      final response = await http.get(uri, headers: {
        // Nominatim exige un User-Agent identificable
        'User-Agent': 'com.example.goway_user',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => NominatimPlace.fromJson(item)).toList();
      } else {
        throw Exception('Error al contactar el servidor de búsqueda');
      }
    } catch (e) {
      throw Exception('Fallo en la búsqueda: $e');
    }
  }
}
