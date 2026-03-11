/// Servicio de configuración de APIs
///
/// Todos los endpoints centralizados en un solo lugar
/// Para cambiar la IP: solo modifica [baseUrl]
class ApiService {
  static const String baseUrl = "http://172.31.99.110/GoWay/api";
  static const String baseGoWayUrl = "http://172.31.99.110/GoWay";

  /// Construye la URL completa de una foto de perfil a partir de su ruta relativa.
  static String? buildPhotoUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return null;
    return '$baseGoWayUrl/$relativeUrl';
  }

  // Endpoints
  static const String loginUrl = "$baseUrl/login.php";
  static const String usuariosUrl = "$baseUrl/usuarios.php";
  static const String routesUrl = "$baseUrl/routes_api.php";
  static const String favoritesUrl = "$baseUrl/favorites_routes_api.php";
  static const String reportsUrl = "$baseUrl/reportes_api.php";
}
