// â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ•—    â–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•—   â–ˆâ–ˆâ•—
// â–ˆâ–ˆâ•”â•â•â•â•â• â–ˆâ–ˆâ•”â•â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘    â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â•šâ–ˆâ–ˆâ•— â–ˆâ–ˆâ•”â•
// â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘ â–ˆâ•— â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•‘ â•šâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•
// â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•‘  â•šâ–ˆâ–ˆâ•”â•
// â•šâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•â•šâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•â•šâ–ˆâ–ˆâ–ˆâ•”â–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•‘
//  â•šâ•â•â•â•â•â•  â•šâ•â•â•â•â•â•  â•šâ•â•â•â•šâ•â•â• â•šâ•â•  â•šâ•â•   â•šâ•â•
//
// map_screen.dart - Pantalla de mapa con OpenStreetMap
// VersiÃ³n: 2.0.0 | Ãšltima actualizaciÃ³n: 19-01-2026
// Mantenido por: Hydra. Inc

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goway_user/screens/map/map_search_delegate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  // Cambio: Aislamiento del marcador GPS con ValueNotifier.
  // En lugar de usar setState y repintar todo el mapa/pantalla, solo 
  // notificamos el cambio a la capa del marcador (optimiza batería y CPU).
  final ValueNotifier<LatLng> _currentLocationNotifier = 
      ValueNotifier(const LatLng(18.17678, -93.06376)); // Jalpa de Méndez
  double _zoom = 15;
  bool _isLoading = true;
  double _rotation = 0.0;
  StreamSubscription<MapEvent>? _mapEventSubscription;
  bool _darkMapEnabled = false;
  
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _mapController = MapController();
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotate || event is MapEventMove) {
        final newRotation = _mapController.camera.rotation;
        if ((_rotation - newRotation).abs() > 0.1) {
          if (mounted) {
            setState(() {
              _rotation = newRotation;
            });
          }
        }
      }
    });
    _initLocation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapEventSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _darkMapEnabled = prefs.getBool('darkMapEnabled') ?? false;
      });
    }
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Los servicios de ubicación están deshabilitados.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Los permisos de ubicación fueron denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error('Permisos denegados permanentemente.');
      }

      // Cambio: Para igualar la alta precisión de goway_card_test, usamos
      // el stream del GPS que fuerza una nueva lectura del satélite,
      // ignorando la ubicación vieja guardada en la caché del celular.
      Position position = await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).first;
      
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      if (mounted) {
        _currentLocationNotifier.value = newLocation;
        setState(() {
          _isLoading = false;
        });
        _mapController.move(newLocation, _zoom);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicaciÃ³n estÃ¡n deshabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicaciÃ³n fueron denegados');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permisos denegados permanentemente.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _centerMap(LatLng location) {
    _mapController.move(location, _zoom);
    _currentLocationNotifier.value = location;
  }

  void _zoomIn() {
    if (_zoom < 22) {
      _zoom += 1;
      _mapController.move(_currentLocationNotifier.value, _zoom);
    }
  }

  void _zoomOut() {
    if (_zoom > 2) {
      _zoom -= 1;
      _mapController.move(_currentLocationNotifier.value, _zoom);
    }
  }

  void _toggleTracking() async {
    if (_isTracking) {
      // Detener seguimiento
      await _positionStreamSubscription?.cancel();
      setState(() {
        _isTracking = false;
      });
    } else {
      // Iniciar seguimiento
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Los servicios de ubicación están deshabilitados.')),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Los permisos de ubicación fueron denegados')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos denegados permanentemente.')),
        );
        return;
      }

      setState(() {
        _isTracking = true;
      });

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // Alta precisión (ahorra batería)
          distanceFilter: 5, // Filtro de 5 metros
        ),
      ).listen((Position position) {
        LatLng newLocation = LatLng(position.latitude, position.longitude);
        if (mounted) {
          _currentLocationNotifier.value = newLocation;
          if (_isTracking) {
             _mapController.move(newLocation, _zoom);
          }
        }
      }, onError: (e) {
        if (!mounted) return;
        setState(() {
          _isTracking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en seguimiento: $e')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mapa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: MapSearchDelegate(),
              );
              if (result != null) {
                _centerMap(result as LatLng);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Mapa principal
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocationNotifier.value,
              initialZoom: _zoom,
              minZoom: 2,
              maxZoom: 22,
              keepAlive: true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                // Cambio: Modo claro usa Carto Voyager, modo oscuro usa Carto Dark All
                urlTemplate: _darkMapEnabled
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.goway_user',
                maxNativeZoom: 19,
                maxZoom: 22,
                minZoom: 2,
                retinaMode: true,
                tileProvider: NetworkTileProvider(),
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
                wmsOptions: null,
              ),
              ValueListenableBuilder<LatLng>(
                valueListenable: _currentLocationNotifier,
                builder: (context, currentLocation, _) {
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation,
                        width: 24,
                        height: 24,
                        child: Tooltip(
                          message: 'Mi Ubicación',
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent[700],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),

          // Loading indicator
          if (_isLoading)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : Colors.blueAccent[700],
                ),
              ),
            ),

          // BrÃºjula inteligente
          if (_rotation != 0.0)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  _mapController.rotate(0.0);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Transform.rotate(
                    angle: -_rotation * (math.pi / 180.0),
                    child: Icon(Icons.explore,
                        color: isDark ? Colors.white : Colors.red[600], size: 28),
                  ),
                ),
              ),
            ),

          // Controles de zoom (un poco mÃ¡s abajo)
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom In
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _zoomIn,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                // Zoom Out
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _zoomOut,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Botones Inferiores
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        Position position = await _determinePosition();
                        LatLng loc = LatLng(position.latitude, position.longitude);
                        _centerMap(loc);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    icon: Image.asset(
                      'lib/assets/icons/icons8-marcador-filled.png',
                      color: Colors.white,
                      width: 24,
                      height: 24,
                    ),
                    label: const Text(
                      'Mi ubicación',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTracking ? Colors.red[600] : const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    icon: Icon(
                      _isTracking ? Icons.stop_rounded : Icons.directions_walk_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      _isTracking ? 'Detener' : 'Seguir viaje',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
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
