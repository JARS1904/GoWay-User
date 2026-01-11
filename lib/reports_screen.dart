import 'package:flutter/material.dart';

/// Pantalla de Reportes de Incidencias
///
/// Muestra los reportes de incidencias creados por el usuario.
/// Permite crear y visualizar reportes de problemas en las rutas.
/// Diseño responsivo con soporte para móvil y tablet.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Datos de ejemplo - reportes del usuario
  final List<Map<String, dynamic>> _userReports = [
    {
      'title': 'Incidente: Avería',
      'status': 'En Proceso',
      'statusColor': Colors.blueAccent,
      'vehicle': 'ABC1234 - Mercedes-Benz O500',
      'driver': 'Andrea Torres Silva',
      'route': 'Nacajuca - Cunduacán',
      'dateTime': '9 ene 2026 10:03',
      'severity': 'alta',
      'description': 'Falla en la transmisión',
    },
    {
      'title': 'Incidente: Congestión de Tráfico',
      'status': 'Reportado',
      'statusColor': Colors.orangeAccent,
      'vehicle': 'XYZ9876 - Volvo FH16',
      'driver': 'Carlos Mendez López',
      'route': 'Centro - Terminal',
      'dateTime': '8 ene 2026 14:30',
      'severity': 'media',
      'description': 'Tráfico intenso en la avenida principal',
    },
    {
      'title': 'Incidente: Retraso',
      'status': 'Resuelto',
      'statusColor': Colors.greenAccent,
      'vehicle': 'DEF5432 - Scania K360',
      'driver': 'Juan Pérez García',
      'route': 'UJAT - Mercado Viejo',
      'dateTime': '7 ene 2026 11:15',
      'severity': 'baja',
      'description': 'Retraso por parada en taller',
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
        title: const Text('Reportes'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreateReportDialog,
            tooltip: 'Crear reporte',
          ),
        ],
      ),
      body: _userReports.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _userReports.length,
              itemBuilder: (context, index) {
                final report = _userReports[index];
                return _buildReportCard(report, isDark);
              },
            ),
    );
  }

  /// Layout para dispositivos tablet
  Widget _buildTabletLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showCreateReportDialog,
                icon: const Icon(Icons.add),
                label: const Text('Crear Reporte'),
              ),
            ),
          ),
        ],
      ),
      body: _userReports.isEmpty
          ? _buildEmptyState(isDark)
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _userReports.length,
                  itemBuilder: (context, index) {
                    final report = _userReports[index];
                    return _buildReportCard(report, isDark);
                  },
                ),
              ),
            ),
    );
  }

  /// Widget para la tarjeta de reporte (basada en la imagen proporcionada)
  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con título y estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['title'],
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gravedad: ${report['severity'].toString().toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getSeverityColor(report['severity']),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (report['statusColor'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report['status'],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: report['statusColor'],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Información del vehículo
              _buildInfoRow(
                icon: Icons.directions_car,
                label: 'Vehículo',
                value: report['vehicle'],
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              // Conductor
              _buildInfoRow(
                icon: Icons.person,
                label: 'Conductor',
                value: report['driver'],
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              // Ruta
              _buildInfoRow(
                icon: Icons.route,
                label: 'Ruta',
                value: report['route'],
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              // Fecha y hora
              _buildInfoRow(
                icon: Icons.schedule,
                label: 'Fecha y Hora',
                value: report['dateTime'],
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              // Descripción del problema
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 18,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report['description'],
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: Editar reporte
                    },
                    child: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Ver detalles completos
                    },
                    child: const Text('Detalles'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar información en filas
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Obtiene el color según la gravedad del reporte
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'alta':
        return Colors.redAccent;
      case 'media':
        return Colors.orangeAccent;
      case 'baja':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  /// Widget para mostrar cuando no hay reportes
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay reportes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Crea un reporte para informar sobre incidencias',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateReportDialog,
            icon: const Icon(Icons.add),
            label: const Text('Crear Reporte'),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo para crear un nuevo reporte
  void _showCreateReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Reporte'),
        content: const Text('Funcionalidad disponible próximamente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra los detalles completos del reporte
  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  report['title'],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Descripción completa:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  report['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
