/// Servicio de configuración de APIs
///
/// Todos los endpoints centralizados en un solo lugar
/// Para cambiar la IP: solo modifica [baseUrl]
class ApiService {
  static const String baseUrl = "http://192.168.30.101/GoWay/api";

  // Endpoints
  static const String loginUrl = "$baseUrl/login.php";
  static const String usuariosUrl = "$baseUrl/usuarios.php";
  static const String routesUrl = "$baseUrl/routes_api.php";
  static const String favoritesUrl = "$baseUrl/favorites_routes_api.php";
}
