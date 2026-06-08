// route_selection_screen.dart - Pantalla de selección de rutas
// Versión: 2.1.0 | Última actualización: 03-05-2026

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:goway_user/services/api_service.dart';
import 'package:goway_user/screens/home/notifications_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goway_user/services/audio_service.dart';
import 'package:marquee/marquee.dart';

// ── Horarios: deduplicación y badge de estado (API routes / favorites) ─────

String scheduleUniqueKey(Map<String, dynamic> schedule) {
  final id = schedule['id_horario'];
  if (id != null && id.toString().trim().isNotEmpty) {
    return id.toString();
  }
  final tipoDia = schedule['tipo_dia'] ?? schedule['dia_semana'];
  return '${tipoDia ?? ''}-${schedule['hora_salida'] ?? ''}-${schedule['hora_llegada'] ?? ''}';
}

/// Texto amigable para el usuario (la BD puede enviar `en_ruta`, etc.).
String scheduleEstadoDisplayLabel(Map<String, dynamic> horario) {
  final raw = horario['estado'];
  if (raw == null || raw.toString().trim().isEmpty) {
    return 'Sin asignación';
  }
  final t = raw.toString().trim();
  final k = t
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_');

  if (const {'programado', 'programada', 'scheduled'}.contains(k)) {
    return 'Programado';
  }
  if (const {'en_ruta', 'enruta', 'in_route', 'on_route'}.contains(k)) {
    return 'En Ruta';
  }
  if (const {'completado', 'completa', 'completed', 'finalizado', 'finalizada'}
      .contains(k)) {
    return 'Completado';
  }
  if (const {'cancelado', 'cancelada', 'canceled', 'cancelled'}.contains(k)) {
    return 'Cancelado';
  }
  if (const {'retrasado', 'retrasada', 'delayed', 'delay'}.contains(k)) {
    return 'Retrasado';
  }
  if (const {'sin_asignacion', 'sin_asignar', 'unassigned'}.contains(k)) {
    return 'Sin asignación';
  }

  return _titleCaseFromSnakeOrPlain(t);
}

