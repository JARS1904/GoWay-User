// ██████╗  ██████╗  ██╗    ██╗ █████╗ ██╗   ██╗
// ██╔════╝ ██╔═══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
// ██║  ███╗██║   ██║██║ █╗ ██║███████║ ╚████╔╝
// ██║   ██║██║   ██║██║███╗██║██╔══██║  ╚██╔╝
// ╚██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║   ██║
//  ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
//
// map_screen.dart - Pantalla de mapa con OpenStreetMap
// Versión: 2.0.0 | Última actualización: 19-01-2026
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  LatLng _currentLocation =
      const LatLng(18.17678, -93.06376); // Jalpa de Méndez
  double _zoom = 15;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Simular carga de tiles
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _centerMap(LatLng location) {
    _mapController.move(location, _zoom);
    setState(() {
      _currentLocation = location;
    });
  }

  void _zoomIn() {
    if (_zoom < 18) {
      _zoom += 1;
      _mapController.move(_currentLocation, _zoom);
      setState(() {});
    }
  }

  void _zoomOut() {
    if (_zoom > 2) {
      _zoom -= 1;
      _mapController.move(_currentLocation, _zoom);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: isTablet
          ? null
          : AppBar(
              title: const Text(
                'Mapa',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              elevation: 0.8,
              backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black,
            ),
      body: Stack(
        children: [
          // Mapa principal
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: _zoom,
              minZoom: 2,
              maxZoom: 18,
              keepAlive: true,
            ),
            children: [
              // Capa de tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.goway_user',
                maxZoom: 18,
                minZoom: 2,
                retinaMode: true,
                tileProvider: NetworkTileProvider(),
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
                wmsOptions: null,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue[700],
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Loading indicator
          if (_isLoading)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const CircularProgressIndicator(),
              ),
            ),

          // Controles de zoom
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
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

          // Panel inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lat: ${_currentLocation.latitude.toStringAsFixed(4)}, Lon: ${_currentLocation.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _centerMap(const LatLng(18.17678, -93.06376));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Mi Ubicación',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
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
}
