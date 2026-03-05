import 'package:flutter/material.dart';
import 'package:goway_user/services/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../home/route_selection_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFavoriteRoutes();
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
  /// Método público para refrescar desde fuera (e.g. nav bar)
  void refresh() => _loadFavoriteRoutes();

  Future<void> _loadFavoriteRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final url =
          '${ApiService.favoritesUrl}?id_usuario=$_userId&action=get_favorites';
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
          title: const Text(
            'Rutas favoritas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
          foregroundColor: isDark ? Colors.white : Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Rutas favoritas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
          foregroundColor: isDark ? Colors.white : Colors.black,
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
        title: const Text(
          'Rutas favoritas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteRoutes,
            tooltip: 'Recargar',
          ),
        ],
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
        title: const Text(
          'Rutas Favoritas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavoriteRoutes,
            tooltip: 'Recargar',
          ),
        ],
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
    final empresaNombre = route['empresa_nombre'] ?? 'Empresa desconocida';
    final origen = route['origen'] ?? 'Origen desconocido';
    final destino = route['destino'] ?? 'Destino desconocido';

    final uniqueSchedules = (route['horarios'] as List)
        .fold<Map<String, dynamic>>({}, (map, schedule) {
          final key =
              '${schedule['dia_semana']}-${schedule['hora_salida']}-${schedule['hora_llegada']}';
          map[key] = schedule;
          return map;
        })
        .values
        .toList();
    final horarios = uniqueSchedules.length;

    final routeId =
        route['id_ruta']?.toString() ?? route['id']?.toString() ?? '';

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
              // ── Header ──────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_bus_rounded,
                        color: Colors.blueAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empresaNombre,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.red),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                origen,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward,
                                size: 11,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                            const SizedBox(width: 4),
                            Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.green[400]),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                destino,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                  height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
              const SizedBox(height: 10),
              // ── Horarios disponibles ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          size: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Horarios disponibles',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$horarios',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.blueAccent[100]
                            : Colors.blueAccent[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Acciones: corazón + ver detalles ────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (routeId.isEmpty) return;
                      try {
                        final response = await http.post(
                          Uri.parse(ApiService.favoritesUrl),
                          headers: {
                            'Content-Type': 'application/x-www-form-urlencoded'
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
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.heart_broken_rounded,
                                        color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Text('Removido de favoritos',
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                                backgroundColor: Colors.grey[700],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                margin:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 96),
                                duration: const Duration(seconds: 1),
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
                              content: Row(
                                children: [
                                  const Icon(Icons.error_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text('Error: $e',
                                          style: const TextStyle(
                                              color: Colors.white))),
                                ],
                              ),
                              backgroundColor: Colors.redAccent[700],
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 26,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ver detalles',
                      style: TextStyle(fontSize: 12, color: Colors.white),
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
