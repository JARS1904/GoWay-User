import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'route_selection_screen.dart';

/// Pantalla de Rutas Favoritas
///
/// Muestra las rutas que el usuario ha marcado como favoritas.
/// Diseño responsivo con soporte para móvil y tablet.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favoriteRoutes = [];
  bool _isLoading = true;
  String? _errorMessage;
  late String _userId;

  final String _apiUrl =
      "http://192.168.30.101/GoWay/api/favorites_routes_api.php";

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';
    setState(() {
      _userId = userId;
    });
    _loadFavoriteRoutes();
  }

  /// Carga las rutas favoritas desde la API
  Future<void> _loadFavoriteRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final url = '$_apiUrl?id_usuario=$_userId&action=get_favorites';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        List<Map<String, dynamic>> routes = [];
        if (decodedResponse is List) {
          routes = List<Map<String, dynamic>>.from(decodedResponse);
        } else if (decodedResponse is Map &&
            decodedResponse.containsKey('error')) {
          throw Exception(decodedResponse['error']);
        }

        setState(() {
          _favoriteRoutes = routes;
          _isLoading = false;
        });
      } else {
        final errorBody = response.body;
        throw Exception('Error ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Determina si el dispositivo es una tablet
  bool get _isTablet {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rutas Favoritas'),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rutas Favoritas'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.red[400] : Colors.red[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar rutas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadFavoriteRoutes,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return _isTablet ? _buildTabletLayout(isDark) : _buildMobileLayout(isDark);
  }

  /// Layout para dispositivos móviles
  Widget _buildMobileLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Favoritas'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _favoriteRoutes.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoriteRoutes.length,
              itemBuilder: (context, index) {
                final route = _favoriteRoutes[index];
                return _buildFavoriteCard(route, isDark, index);
              },
            ),
    );
  }

  /// Layout para dispositivos tablet
  Widget _buildTabletLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Favoritas'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _favoriteRoutes.isEmpty
          ? _buildEmptyState(isDark)
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _favoriteRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _favoriteRoutes[index];
                    return _buildFavoriteCard(route, isDark, index);
                  },
                ),
              ),
            ),
    );
  }

  /// Widget para la tarjeta de ruta favorita
  Widget _buildFavoriteCard(
      Map<String, dynamic> route, bool isDark, int index) {
    // Extraer los datos de la ruta
    final empresaNombre = route['empresa_nombre'] ?? 'Empresa desconocida';
    final origen = route['origen'] ?? 'Origen desconocido';
    final destino = route['destino'] ?? 'Destino desconocido';
    final horarios = route['horarios'] is List ? (route['horarios'] as List).length : 0;
    final routeId = route['id_ruta']?.toString() ?? route['id']?.toString() ?? '';

    return Card(
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      elevation: 1,
      shadowColor: isDark ? Colors.black54 : Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Deduplicar horarios como en route_selection_screen
          final uniqueSchedules = (route['horarios'] as List)
              .fold<Map<String, dynamic>>({}, (map, schedule) {
                final key =
                    '${schedule['dia_semana']}-${schedule['hora_salida']}-${schedule['hora_llegada']}';
                map[key] = schedule;
                return map;
              })
              .values
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteDetailsScreen(
                route: {
                  ...route,
                  'horarios': uniqueSchedules,
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre de la empresa con icono
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.business_rounded,
                          size: 25,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            empresaNombre,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    color: Colors.redAccent,
                    onPressed: () async {
                      if (routeId.isNotEmpty) {
                        try {
                          final response = await http.post(
                            Uri.parse(_apiUrl),
                            headers: {
                              'Content-Type':
                                  'application/x-www-form-urlencoded'
                            },
                            body: {
                              'id_usuario': _userId,
                              'id_ruta': routeId,
                              'action': 'remove_favorite'
                            },
                          );

                          if (response.statusCode == 200) {
                            _loadFavoriteRoutes();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removido de favoritos'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          } else {
                            throw Exception('Error al eliminar');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Origen y Destino con iconos
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      origen,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: isDark ? Colors.grey : Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: Colors.green[400],
                  ),
                  Expanded(
                    child: Text(
                      destino,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
              ),
              const SizedBox(height: 8),
              
              // Horarios disponibles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Horarios disponibles:',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$horarios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar cuando no hay rutas favoritas
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay rutas favoritas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega rutas a favoritos para acceder rápidamente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigator.pushNamed(context, '/rutas');
            },
            icon: const Icon(Icons.add),
            label: const Text('Explorar Rutas'),
          ),
        ],
      ),
    );
  }
}
