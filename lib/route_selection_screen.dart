// route_selection_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  String? _origin;
  String? _destination;
  List<String> _locations = [];
  List<dynamic> _routes = [];
  bool _loading = false;
  final String _apiUrl = "http://192.168.30.101/GoWay/api/routes_api.php";

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    try {
      final url = Uri.parse(
          'http://192.168.30.101/GoWay/api/routes_api.php?action=locations');
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
          setState(() {
            _locations = data.cast<String>();
          });
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
      // Opcional: Recargar después de un tiempo
      Future.delayed(const Duration(seconds: 5), _fetchLocations);
    }
  }

  Future<void> _searchRoutes() async {
    if (_origin == null || _destination == null) return;

    setState(() {
      _loading = true;
      _routes = [];
    });

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'search_routes',
          'origin': _origin,
          'destination': _destination,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _routes = responseData;
        });
      } else {
        _showError(responseData['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      _showError('Error de conexión: ${e.toString()}');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: .8,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            // Logo de la aplicación
            Image.asset(
              'lib/assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            const Text(
              'GoWay',
              style: TextStyle(
                fontWeight: FontWeight.bold,
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
            const Text(
              '¿A dónde quieres ir?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                ), // Para ajustar el padding de las listas desplegables
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
                ), // Para ajustar el padding de las listas desplegables
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
              padding: EdgeInsets.symmetric(
                horizontal: 40, // Espacio horizontal para el separador
              ),
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

  Widget _buildRouteCard(Map<String, dynamic> route) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouteDetailsScreen(route: route),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route['empresa_nombre'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(route['origen']),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(route['destino']),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Horarios disponibles:'),
                  Text(
                    '${route['horarios'].length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent[700],
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                  child: Text(
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
        ),
      ),
    );
  }
}

class RouteDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        title: Text(
          route['empresa_nombre'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route['nombre'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${route['origen']} - ${route['destino']}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Información de la empresa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información de la empresa:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.business_rounded, 'Nombre:',
                      route['empresa_nombre']),
                  _buildInfoRow(Icons.phone_android_rounded, 'Teléfono:',
                      route['empresa_telefono']),
                  _buildInfoRow(Icons.location_on_rounded, 'Dirección:',
                      route['empresa_direccion']),
                  _buildInfoRow(
                      Icons.email_rounded, 'Email:', route['empresa_email']),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Horarios disponibles (con la corrección específica)
            const Text(
              'Horarios disponibles:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...route['horarios'].map<Widget>((horario) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Fila superior: Empresa y Día
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            route['empresa_nombre'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
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

                      // Ruta: Origen -> Destino
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

                      // Fila de iconos y etiquetas
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Icono de salida + texto
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_bus,
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
                            // Icono de llegada + texto
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

                      // Fila de horas
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

                      // Frecuencia
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
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  _showReservationDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Reservar viaje'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares para construir filas de información
  Widget _buildInfoRow(IconData icon, String label, String? value) {
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'No especificado',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReservationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar reservación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Empresa: ${route['empresa_nombre']}'),
              Text('Ruta: ${route['origen']} - ${route['destino']}'),
              const SizedBox(height: 16),
              const Text('¿Deseas reservar este viaje?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reservación exitosa'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
