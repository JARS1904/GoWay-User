import 'package:flutter/material.dart';

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
  // Datos de ejemplo - rutas favoritas del usuario
  final List<Map<String, String>> _favoriteRoutes = [
    {
      'origin': 'Nacajuca',
      'destination': 'Cunduacán',
      'time': '45 min',
      'distance': '32 km',
    },
    {
      'origin': 'Centro',
      'destination': 'Terminal',
      'time': '20 min',
      'distance': '15 km',
    },
    {
      'origin': 'Parque Tabasco',
      'destination': 'Hospital Regional',
      'time': '35 min',
      'distance': '25 km',
    },
    {
      'origin': 'UJAT',
      'destination': 'Mercado Viejo',
      'time': '55 min',
      'distance': '40 km',
    },
    {
      'origin': 'Aeropuerto',
      'destination': 'Centro Histórico',
      'time': '30 min',
      'distance': '22 km',
    },
  ];

  /// Determina si el dispositivo es una tablet
  bool get _isTablet {
    return MediaQuery.of(context).size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      Map<String, String> route, bool isDark, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: InkWell(
        onTap: () {
          // TODO: Navegar a pantalla de selección de ruta
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${route['origin']} → ${route['destination']}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con origen y destino
              Row(
                children: [
                  // Indicador de favorito
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route['origin']} → ${route['destination']}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Icono de favorito
                  IconButton(
                    icon: const Icon(Icons.favorite),
                    color: Colors.redAccent,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Removido de favoritos'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Información de tiempo y distancia
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          route['time']!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          route['distance']!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Botón de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Iniciar viaje con esta ruta
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Ver Ruta'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
