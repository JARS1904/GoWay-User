// ██████╗  ██████╗  ██╗    ██╗ █████╗ ██╗   ██╗
// ██╔════╝ ██╔═══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
// ██║  ███╗██║   ██║██║ █╗ ██║███████║ ╚████╔╝
// ██║   ██║██║   ██║██║███╗██║██╔══██║  ╚██╔╝
// ╚██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║   ██║
//  ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
//
// main.dart - Punto de entrada principal
// Versión: 2.0.0 | Última actualización: 29-03-2025}
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:goway_user/services/api_service.dart';
import 'package:goway_user/screens/map/map_screen.dart';
import 'package:goway_user/screens/profile/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationWrapper extends StatefulWidget {
  final Function(bool)? onThemeChange;

  const MainNavigationWrapper({super.key, this.onThemeChange});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const RouteSelectionScreen(),
      const MapScreen(),
      FutureBuilder(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return ProfileScreen(
              userName: snapshot.data?['name'] ?? 'Usuario',
              userEmail: snapshot.data?['email'] ?? 'email@ejemplo.com',
              onThemeChange: widget.onThemeChange,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    ];
  }

  Future<Map<String, String>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName') ?? 'Usuario',
      'email': prefs.getString('userEmail') ?? 'email@ejemplo.com',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              "lib/assets/icons/icon_home.png",
              width: 24,
              height: 24,
              color: _currentIndex == 0
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.map,
              color: _currentIndex == 1
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: 'Mapas',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              "lib/assets/icons/icon_user.png",
              width: 24,
              height: 24,
              color: _currentIndex == 2
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen>
    with WidgetsBindingObserver {
  String? _origin;
  String? _destination;
  List<String> _locations = [];
  List<dynamic> _routes = [];
  bool _loading = false;
  late String _userId;
  Map<String, dynamic>? _selectedRoute;
  Set<String> _favoriteRouteIds = {};
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeUserId();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      // Recargar favoritos cuando la app vuelve al foreground
      _loadFavorites();
    }
  }

  /// Método público para recargar favoritos desde el exterior
  /// Se llama cuando se vuelve a la pantalla de inicio desde otra pantalla
  void refreshFavorites() {
    _loadFavorites();
  }

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';
    if (mounted) {
      setState(() {
        _userId = userId;
      });
    }
    _loadFavorites();
    _fetchLocations();
  }

  /// Carga los favoritos actuales del usuario
  Future<void> _loadFavorites() async {
    try {
      final url =
          '${ApiService.favoritesUrl}?id_usuario=$_userId&action=get_favorites';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        Set<String> favoriteIds = {};
        if (decodedResponse is List) {
          for (var route in decodedResponse) {
            if (route is Map && route.containsKey('id_ruta')) {
              favoriteIds.add(route['id_ruta'].toString());
            } else if (route is Map && route.containsKey('id')) {
              favoriteIds.add(route['id'].toString());
            }
          }
        }

        if (mounted) {
          setState(() {
            _favoriteRouteIds = favoriteIds;
          });
        }
      }
    } catch (e) {
      debugPrint('Error al cargar favoritos: $e');
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final url = Uri.parse('${ApiService.routesUrl}?action=locations');
      debugPrint('Consultando API en: $url');

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Respuesta del servidor: ${response.statusCode}');
      debugPrint('Contenido de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is List) {
          if (mounted) {
            setState(() {
              _locations = data.cast<String>();
            });
          }
          return;
        } else if (data is Map && data.containsKey('error')) {
          throw Exception(data['error']);
        }
        throw Exception('Formato de respuesta no válido');
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } on Exception catch (e) {
      debugPrint('Error al cargar ubicaciones: $e');
      _showError('No se pudieron cargar las ubicaciones. Intenta nuevamente.');
      Future.delayed(const Duration(seconds: 5), _fetchLocations);
    }
  }

  Future<void> _searchRoutes() async {
    if (_origin == null || _destination == null) return;

    if (mounted) {
      setState(() {
        _loading = true;
        _routes = [];
        _selectedRoute = null;
      });
    }

    try {
      final response = await http.post(
        Uri.parse(ApiService.routesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'search_routes',
          'origin': _origin,
          'destination': _destination,
        }),
      );

      debugPrint('Respuesta de búsqueda de rutas: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData is List) {
          final processedRoutes =
              _processRoutes(responseData.cast<Map<String, dynamic>>());
          if (mounted) {
            setState(() {
              _routes = processedRoutes;
            });
          }
        } else if (responseData is Map && responseData.containsKey('error')) {
          _showError(responseData['error']);
        } else {
          _showError('Formato de respuesta no válido');
        }
      } else {
        _showError(responseData['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      _showError('Error de conexión: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<dynamic> _processRoutes(List<Map<String, dynamic>> routes) {
    final Map<int, dynamic> uniqueRoutes = {};

    for (var route in routes) {
      final routeId = route['id_ruta'] as int;

      if (uniqueRoutes.containsKey(routeId)) {
        final existingRoute = uniqueRoutes[routeId];
        final existingSchedules = List.from(existingRoute['horarios']);
        final newSchedules = List.from(route['horarios']);

        final combinedSchedules = [...existingSchedules, ...newSchedules]
            .fold<Map<String, dynamic>>({}, (map, schedule) {
              final key =
                  '${schedule['dia_semana']}-${schedule['hora_salida']}-${schedule['hora_llegada']}';
              map[key] = schedule;
              return map;
            })
            .values
            .toList();

        existingRoute['horarios'] = combinedSchedules;
      } else {
        uniqueRoutes[routeId] = <String, dynamic>{...route};
      }
    }

    return uniqueRoutes.values.toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _selectRoute(Map<String, dynamic> route) {
    setState(() {
      _selectedRoute = route;
    });
  }

  bool get _isTablet {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    if (_isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        elevation: .8,
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Row(
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'GoWay',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿A dónde quieres ir?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Selector de origen
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Seleccione el origen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
              ),
              value: _origin,
              items: _locations.map((String location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _origin = newValue;
                  _routes = [];
                  _selectedRoute = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Selector de destino
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Seleccione el destino',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
              ),
              value: _destination,
              items: _locations.map((String location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _destination = newValue;
                  _routes = [];
                  _selectedRoute = null;
                });
              },
            ),
            const SizedBox(height: 24),

            // Botón de búsqueda
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _origin != null && _destination != null
                    ? _searchRoutes
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Buscar',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Separador
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Divider(
                color: Colors.grey[400],
                thickness: 2,
              ),
            ),

            const SizedBox(height: 24),

            // Mostrar carga o resultados
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_routes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _routes.length,
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return _buildRouteCard(route);
                  },
                ),
              )
            else if (_origin != null && _destination != null && !_loading)
              const Center(
                child: Text(
                  'No se encontraron rutas para esta combinación',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        elevation: .8,
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Row(
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'GoWay',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          // Panel izquierdo para búsqueda
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿A dónde quieres ir?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selector de origen
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Seleccione el origen',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                    ),
                    value: _origin,
                    items: _locations.map((String location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _origin = newValue;
                        _routes = [];
                        _selectedRoute = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Selector de destino
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Seleccione el destino',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                    ),
                    value: _destination,
                    items: _locations.map((String location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _destination = newValue;
                        _routes = [];
                        _selectedRoute = null;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón de búsqueda
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _origin != null && _destination != null
                          ? _searchRoutes
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Buscar',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Separador
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Divider(
                      color: Colors.grey[400],
                      thickness: 2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lista de rutas
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_routes.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _routes.length,
                        itemBuilder: (context, index) {
                          final route = _routes[index];
                          return _buildRouteCard(route, forTablet: true);
                        },
                      ),
                    )
                  else if (_origin != null && _destination != null && !_loading)
                    const Center(
                      child: Text(
                        'No se encontraron rutas para esta combinación',
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Panel derecho para detalles
          Expanded(
            flex: 3,
            child: _selectedRoute != null
                ? _buildRouteDetails(_selectedRoute!)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_bus,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Selecciona una ruta para ver los detalles',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, {bool forTablet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uniqueSchedules = (route['horarios'] as List)
        .fold<Map<String, dynamic>>({}, (map, schedule) {
          final key =
              '${schedule['dia_semana']}-${schedule['hora_salida']}-${schedule['hora_llegada']}';
          map[key] = schedule;
          return map;
        })
        .values
        .toList();

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
          if (forTablet) {
            _selectRoute(route);
          } else {
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
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.business_rounded,
                    size: 25,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    route['empresa_nombre'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    route['origen'],
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
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
                  Text(
                    route['destino'],
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
              ),
              const SizedBox(height: 8),
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
                      const SizedBox(width: 8),
                    ],
                  ),
                  Text(
                    '${uniqueSchedules.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _favoriteRouteIds.contains(route['id_ruta']?.toString())
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    color: Colors.redAccent,
                    onPressed: () async {
                      final routeId = route['id_ruta']?.toString() ?? '';
                      if (routeId.isEmpty) return;

                      final isFavorite = _favoriteRouteIds.contains(routeId);
                      try {
                        final response = await http.post(
                          Uri.parse(ApiService.favoritesUrl),
                          headers: {
                            'Content-Type': 'application/x-www-form-urlencoded'
                          },
                          body: {
                            'id_usuario': _userId,
                            'id_ruta': routeId,
                            'action':
                                isFavorite ? 'remove_favorite' : 'add_favorite'
                          },
                        );

                        if (response.statusCode == 200) {
                          if (mounted) {
                            setState(() {
                              if (isFavorite) {
                                _favoriteRouteIds.remove(routeId);
                              } else {
                                _favoriteRouteIds.add(routeId);
                              }
                            });
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFavorite
                                    ? 'Removido de favoritos'
                                    : 'Agregado a favoritos'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
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
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent[700],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Ver detalles',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildRouteDetails(Map<String, dynamic> route) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uniqueSchedules = (route['horarios'] as List)
        .fold<Map<String, dynamic>>({}, (map, schedule) {
          final key =
              '${schedule['dia_semana']}-${schedule['hora_salida']}-${schedule['hora_llegada']}';
          map[key] = schedule;
          return map;
        })
        .values
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route['nombre'] ?? 'Ruta sin nombre',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${route['origen']} - ${route['destino']}',
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? Colors.grey[600] : Colors.grey[300],
          ),
          const SizedBox(height: 16),

          // Información de la empresa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de la empresa:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                    Icons.business_rounded, 'Nombre:', route['empresa_nombre'],
                    isDark: isDark),
                _buildInfoRow(Icons.phone_android_rounded, 'Teléfono:',
                    route['empresa_telefono'],
                    isDark: isDark),
                _buildInfoRow(Icons.location_on_rounded, 'Dirección:',
                    route['empresa_direccion'] ?? 'No especificada',
                    isDark: isDark),
                _buildInfoRow(Icons.email_rounded, 'Email:',
                    route['empresa_email'] ?? 'No especificado',
                    isDark: isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Horarios disponibles
          const Text(
            'Horarios disponibles:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...uniqueSchedules.map<Widget>((horario) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          route['empresa_nombre'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 20,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              horario['dia_semana'],
                              style: const TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            route['origen'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 16),
                          Text(
                            route['destino'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 20,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Salida',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Llegada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            horario['hora_salida'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            horario['hora_llegada'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat_rounded,
                            size: 20,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Frecuencia: ${horario['frecuencia']}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Paradas de la ruta
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.traffic_rounded,
                                size: 20,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Paradas:',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(route['paradas'] as List).map<Widget>((parada) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 28, bottom: 4),
                              child: Text(
                                '• $parada',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Información del conductor y vehículo
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: Colors.blue[800],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Conductor: ${horario['conductor_nombre'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.directions_bus_rounded,
                                size: 20,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vehículo: ${horario['vehiculo_modelo'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.confirmation_number_rounded,
                                size: 20,
                                color: Colors.orange[800],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Placa: ${horario['vehiculo_placa'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                size: 20,
                                color: Colors.purple[800],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Capacidad: ${horario['vehiculo_capacidad']?.toString() ?? 'N/A'} pasajeros',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value,
      {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'No especificado',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RouteDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    final uniqueSchedules = (route['horarios'] as List)
        .fold<Map<String, dynamic>>({}, (map, schedule) {
          final key =
              '${schedule['dia_semana']}-${schedule['hora_salida']}-${schedule['hora_llegada']}';
          map[key] = schedule;
          return map;
        })
        .values
        .toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0.8,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: Text(
          route['empresa_nombre'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 800 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route['nombre'] ?? 'Ruta sin nombre',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${route['origen']} - ${route['destino']}',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                ),
                const SizedBox(height: 16),

                // Información de la empresa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark ? const Color(0xFF3C3C3C) : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de la empresa:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.business_rounded, 'Nombre:',
                          route['empresa_nombre'],
                          isDark: isDark),
                      _buildInfoRow(Icons.phone_android_rounded, 'Teléfono:',
                          route['empresa_telefono'],
                          isDark: isDark),
                      _buildInfoRow(Icons.location_on_rounded, 'Dirección:',
                          route['empresa_direccion'] ?? 'No especificada',
                          isDark: isDark),
                      _buildInfoRow(Icons.email_rounded, 'Email:',
                          route['empresa_email'] ?? 'No especificado',
                          isDark: isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                ),
                const SizedBox(height: 16),

                // Horarios disponibles
                Text(
                  'Horarios disponibles:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ...uniqueSchedules.map<Widget>((horario) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3C3C3C)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                route['empresa_nombre'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_rounded,
                                    size: 20,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    horario['dia_semana'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  route['origen'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Icon(Icons.arrow_forward,
                                    size: 16,
                                    color: isDark ? Colors.grey : Colors.black),
                                Text(
                                  route['destino'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Salida',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Llegada',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  horario['hora_salida'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  horario['hora_llegada'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.repeat_rounded,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Frecuencia: ${horario['frecuencia']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Paradas de la ruta
                          Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.traffic_rounded,
                                      size: 20,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Paradas:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...(route['paradas'] as List)
                                    .map<Widget>((parada) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 28, bottom: 4),
                                    child: Text(
                                      '• $parada',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Información del conductor y vehículo
                          Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_rounded,
                                      size: 20,
                                      color: Colors.blue[800],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Conductor: ${horario['conductor_nombre'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_bus_rounded,
                                      size: 20,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vehículo: ${horario['vehiculo_modelo'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_rounded,
                                      size: 20,
                                      color: Colors.orange[800],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Placa: ${horario['vehiculo_placa'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_alt_rounded,
                                      size: 20,
                                      color: Colors.purple[800],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Capacidad: ${horario['vehiculo_capacidad']?.toString() ?? 'N/A'} pasajeros',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value,
      {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'No especificado',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