String _titleCaseFromSnakeOrPlain(String t) {
  if (t.contains('_')) {
    return t
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
  if (t.length == 1) {
    return t.toUpperCase();
  }
  return '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
}

/// Colores de la cápsula de estado (fondo / texto).
({Color background, Color foreground}) scheduleEstadoBadgeColors(
    String displayLabel,
    {bool isDark = false}) {
  switch (displayLabel) {
    case 'Sin asignación':
      return (
        background: Colors.grey.withOpacity(0.12),
        foreground: isDark ? Colors.grey[300]! : Colors.grey[700]!,
      );
    case 'Programado':
      return (
        background: Colors.grey.withOpacity(0.12),
        foreground: isDark ? Colors.grey[300]! : Colors.grey[700]!,
      );
    case 'En Ruta':
      return (
        background: Colors.blue.withOpacity(0.12),
        foreground: isDark ? Colors.blue[300]! : Colors.blue[800]!,
      );
    case 'Retrasado':
      return (
        background: Colors.amber.withOpacity(0.12),
        foreground: isDark ? Colors.amber[300]! : Colors.amber[800]!,
      );
    case 'Cancelado':
      return (
        background: Colors.red.withOpacity(0.12),
        foreground: isDark ? Colors.red[300]! : Colors.red[800]!,
      );
    case 'Completado':
      return (
        background: Colors.green.withOpacity(0.12),
        foreground: isDark ? Colors.green[300]! : Colors.green[800]!,
      );
    default:
      return (
        background: Colors.grey.withOpacity(0.12),
        foreground: isDark ? Colors.grey[300]! : Colors.grey[700]!,
      );
  }
}

/// Cápsula de estado de asignación (estilo tipo de día).
class EstadoAsignacionCapsule extends StatelessWidget {
  final String displayLabel;
  final bool isDark;

  const EstadoAsignacionCapsule({
    super.key,
    required this.displayLabel,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = scheduleEstadoBadgeColors(displayLabel, isDark: isDark);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.foreground,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET: Línea de tiempo de paradas con puntos circulares
// =============================================================================

class StopsTimeline extends StatelessWidget {
  final List<dynamic> stops;
  final Color lineColor;
  final bool isDark;
  final String? highlightStart;
  final String? highlightEnd;

  const StopsTimeline({
    super.key,
    required this.stops,
    required this.lineColor,
    required this.isDark,
    this.highlightStart,
    this.highlightEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    List<dynamic> displayStops = List.from(stops);
    int startIndex = 0;
    int endIndex = stops.length - 1;

    if (highlightStart != null && highlightEnd != null) {
      startIndex = stops.indexWhere((stop) {
        final nombre = stop['nombre']?.toString() ?? stop.toString();
        return nombre == highlightStart;
      });
      endIndex = stops.indexWhere((stop) {
        final nombre = stop['nombre']?.toString() ?? stop.toString();
        return nombre == highlightEnd;
      });

      if (startIndex != -1 && endIndex != -1 && startIndex <= endIndex) {
        displayStops = stops.sublist(startIndex, endIndex + 1);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: displayStops.asMap().entries.map((entry) {
        final idx = entry.key;
        final stop = entry.value;
        final isFirst = idx == 0;
        final isLast = idx == displayStops.length - 1;
        final stopName = stop['nombre']?.toString() ?? stop.toString();
        final minutes = stop['minutos_desde_origen'];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isFirst ||
                      (highlightStart != null && highlightEnd != null))
                    Container(
                        width: 5, height: 22, color: lineColor.withOpacity(0.4))
                  else
                    const SizedBox(height: 14),
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst || isLast
                          ? lineColor
                          : (isDark ? Colors.white : Colors.white),
                      border: Border.all(color: lineColor, width: 2),
                    ),
                  ),
                  if (!isLast ||
                      (highlightStart != null && highlightEnd != null))
                    Container(
                        width: 5, height: 22, color: lineColor.withOpacity(0.4))
                  else
                    const SizedBox(height: 14),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(stopName,
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87)),
                    if (minutes != null && minutes > 0)
                      Text('+$minutes min',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// =============================================================================
// ROUTE SELECTION SCREEN
// =============================================================================

class RouteSelectionScreen extends StatefulWidget {
  final String? userPhotoUrl;
  final String? userName;

  const RouteSelectionScreen({super.key, this.userPhotoUrl, this.userName});

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
  String? _userPhotoUrl;
  Map<String, dynamic>? _selectedRoute;
  Set<String> _favoriteRouteIds = {};
  int _unreadNotifications = 0;
  bool _initialFetchDone = false;
  Timer? _notificationTimer;
  bool _photoLoadError = false;
  bool _hideUnassignedSchedules = false;
  int _currentSchedulePage = 0;
  final int _schedulesPerPage = 5;
  final GlobalKey _schedulesTitleKey = GlobalKey();

  void _scrollToSchedules() {
    if (_schedulesTitleKey.currentContext != null) {
      Scrollable.ensureVisible(
        _schedulesTitleKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _userPhotoUrl = widget.userPhotoUrl;
    WidgetsBinding.instance.addObserver(this);
    _initializeUserId();
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) _fetchUnreadNotificationsCount();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadFavorites();
      _fetchUnreadNotificationsCount();
      _loadPreferences();
    }
  }

  void refresh() {
    _initializeUserId();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hideUnassignedSchedules =
            prefs.getBool('hideUnassignedSchedules') ?? false;
      });
    }
  }

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';
    final userName =
        prefs.getString('userName') ?? widget.userName ?? 'Usuario';
    final userPhotoUrl = prefs.getString('userPhotoUrl') ?? widget.userPhotoUrl;
    if (mounted) {
      setState(() {
        _userId = userId;
        _userName = userName;
        if (_userPhotoUrl != userPhotoUrl) {
          _userPhotoUrl = userPhotoUrl;
          _photoLoadError = false;
        }
      });
    }
    _loadFavorites();
    _fetchLocations();
    _fetchUnreadNotificationsCount();
    _loadPreferences();
  }

  Future<void> _fetchUnreadNotificationsCount() async {
    try {
      final url = Uri.parse(
          '${ApiService.notificationsUrl}?action=get_notifications&id_usuario=$_userId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['unread_count'] != null &&
            mounted) {
          int newCount = int.tryParse(data['unread_count'].toString()) ?? 0;
          if (_initialFetchDone && newCount > _unreadNotifications) {
            AudioService.instance.playNotificationSound();
          }
          _initialFetchDone = true;
          setState(() {
            _unreadNotifications = newCount;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch notifications: $e');
    }
  }

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
        if (mounted) setState(() => _favoriteRouteIds = favoriteIds);
      }
    } catch (e) {
      debugPrint('Error al cargar favoritos: $e');
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final url = Uri.parse('${ApiService.routesUrl}?action=locations');
      final response = await http.get(url, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is List && mounted) {
          setState(() => _locations = data.cast<String>());
          return;
        } else if (data is Map && data.containsKey('error')) {
          throw Exception(data['error']);
        }
        throw Exception('Formato de respuesta no válido');
      } else {
        throw Exception('Error HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al cargar ubicaciones: $e');
      _showError('No se pudieron cargar las ubicaciones. Intenta nuevamente.');
      Future.delayed(const Duration(seconds: 5), _fetchLocations);
    }
  }

  Future<void> _searchRoutes() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_origin == null || _destination == null) return;

    setState(() {
      _loading = true;
      _routes = [];
      _selectedRoute = null;
      _currentSchedulePage = 0;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiService.routesUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'search_routes',
          'origin': _origin,
          'destination': _destination
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData is List) {
          final processedRoutes =
              _processRoutes(responseData.cast<Map<String, dynamic>>());
          if (mounted) setState(() => _routes = processedRoutes);
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
      if (mounted) setState(() => _loading = false);
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
                  scheduleUniqueKey(Map<String, dynamic>.from(schedule as Map));
              map[key] = schedule;
              return map;
            })
            .values
            .toList();
        existingRoute['horarios'] = combinedSchedules;
      } else {
        uniqueRoutes[routeId] = {...route};
      }
    }
    return uniqueRoutes.values.toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)))
        ]),
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
      _currentSchedulePage = 0;
    });
  }

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  /// Avatar de usuario (con borde)
  Widget _buildAppBarAvatar() {
    final hasPhoto =
        _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty && !_photoLoadError;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              width: 2.0),
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blueAccent[700],
          backgroundImage: hasPhoto
              ? NetworkImage(ApiService.buildPhotoUrl(_userPhotoUrl)!)
              : null,
          onBackgroundImageError: hasPhoto
              ? (_, __) => setState(() => _photoLoadError = true)
              : null,
          child: !hasPhoto
              ? Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 28),
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationsScreen()));
              _fetchUnreadNotificationsCount();
            },
          ),
          if (_unreadNotifications > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10)),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _isTablet ? _buildTabletLayout() : _buildMobileLayout();

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppBarAvatar(),
            const SizedBox(width: 8),
            const Text('GoWay', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [_buildNotificationIcon()],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $_userName 👋',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 4),
              Text('¿A dónde quieres ir?',
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600])),
              const SizedBox(height: 20),
              // Selector de punto de origen
              DropdownMenu<String>(
                requestFocusOnTap: true,
                expandedInsets: EdgeInsets.zero,
                menuHeight: 300,
                initialSelection: _origin,
                label: const Text('Seleccione el origen'),
                leadingIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Image.asset(
                    'lib/assets/icons/icons8-marcador.png',
                    width: 20,
                    height: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  constraints: const BoxConstraints(maxHeight: 48),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide:
                        BorderSide(color: Colors.blueAccent[700]!, width: 1.8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(
                      isDark ? const Color(0xFF1E1E1E) : Colors.grey[50]),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
                  elevation: const WidgetStatePropertyAll(8),
                ),
                dropdownMenuEntries: _locations
                    .map((location) => DropdownMenuEntry(
                          value: location,
                          label: location,
                          style: MenuItemButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white : Colors.black87,
                            textStyle: const TextStyle(fontSize: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ))
                    .toList(),
                onSelected: (newValue) => setState(() {
                  _origin = newValue;
                  _routes = [];
                  _selectedRoute = null;
                  _currentSchedulePage = 0;
                }),
              ),
              const SizedBox(height: 16),
              // Selector de punto de destino
              DropdownMenu<String>(
                requestFocusOnTap: true,
                expandedInsets: EdgeInsets.zero,
                menuHeight: 300,
                initialSelection: _destination,
                label: const Text('Seleccione el destino'),
                leadingIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Image.asset(
                    'lib/assets/icons/icons8-marcador.png',
                    width: 20,
                    height: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  isDense: true,
                  constraints: const BoxConstraints(maxHeight: 48),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    borderSide:
                        BorderSide(color: Colors.blueAccent[700]!, width: 1.8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(
                      isDark ? const Color(0xFF1E1E1E) : Colors.grey[50]),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
                  elevation: const WidgetStatePropertyAll(8),
                ),
                dropdownMenuEntries: _locations
                    .map((location) => DropdownMenuEntry(
                          value: location,
                          label: location,
                          style: MenuItemButton.styleFrom(
                            foregroundColor:
                                isDark ? Colors.white : Colors.black87,
                            textStyle: const TextStyle(fontSize: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ))
                    .toList(),
                onSelected: (newValue) => setState(() {
                  _destination = newValue;
                  _routes = [];
                  _selectedRoute = null;
                  _currentSchedulePage = 0;
                }),
              ),
              const SizedBox(height: 24),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    icon: _loading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.search_rounded, size: 20),
                    label: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Buscar', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Divider(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      thickness: 1.5)),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_routes.isNotEmpty)
                Expanded(
                    child: ListView.builder(
                        itemCount: _routes.length,
                        itemBuilder: (context, index) =>
                            _buildRouteCard(_routes[index])))
              else if (_origin != null && _destination != null && !_loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.only(
                            top: 16, left: 30, bottom: 16, right: 30),
                        child: Text(
                            'No se encontraron rutas para esta combinación',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppBarAvatar(),
            const SizedBox(width: 8),
            const Text('GoWay', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [_buildNotificationIcon()],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hola, $_userName 👋',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 4),
                    Text('¿A dónde quieres ir?',
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[600])),
                    const SizedBox(height: 20),
                    _buildDropdown(
                        'Seleccione el origen',
                        _origin,
                        (v) => setState(() {
                              _origin = v;
                              _routes = [];
                              _selectedRoute = null;
                              _currentSchedulePage = 0;
                            }),
                        isDark),
                    const SizedBox(height: 16),
                    _buildDropdown(
                        'Seleccione el destino',
                        _destination,
                        (v) => setState(() {
                              _destination = v;
                              _routes = [];
                              _selectedRoute = null;
                              _currentSchedulePage = 0;
                            }),
                        isDark),
                    const SizedBox(height: 24),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                          icon: _loading
                              ? const SizedBox.shrink()
                              : const Icon(Icons.search_rounded, size: 20),
                          label: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Buscar',
                                  style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Divider(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            thickness: 1.5)),
                    const SizedBox(height: 24),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else if (_routes.isNotEmpty)
                      Expanded(
                          child: ListView.builder(
                              itemCount: _routes.length,
                              itemBuilder: (context, index) => _buildRouteCard(
                                  _routes[index],
                                  forTablet: true)))
                    else if (_origin != null &&
                        _destination != null &&
                        !_loading)
                      const Center(
                          child: Text(
                              'No se encontraron rutas para esta combinación')),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: _selectedRoute != null
                  ? _buildRouteDetails(_selectedRoute!)
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('lib/assets/images/logo_sin_nombre.png',
                              width: 60, height: 60),
                          const SizedBox(height: 16),
                          const Text(
                              'Selecciona una ruta para ver los detalles',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label, String? value, Function(String?) onChanged, bool isDark) {
    return DropdownMenu<String>(
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 300,
      initialSelection: value,
      label: Text(label),
      inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          constraints: const BoxConstraints(maxHeight: 48),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16)),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
            isDark ? const Color(0xFF1E1E1E) : Colors.grey[50]),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        elevation: const WidgetStatePropertyAll(8),
      ),
      dropdownMenuEntries: _locations
          .map((location) => DropdownMenuEntry(
              value: location,
              label: location,
              style: MenuItemButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black87,
                textStyle: const TextStyle(fontSize: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              )))
          .toList(),
      onSelected: onChanged,
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route, {bool forTablet = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var uniqueSchedules = (route['horarios'] as List)
        .fold<Map<String, dynamic>>({}, (map, schedule) {
          final key =
              scheduleUniqueKey(Map<String, dynamic>.from(schedule as Map));
          map[key] = schedule;
          return map;
        })
        .values
        .toList();

    if (_hideUnassignedSchedules) {
      uniqueSchedules = uniqueSchedules.where((s) {
        return scheduleEstadoDisplayLabel(
                Map<String, dynamic>.from(s as Map)) !=
            'Sin asignación';
      }).toList();
    }

    return _PressScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              isDark ? null : Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
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
                          route: {...route, 'horarios': uniqueSchedules})));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header con padding ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.directions_bus_rounded,
                            color: Colors.blueAccent[700], size: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(route['empresa_nombre'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: Colors.blue),
                              const SizedBox(width: 2),
                              Flexible(
                                  child: Text(route['origen'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward,
                                  size: 12,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600]),
                              const SizedBox(width: 4),
                              const Icon(Icons.location_on_rounded,
                                  size: 13, color: Colors.red),
                              const SizedBox(width: 2),
                              Flexible(
                                  child: Text(route['destino'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          if (route['es_tramo'] == 1) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.content_cut_rounded,
                                            size: 12,
                                            color: isDark
                                                ? Colors.orange[300]
                                                : Colors.orange[800]),
                                        const SizedBox(width: 4),
                                        Text('Tramo parcial',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? Colors.orange[300]
                                                    : Colors.orange[800])),
                                      ],
                                    )),
                                const SizedBox(width: 6),
                                Icon(Icons.directions_walk_rounded,
                                    size: 12,
                                    color: isDark
                                        ? Colors.orange[300]
                                        : Colors.orange[700]),
                                const SizedBox(width: 2),
                                Flexible(
                                    child: SizedBox(
                                        height: 15,
                                        child: Marquee(
                                          text:
                                              '${route['parada_embarque'] ?? '-'}   ➔   ${route['parada_bajada'] ?? '-'}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark
                                                  ? Colors.orange[300]
                                                  : Colors.orange[800]),
                                          scrollAxis: Axis.horizontal,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          blankSpace: 40.0,
                                          velocity: 30.0,
                                          pauseAfterRound:
                                              const Duration(seconds: 2),
                                          startPadding: 0.0,
                                          accelerationDuration:
                                              const Duration(milliseconds: 500),
                                          accelerationCurve: Curves.easeIn,
                                          decelerationDuration:
                                              const Duration(milliseconds: 500),
                                          decelerationCurve: Curves.easeOut,
                                        ))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // ── Horarios y acciones con padding ────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 20,
                              color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text('Horarios disponibles',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500))
                        ]),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('${uniqueSchedules.length}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.blueAccent[100]
                                        : Colors.blueAccent[700]))),
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
                            final isFavorite =
                                _favoriteRouteIds.contains(routeId);
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
                              if (response.statusCode == 200 && mounted) {
                                setState(() => isFavorite
                                    ? _favoriteRouteIds.remove(routeId)
                                    : _favoriteRouteIds.add(routeId));
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Row(children: [
                                    Icon(
                                        isFavorite
                                            ? Icons.heart_broken_rounded
                                            : Icons.favorite_rounded,
                                        color: Colors.white,
                                        size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                        isFavorite
                                            ? 'Removido de favoritos'
                                            : 'Agregado a favoritos',
                                        style: const TextStyle(
                                            color: Colors.white))
                                  ]),
                                  backgroundColor: isFavorite
                                      ? Colors.grey[700]
                                      : Colors.blueAccent[700],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  margin:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 96),
                                  duration: const Duration(seconds: 1),
                                ));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Row(children: [
                                          const Icon(Icons.error_rounded,
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                              child: Text('Error: $e',
                                                  style: const TextStyle(
                                                      color: Colors.white)))
                                        ]),
                                        backgroundColor: Colors.redAccent[700],
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        margin: const EdgeInsets.fromLTRB(
                                            16, 16, 16, 96),
                                        duration: const Duration(seconds: 3)));
                              }
                            }
                          },
                          child: Icon(
                              _favoriteRouteIds
                                      .contains(route['id_ruta']?.toString())
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: Colors.redAccent,
                              size: 26),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 20),
                              decoration: BoxDecoration(
                                  color: Colors.blueAccent[700],
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(20))),
                              child: const Text('Ver detalles',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteDetails(Map<String, dynamic> route) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var uniqueSchedules = (route['horarios'] as List)
        .fold<Map<String, dynamic>>({}, (map, schedule) {
          final key =
              scheduleUniqueKey(Map<String, dynamic>.from(schedule as Map));
          map[key] = schedule;
          return map;
        })
        .values
        .toList();

    if (_hideUnassignedSchedules) {
      uniqueSchedules = uniqueSchedules.where((s) {
        return scheduleEstadoDisplayLabel(
                Map<String, dynamic>.from(s as Map)) !=
            'Sin asignación';
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (route['es_tramo'] != 1) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(route['origen'] ?? '',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: 22,
                        color: isDark ? Colors.grey[500] : Colors.grey[600])),
                Text(route['destino'] ?? '',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (route['es_tramo'] == 1) ...[
            SizedBox(
              height: 32,
              child: Marquee(
                text:
                    '${route['parada_embarque'] ?? '-'}   ➔   ${route['parada_bajada'] ?? '-'}',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black),
                scrollAxis: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 60.0,
                velocity: 40.0,
                pauseAfterRound: const Duration(seconds: 2),
                startPadding: 0.0,
                accelerationDuration: const Duration(milliseconds: 500),
                accelerationCurve: Curves.easeIn,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.content_cut_rounded,
                        size: 14,
                        color:
                            isDark ? Colors.orange[300] : Colors.orange[800]),
                    const SizedBox(width: 4),
                    Text('Tramo parcial',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.orange[300]
                                : Colors.orange[800])),
                  ],
                )),
            const SizedBox(height: 6),
            Row(children: [
              Text('Ruta completa: ',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[500] : Colors.grey[600])),
              Flexible(
                  child: Text(route['origen'],
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[600]),
                      overflow: TextOverflow.ellipsis)),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500])),
              Flexible(
                  child: Text(route['destino'],
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[600]),
                      overflow: TextOverflow.ellipsis))
            ]),
          ],
          const SizedBox(height: 32),
          Container(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isDark
                    ? null
                    : Border.all(color: Colors.grey[200]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Información de la empresa:',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.business_rounded, 'Nombre:',
                      route['empresa_nombre'],
                      isDark: isDark),
                  _buildInfoRow(Icons.phone_rounded, 'Teléfono:',
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
          ),
          const SizedBox(height: 32),
          Row(
            key: _schedulesTitleKey,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Horarios disponibles:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 20),
          // ── Horarios paginados ─────────────────────────────
          Builder(
            builder: (context) {
              final totalPages =
                  (uniqueSchedules.length / _schedulesPerPage).ceil();
              final startIndex = _currentSchedulePage * _schedulesPerPage;
              final endIndex = (startIndex + _schedulesPerPage)
                  .clamp(0, uniqueSchedules.length);
              final paginatedSchedules =
                  uniqueSchedules.sublist(startIndex, endIndex);

              return Column(
                children: [
                  Column(
                    children: paginatedSchedules
                        .asMap()
                        .entries
                        .map((entry) => _StaggeredItem(
                              key: ValueKey(
                                  '${_currentSchedulePage}_${entry.key}'),
                              index: entry.key,
                              pageKey: _currentSchedulePage,
                              child: _ScheduleCard(
                                  route: route,
                                  horario: entry.value,
                                  isDark: isDark),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  // ── Controles de paginación modernos ────────────
                  if (totalPages > 1)
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        border: isDark
                            ? null
                            : Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _currentSchedulePage > 0
                                ? () {
                                    setState(() => _currentSchedulePage--);
                                    _scrollToSchedules();
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _currentSchedulePage > 0
                                    ? Colors.blueAccent[700]
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 16,
                                color: _currentSchedulePage > 0
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            'Página ${_currentSchedulePage + 1} de $totalPages',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 20),
                          InkWell(
                            onTap: _currentSchedulePage < totalPages - 1
                                ? () {
                                    setState(() => _currentSchedulePage++);
                                    _scrollToSchedules();
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _currentSchedulePage < totalPages - 1
                                    ? Colors.blueAccent[700]
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: _currentSchedulePage < totalPages - 1
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value,
      {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[500] : Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(value ?? 'No especificado',
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          child: widget.child),
    );
  }
}

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late Map<String, dynamic> _currentRoute;
  int _currentSchedulePage = 0;
  final int _schedulesPerPage = 5;
  final GlobalKey _schedulesTitleKey = GlobalKey();
  bool _hideUnassignedSchedules = false;

  void _scrollToSchedules() {
    if (_schedulesTitleKey.currentContext != null) {
      Scrollable.ensureVisible(
        _schedulesTitleKey.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _currentRoute = Map<String, dynamic>.from(widget.route);
    _currentSchedulePage = 0;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hideUnassignedSchedules =
            prefs.getBool('hideUnassignedSchedules') ?? false;
      });
    }
  }

  Future<void> _refreshRouteData() async {
    bool updated = false;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '1';

    try {
      final origin = _currentRoute['origen_busqueda'] ??
          _currentRoute['origen'] ??
          _currentRoute['parada_embarque'] ??
          '';
      final destination = _currentRoute['destino_busqueda'] ??
          _currentRoute['destino'] ??
          _currentRoute['parada_bajada'] ??
          '';

      final response = await http
          .post(
            Uri.parse(ApiService.routesUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'action': 'search_routes',
              'origin': origin,
              'destination': destination
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // La API devuelve un array plano de rutas
        final List rutas = data is List ? data : (data['rutas'] as List? ?? []);
        final idRoute = _currentRoute['id_ruta']?.toString() ??
            _currentRoute['id']?.toString() ??
            '';

        final updatedRoute = rutas.cast<Map<String, dynamic>>().firstWhere(
              (r) =>
                  (r['id_ruta']?.toString() ?? r['id']?.toString() ?? '') ==
                  idRoute,
              orElse: () => <String, dynamic>{},
            );

        if (updatedRoute.isNotEmpty && mounted) {
          setState(() {
            _currentRoute = {
              ..._currentRoute,
              'horarios': updatedRoute['horarios'] ?? _currentRoute['horarios'],
              'paradas_ruta':
                  updatedRoute['paradas_ruta'] ?? _currentRoute['paradas_ruta'],
            };
          });
          updated = true;
        }
      }
    } catch (e) {
      debugPrint('Error search_routes: $e');
    }

    if (!updated) {
      try {
        final url =
            '${ApiService.favoritesUrl}?id_usuario=$userId&action=get_favorites';
        final response =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decodedResponse = json.decode(response.body);
          if (decodedResponse is List) {
            final idRoute = _currentRoute['id_ruta']?.toString() ??
                _currentRoute['id']?.toString() ??
                '';
            final updatedRoute = decodedResponse.firstWhere(
              (r) =>
                  (r['id_ruta']?.toString() ?? r['id']?.toString() ?? '') ==
                  idRoute,
              orElse: () => null,
            );

            if (updatedRoute != null && mounted) {
              setState(() {
                _currentRoute = {
                  ..._currentRoute,
                  'horarios':
                      updatedRoute['horarios'] ?? _currentRoute['horarios']
                };
              });
              updated = true;
            }
          }
        }
      } catch (e) {
        debugPrint('Error get_favorites: $e');
      }
    }

    if (!updated) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _currentRoute;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width > 600;
    var uniqueSchedules = (route['horarios'] as List? ?? [])
        .fold<Map<String, dynamic>>({}, (map, schedule) {
          final key =
              scheduleUniqueKey(Map<String, dynamic>.from(schedule as Map));
          map[key] = schedule;
          return map;
        })
        .values
        .toList();

    if (_hideUnassignedSchedules) {
      uniqueSchedules = uniqueSchedules.where((s) {
        return scheduleEstadoDisplayLabel(
                Map<String, dynamic>.from(s as Map)) !=
            'Sin asignación';
      }).toList();
    }

    return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
          elevation: 0,
          foregroundColor: isDark ? Colors.white : Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(route['empresa_nombre'],
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        ),
        body: RefreshIndicator(
          onRefresh: _refreshRouteData,
          color: isDark ? Colors.white : Colors.blueAccent[700],
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isTablet ? 800 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (route['es_tramo'] != 1) ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(route['origen'] ?? '',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black)),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded,
                                  size: 22,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600])),
                          Text(route['destino'] ?? '',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (route['es_tramo'] == 1) ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(route['parada_embarque'] ?? '-',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black)),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward_rounded,
                                  size: 22,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600])),
                          Text(route['parada_bajada'] ?? '-',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.content_cut_rounded,
                                  size: 14,
                                  color: isDark
                                      ? Colors.orange[300]
                                      : Colors.orange[800]),
                              const SizedBox(width: 4),
                              Text('Tramo parcial',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.orange[300]
                                          : Colors.orange[800])),
                            ],
                          )),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('Ruta completa: ',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600])),
                        Flexible(
                            child: Text(route['origen'],
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600]),
                                overflow: TextOverflow.ellipsis)),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.arrow_forward_rounded,
                                size: 14,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500])),
                        Flexible(
                            child: Text(route['destino'],
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[600]),
                                overflow: TextOverflow.ellipsis))
                      ]),
                    ],
                    const SizedBox(height: 32),
                    Container(
                      margin: EdgeInsets.zero,
                      decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isDark
                              ? null
                              : Border.all(
                                  color: Colors.grey[200]!, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.3 : 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Información de la empresa:',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black)),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.business_rounded, 'Nombre:',
                                route['empresa_nombre'],
                                isDark: isDark),
                            _buildInfoRow(Icons.phone_rounded, 'Teléfono:',
                                route['empresa_telefono'],
                                isDark: isDark),
                            _buildInfoRow(
                                Icons.location_on_rounded,
                                'Dirección:',
                                route['empresa_direccion'] ?? 'No especificada',
                                isDark: isDark),
                            _buildInfoRow(Icons.email_rounded, 'Email:',
                                route['empresa_email'] ?? 'No especificado',
                                isDark: isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('Horarios disponibles:',
                        key: _schedulesTitleKey,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) {
                        final totalPages =
                            (uniqueSchedules.length / _schedulesPerPage).ceil();
                        final startIndex =
                            _currentSchedulePage * _schedulesPerPage;
                        final endIndex = (startIndex + _schedulesPerPage)
                            .clamp(0, uniqueSchedules.length);
                        final paginatedSchedules =
                            uniqueSchedules.sublist(startIndex, endIndex);

                        return Column(
                          children: [
                            Column(
                              children: paginatedSchedules
                                  .asMap()
                                  .entries
                                  .map((entry) => _StaggeredItem(
                                        key: ValueKey(
                                            '${_currentSchedulePage}_${entry.key}'),
                                        index: entry.key,
                                        pageKey: _currentSchedulePage,
                                        child: _ScheduleCard(
                                            route: route,
                                            horario: entry.value,
                                            isDark: isDark),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                            if (totalPages > 1)
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A2A2A)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(30),
                                  border: isDark
                                      ? null
                                      : Border.all(
                                          color: Colors.grey[300]!, width: 1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: _currentSchedulePage > 0
                                          ? () {
                                              setState(
                                                  () => _currentSchedulePage--);
                                              _scrollToSchedules();
                                            }
                                          : null,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _currentSchedulePage > 0
                                              ? Colors.blueAccent[700]
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.arrow_back_ios_rounded,
                                          size: 16,
                                          color: _currentSchedulePage > 0
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.grey[600]
                                                  : Colors.grey[400]),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Text(
                                      'Página ${_currentSchedulePage + 1} de $totalPages',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    InkWell(
                                      onTap: _currentSchedulePage <
                                              totalPages - 1
                                          ? () {
                                              setState(
                                                  () => _currentSchedulePage++);
                                              _scrollToSchedules();
                                            }
                                          : null,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _currentSchedulePage <
                                                  totalPages - 1
                                              ? Colors.blueAccent[700]
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: _currentSchedulePage <
                                                  totalPages - 1
                                              ? Colors.white
                                              : (isDark
                                                  ? Colors.grey[600]
                                                  : Colors.grey[400]),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget _buildInfoRow(IconData icon, String label, String? value,
      {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[500] : Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(value ?? 'No especificado',
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatefulWidget {
  final Map<String, dynamic> route;
  final Map<String, dynamic> horario;
  final bool isDark;

  const _ScheduleCard(
      {required this.route, required this.horario, required this.isDark});

  @override
  State<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<_ScheduleCard> {
  bool _expanded = false;

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value, bool isDark,
      {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20,
              color:
                  iconColor ?? (isDark ? Colors.grey[500] : Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 13)),
                Text(value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeInfoRow(BuildContext context, IconData icon, String label,
      dynamic disponibles, dynamic capacidad, bool isDark,
      {Color? iconColor}) {
    int disp = int.tryParse(disponibles?.toString() ?? '') ?? -1;
    int cap = int.tryParse(capacidad?.toString() ?? '') ?? 0;

    if (cap <= 0 || disp < 0) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: iconColor ??
                        (isDark ? Colors.grey[500] : Colors.grey[600])),
                const SizedBox(width: 8),
                Text(label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${cap > 0 ? cap : 'N/A'} pasajeros (Capacidad total)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white : Colors.black, fontSize: 14)),
          ],
        ),
      );
    }

    double ratio = disp / cap;
    Color progressColor;
    Color pillBgColor;
    Color pillTextColor;
    String statusText;

    if (ratio > 0.5) {
      progressColor = const Color(0xFF689F38);
      pillBgColor = const Color(0xFFE8F5E9);
      pillTextColor = const Color(0xFF2E7D32);
      statusText = 'Disponible';
    } else if (ratio > 0.15) {
      progressColor = const Color(0xFFFBC02D);
      pillBgColor = const Color(0xFFFFF9C4);
      pillTextColor = const Color(0xFFF57F17);
      statusText = 'Pocos lugares';
    } else if (ratio > 0) {
      progressColor = const Color(0xFFE64A19);
      pillBgColor = const Color(0xFFFBE9E7);
      pillTextColor = const Color(0xFFD84315);
      statusText = 'Casi agotado';
    } else {
      progressColor = Colors.grey[400]!;
      pillBgColor = Colors.grey[300]!;
      pillTextColor = Colors.grey[700]!;
      statusText = 'Agotado';
    }

    if (isDark) {
      if (ratio > 0.5) {
        pillBgColor = const Color(0xFFE8F5E9).withOpacity(0.15);
        pillTextColor = const Color(0xFFA5D6A7);
      } else if (ratio > 0.15) {
        pillBgColor = const Color(0xFFFFF9C4).withOpacity(0.15);
        pillTextColor = const Color(0xFFFFF59D);
      } else if (ratio > 0) {
        pillBgColor = const Color(0xFFFBE9E7).withOpacity(0.15);
        pillTextColor = const Color(0xFFFFAB91);
      } else {
        pillBgColor = Colors.grey[800]!;
        pillTextColor = Colors.grey[400]!;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: iconColor ??
                      (isDark ? Colors.grey[500] : Colors.grey[600])),
              const SizedBox(width: 8),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.grey[800]! : Colors.grey[300]!),
                    ),
                    CircularProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$disp',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                  height: 1.0)),
                          Text('de $cap',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  height: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                        text: TextSpan(
                            style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[800]),
                            children: [
                          TextSpan(
                              text: '$disp',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ' de $cap lugares disponibles')
                        ])),
                    const SizedBox(height: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: pillBgColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(statusText,
                            style: TextStyle(
                                color: pillTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns true if the schedule is in a terminal state (no longer available).
  bool _isDisabledState(String estadoDisplay) {
    return estadoDisplay == 'Completado' || estadoDisplay == 'Cancelado';
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final horario = widget.horario;
    final isDark = widget.isDark;

    final estadoDisplay = scheduleEstadoDisplayLabel(horario);
    final tipoDiaStr =
        (horario['tipo_dia'] ?? horario['dia_semana'] ?? '-').toString();
    final isDisabled = _isDisabledState(estadoDisplay);

    // Disabled appearance: muted background + reduced opacity
    final cardColor = isDisabled
        ? (isDark ? const Color(0xFF181818) : Colors.grey[100]!)
        : (isDark ? const Color(0xFF1E1E1E) : Colors.white);

    return Opacity(
      opacity: isDisabled ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? null
              : Border.all(
                  color: isDisabled ? Colors.grey[300]! : Colors.grey[200]!,
                  width: 1.5),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
        ),
        child: InkWell(
          // Disable tap entirely for completed/cancelled schedules
          onTap:
              isDisabled ? null : () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.calendar_month_rounded,
                            color: Colors.green[700], size: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(route['empresa_nombre'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 12, color: Colors.blue),
                              const SizedBox(width: 2),
                              Flexible(
                                  child: Text(route['origen'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward,
                                  size: 11,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[600]),
                              const SizedBox(width: 4),
                              const Icon(Icons.location_on_rounded,
                                  size: 12, color: Colors.red),
                              const SizedBox(width: 2),
                              Flexible(
                                  child: Text(route['destino'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: isDark
                                                  ? Colors.grey[500]
                                                  : Colors.grey[600],
                                              fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          EstadoAsignacionCapsule(
                              displayLabel: estadoDisplay, isDark: isDark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(tipoDiaStr,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.green[300]
                                        : Colors.green[800],
                                    letterSpacing: 0.3))),
                        const SizedBox(height: 6),
                        Icon(
                            isDisabled
                                ? Icons.lock_outline_rounded
                                : (_expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded),
                            size: 20,
                            color: isDisabled
                                ? (isDark ? Colors.grey[600] : Colors.grey[400])
                                : (isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Divider 1 — borde a borde ────────────────────────
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey[200],
              ),
              const SizedBox(height: 10),
              // ── Horas con padding ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: _infoRow(
                            context,
                            Icons.directions_bus_rounded,
                            route['es_tramo'] == 1 ? 'Abordaje' : 'Salida',
                            (route['es_tramo'] == 1 &&
                                    horario['hora_abordaje'] != null)
                                ? horario['hora_abordaje']
                                : (horario['hora_salida'] ?? '-'),
                            isDark,
                            iconColor: Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoRow(
                            context,
                            Icons.directions_bus_rounded,
                            route['es_tramo'] == 1 ? 'Bajada' : 'Llegada',
                            (route['es_tramo'] == 1 &&
                                    horario['hora_bajada'] != null)
                                ? horario['hora_bajada']
                                : (horario['hora_llegada'] ?? '-'),
                            isDark,
                            iconColor: Colors.redAccent)),
                  ],
                ),
              ),
              // ── Contenido expandible ──────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(
                                    context,
                                    Icons.refresh_rounded,
                                    'Frecuencia',
                                    horario['frecuencia']?.toString() ?? '-',
                                    isDark,
                                    iconColor: Colors.orange[700]),
                                if (route['es_tramo'] == 1) ...[
                                  const SizedBox(height: 6),
                                  _infoRow(
                                      context,
                                      Icons.schedule_rounded,
                                      'Salida de ruta',
                                      horario['hora_salida'] ?? '-',
                                      isDark,
                                      iconColor: Colors.grey[600]),
                                  const SizedBox(height: 6),
                                  _infoRow(
                                      context,
                                      Icons.schedule_rounded,
                                      'Llegada de ruta',
                                      horario['hora_llegada'] ?? '-',
                                      isDark,
                                      iconColor: Colors.grey[600]),
                                ],
                              ],
                            ),
                          ),
                          // ── Divider 2 — borde a borde ────────────
                          const SizedBox(height: 10),
                          Container(
                            height: 1,
                            color: isDark ? Colors.white12 : Colors.grey[200],
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(
                                    context,
                                    Icons.person_rounded,
                                    'Conductor',
                                    horario['conductor_nombre'] ?? 'N/A',
                                    isDark,
                                    iconColor: Colors.blue[800]),
                                const SizedBox(height: 6),
                                _infoRow(
                                    context,
                                    Icons.directions_bus_rounded,
                                    'Vehículo',
                                    horario['vehiculo_modelo'] ?? 'N/A',
                                    isDark,
                                    iconColor: Colors.blue[700]),
                                const SizedBox(height: 6),
                                _infoRow(
                                    context,
                                    Icons.confirmation_number_rounded,
                                    'Placa',
                                    horario['vehiculo_placa'] ?? 'N/A',
                                    isDark,
                                    iconColor: Colors.orange[800]),
                                const SizedBox(height: 6),
                                _badgeInfoRow(
                                    context,
                                    Icons.event_seat_rounded,
                                    'Disponibilidad de asientos',
                                    horario['asientos_disponibles'],
                                    horario['vehiculo_capacidad'],
                                    isDark,
                                    iconColor: const Color.fromARGB(
                                        255, 246, 186, 66)),
                              ],
                            ),
                          ),
                          if ((route['paradas_ruta'] as List?)?.isNotEmpty ==
                              true) ...[
                            // ── Divider 3 — borde a borde ──────────
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: isDark ? Colors.white12 : Colors.grey[200],
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.route_rounded,
                                        size: 20, color: Colors.amber.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Paradas',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                      color: isDark
                                                          ? Colors.grey[500]
                                                          : Colors.grey[600],
                                                      fontSize: 13)),
                                          const SizedBox(height: 8),
                                          StopsTimeline(
                                              stops: (route['paradas_ruta']
                                                  as List),
                                              lineColor: Colors.amber.shade700,
                                              isDark: isDark,
                                              highlightStart:
                                                  route['es_tramo'] == 1
                                                      ? route['parada_embarque']
                                                      : null,
                                              highlightEnd:
                                                  route['es_tramo'] == 1
                                                      ? route['parada_bajada']
                                                      : null),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else if ((route['paradas'] as List?)?.isNotEmpty ==
                              true) ...[
                            // ── Divider 4 — borde a borde ──────────
                            const SizedBox(height: 16),
                            Container(
                              height: 1,
                              color: isDark ? Colors.white12 : Colors.grey[200],
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.route_rounded,
                                        size: 20, color: Colors.amber.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Paradas',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                      color: isDark
                                                          ? Colors.grey[500]
                                                          : Colors.grey[600],
                                                      fontSize: 13)),
                                          const SizedBox(height: 8),
                                          StopsTimeline(
                                              stops: (route['paradas'] as List)
                                                  .map((p) => {'nombre': p})
                                                  .toList(),
                                              lineColor: Colors.amber.shade700,
                                              isDark: isDark,
                                              highlightStart:
                                                  route['es_tramo'] == 1
                                                      ? route['parada_embarque']
                                                      : null,
                                              highlightEnd:
                                                  route['es_tramo'] == 1
                                                      ? route['parada_bajada']
                                                      : null),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox(height: 16),
              ),
            ],
          ),
        ),
      ), // closes Container
    ); // closes Opacity
  }
}

class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final int pageKey;

  const _StaggeredItem({
    super.key,
    required this.child,
    required this.index,
    required this.pageKey,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
