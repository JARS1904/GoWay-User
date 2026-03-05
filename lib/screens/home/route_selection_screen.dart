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
  String _userName = 'Usuario';
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
    final userName = prefs.getString('userName') ?? 'Usuario';
    if (mounted) {
      setState(() {
        _userId = userId;
        _userName = userName;
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
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child:
                    Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.redAccent[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        duration: const Duration(seconds: 3),
      ),
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
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: 30,
              color: isDark ? Colors.white : Colors.blueAccent[700],
            ),
            const SizedBox(width: 8),
            Text(
              'GoWay',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo al usuario
            Text(
              'Hola, $_userName 👋',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '¿A dónde quieres ir?',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // Selector de origen
            DropdownButtonFormField<String>(
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
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
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
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
              isExpanded: true,
              borderRadius: BorderRadius.circular(16),
              dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
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
                  child: Text(
                    location,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
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
            _PressScale(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _origin != null && _destination != null
                      ? _searchRoutes
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent[700],
                    foregroundColor: Colors.white,
                    elevation: 3,
                    animationDuration: const Duration(milliseconds: 150),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.search_rounded, size: 20),
                  label: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Buscar',
                          style: TextStyle(fontSize: 16),
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
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_rounded,
              size: 30,
              color: isDark ? Colors.white : Colors.blueAccent[700],
            ),
            const SizedBox(width: 8),
            Text(
              'GoWay',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                  // Saludo al usuario
                  Text(
                    'Hola, $_userName 👋',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¿A dónde quieres ir?',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selector de origen
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor:
                        isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
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
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
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
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor:
                        isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
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
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
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
                  _PressScale(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _origin != null && _destination != null
                            ? _searchRoutes
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent[700],
                          foregroundColor: Colors.white,
                          elevation: 3,
                          animationDuration: const Duration(milliseconds: 150),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.search_rounded, size: 20),
                        label: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Buscar',
                                style: TextStyle(fontSize: 16),
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

    return _PressScale(
      child: Card(
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
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () async {
            if (forTablet) {
              _selectRoute(route);
            } else {
              await Future.delayed(const Duration(milliseconds: 120));
              if (!mounted) return;
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
                            route['empresa_nombre'],
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
                                  route['origen'],
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
                                  route['destino'],
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
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.grey[200]),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 15,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Horarios disponibles',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${uniqueSchedules.length}',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final routeId = route['id_ruta']?.toString() ?? '';
                        if (routeId.isEmpty) return;

                        final isFavorite = _favoriteRouteIds.contains(routeId);
                        try {
                          final response = await http.post(
                            Uri.parse(ApiService.favoritesUrl),
                            headers: {
                              'Content-Type':
                                  'application/x-www-form-urlencoded'
                            },
                            body: {
                              'id_usuario': _userId,
                              'id_ruta': routeId,
                              'action': isFavorite
                                  ? 'remove_favorite'
                                  : 'add_favorite'
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
                                  content: Row(
                                    children: [
                                      Icon(
                                        isFavorite
                                            ? Icons.heart_broken_rounded
                                            : Icons.favorite_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        isFavorite
                                            ? 'Removido de favoritos'
                                            : 'Agregado a favoritos',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: isFavorite
                                      ? Colors.grey[700]
                                      : Colors.blueAccent[700],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  margin:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 96),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
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
                                margin:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 96),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      child: Icon(
                        _favoriteRouteIds.contains(route['id_ruta']?.toString())
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: Colors.redAccent,
                        size: 26,
                      ),
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
          ...uniqueSchedules
              .map<Widget>((horario) =>
                  _ScheduleCard(route: route, horario: horario, isDark: isDark))
              .toList(),
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

/// Widget con animación de presión estilo iOS: se hunde al presionar y regresa al soltar.
class _PressScale extends StatefulWidget {
  final Widget child;
  const _PressScale({required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
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
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
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
                ...uniqueSchedules
                    .map<Widget>((horario) => _ScheduleCard(
                        route: route, horario: horario, isDark: isDark))
                    .toList(),
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

// =============================================================================
// Tarjeta de horario expandible
// =============================================================================

class _ScheduleCard extends StatefulWidget {
  final Map<String, dynamic> route;
  final Map<String, dynamic> horario;
  final bool isDark;

  const _ScheduleCard({
    required this.route,
    required this.horario,
    required this.isDark,
  });

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  bool _expanded = false;

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value, bool isDark,
      {Color? iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 15,
            color: iconColor ?? (isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final horario = widget.horario;
    final isDark = widget.isDark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      elevation: isDark ? 0 : 1,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (siempre visible) ──────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_month_rounded,
                        color: Colors.green[700], size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['empresa_nombre'],
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Origen → Destino compacto
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.blue),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                route['origen'],
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
                            const Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.red),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                route['destino'],
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
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Pill día de semana
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          horario['dia_semana'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.green[300] : Colors.green[800],
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                  height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
              const SizedBox(height: 10),
              // Horas de salida y llegada
              Row(
                children: [
                  Expanded(
                    child: _infoRow(
                      context,
                      Icons.location_on_rounded,
                      'Salida',
                      horario['hora_salida'],
                      isDark,
                      iconColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoRow(
                      context,
                      Icons.location_on_rounded,
                      'Llegada',
                      horario['hora_llegada'],
                      isDark,
                      iconColor: Colors.red,
                    ),
                  ),
                ],
              ),
              // ── Contenido expandible ──────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _infoRow(
                            context,
                            Icons.repeat_rounded,
                            'Frecuencia',
                            horario['frecuencia']?.toString() ?? '-',
                            isDark,
                            iconColor: Colors.orange[700],
                          ),
                          const SizedBox(height: 10),
                          Divider(
                              height: 1,
                              color:
                                  isDark ? Colors.white12 : Colors.grey[200]),
                          const SizedBox(height: 10),
                          _infoRow(
                            context,
                            Icons.person_rounded,
                            'Conductor',
                            horario['conductor_nombre'] ?? 'N/A',
                            isDark,
                            iconColor: Colors.blue[800],
                          ),
                          const SizedBox(height: 6),
                          _infoRow(
                            context,
                            Icons.directions_bus_rounded,
                            'Vehículo',
                            horario['vehiculo_modelo'] ?? 'N/A',
                            isDark,
                            iconColor: Colors.blue[700],
                          ),
                          const SizedBox(height: 6),
                          _infoRow(
                            context,
                            Icons.confirmation_number_rounded,
                            'Placa',
                            horario['vehiculo_placa'] ?? 'N/A',
                            isDark,
                            iconColor: Colors.orange[800],
                          ),
                          const SizedBox(height: 6),
                          _infoRow(
                            context,
                            Icons.people_alt_rounded,
                            'Capacidad',
                            '${horario['vehiculo_capacidad']?.toString() ?? 'N/A'} pasajeros',
                            isDark,
                            iconColor: Colors.purple[700],
                          ),
                          if ((route['paradas'] as List).isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Divider(
                                height: 1,
                                color:
                                    isDark ? Colors.white12 : Colors.grey[200]),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.traffic_rounded,
                                    size: 15, color: Colors.purple[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Paradas',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...(route['paradas'] as List)
                                          .map<Widget>((parada) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 2),
                                                child: Text(
                                                  '• $parada',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ))
                                          .toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 4),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
