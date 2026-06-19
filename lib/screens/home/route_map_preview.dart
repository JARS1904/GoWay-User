import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class RouteMapPreview extends StatefulWidget {
  final List<dynamic> paradasRuta;
  final bool isDark;
  final String? paradaEmbarque;
  final String? paradaBajada;

  const RouteMapPreview({
    super.key,
    required this.paradasRuta,
    required this.isDark,
    this.paradaEmbarque,
    this.paradaBajada,
  });

  @override
  State<RouteMapPreview> createState() => _RouteMapPreviewState();
}

class _RouteMapPreviewState extends State<RouteMapPreview> {
  bool _darkMapEnabled = false;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initLocation();
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
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> paradasActivas = _getParadasFiltradas();
    if (paradasActivas.isEmpty) return const SizedBox.shrink();

    List<LatLng> points = [];
    List<Marker> markers = [];

    for (int i = 0; i < paradasActivas.length; i++) {
      final parada = paradasActivas[i];
      final latStr = parada['latitud'];
      final lngStr = parada['longitud'];

      if (latStr != null && lngStr != null) {
        final lat = double.tryParse(latStr.toString());
        final lng = double.tryParse(lngStr.toString());

        if (lat != null && lng != null) {
          final point = LatLng(lat, lng);
          points.add(point);

          final isStart = i == 0;
          final isEnd = i == paradasActivas.length - 1;

          Color? markerColor;
          String iconPath;

          if (isStart) {
            markerColor = Colors.green[600];
            iconPath = 'lib/assets/icons/icons8-marcador-filled.png';
          } else if (isEnd) {
            markerColor = Colors.red[600];
            iconPath = 'lib/assets/icons/icons8-marcador-filled.png';
          } else {
            markerColor = null; // No color override for the bus stop icon
            iconPath = 'lib/assets/icons/icons8-parada-autobus.png';
          }

          markers.add(
            Marker(
              point: point,
              width: 40,
              height: 40,
              child: Tooltip(
                message: parada['nombre'] ?? 'Parada',
                triggerMode: TooltipTriggerMode.tap,
                preferBelow: false,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey[800] : Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 30,
                    height: 30,
                    color: markerColor,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
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
      );
      points.add(_currentLocation!);
    }

    if (points.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paradas de la ruta:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 250,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: widget.isDark
                ? null
                : Border.all(color: Colors.grey[200]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(40.0),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _darkMapEnabled
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.goway_user',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.black87 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.fullscreen,
                        color: widget.isDark ? Colors.white : Colors.black87),
                    onPressed: () {
                      _showFullScreenMap(
                          context, points, markers, _darkMapEnabled);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullScreenMap(BuildContext context, List<LatLng> points,
      List<Marker> markers, bool darkMapEnabled) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          backgroundColor:
              widget.isDark ? const Color(0xFF121212) : Colors.grey[50],
          elevation: 0,
          foregroundColor: widget.isDark ? Colors.white : Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Paradas de la ruta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : Colors.black,
            ),
          ),
          iconTheme:
              IconThemeData(color: widget.isDark ? Colors.white : Colors.black),
        ),
        body: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(points),
              padding: const EdgeInsets.all(40.0),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: darkMapEnabled
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.goway_user',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    ));
  }

  List<dynamic> _getParadasFiltradas() {
    final paradas = widget.paradasRuta;
    if (widget.paradaEmbarque != null && widget.paradaBajada != null) {
      int startIndex =
          paradas.indexWhere((p) => p['nombre'] == widget.paradaEmbarque);
      int endIndex =
          paradas.indexWhere((p) => p['nombre'] == widget.paradaBajada);

      if (startIndex != -1 && endIndex != -1) {
        if (startIndex <= endIndex) {
          return paradas.sublist(startIndex, endIndex + 1);
        } else {
          return paradas.sublist(endIndex, startIndex + 1).reversed.toList();
        }
      }
    }
    return paradas;
  }
}
