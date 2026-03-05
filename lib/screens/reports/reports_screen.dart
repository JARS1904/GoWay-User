import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final List<Map<String, dynamic>> _userReports = [];
  String _userId = '';
  bool _loadingReports = false;

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  void refresh() => setState(() {});

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    if (_userId.isNotEmpty) await _loadReportsFromServer();
  }

  Future<void> _loadReportsFromServer() async {
    if (_userId.isEmpty) return;
    if (mounted) setState(() => _loadingReports = true);
    try {
      final uri = Uri.parse(ApiService.reportsUrl).replace(
        queryParameters: {'action': 'get_reports', 'id_usuario': _userId},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      // Respuesta no-JSON (HTML de error Apache, etc.)
      if (!response.body.trimLeft().startsWith('{')) {
        if (mounted) {
          setState(() => _loadingReports = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error HTTP ${response.statusCode}: respuesta inesperada del servidor'),
            backgroundColor: Colors.redAccent[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          ));
        }
        return;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['success'] == true) {
        final list = (decoded['reportes'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((r) => <String, dynamic>{
                  ...r,
                  'fecha_hora': r['fecha_incidente'] ?? r['fecha_hora'] ?? '-',
                })
            .toList();
        if (mounted) {
          setState(() {
            _userReports
              ..clear()
              ..addAll(list);
            _loadingReports = false;
          });
        }
      } else {
        // API devolvió error JSON (ej. 403 por rol incorrecto)
        if (mounted) {
          setState(() => _loadingReports = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error al cargar reportes: ${decoded['error'] ?? 'HTTP ${response.statusCode}'}'),
            backgroundColor: Colors.redAccent[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingReports = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.redAccent[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _isTablet ? _buildTabletLayout(isDark) : _buildMobileLayout(isDark);
  }

  Widget _buildMobileLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showCreateReportDialog,
            tooltip: 'Crear reporte',
          ),
        ],
      ),
      body: _loadingReports
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportsFromServer,
              child: _userReports.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _userReports.length,
                      itemBuilder: (context, index) =>
                          _buildReportCard(_userReports[index], isDark),
                    ),
            ),
    );
  }

  Widget _buildTabletLayout(bool isDark) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: _showCreateReportDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent[700],
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('+ Crear reporte',
                    style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
      body: _loadingReports
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportsFromServer,
              child: _userReports.isEmpty
                  ? _buildEmptyState(isDark)
                  : Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                          itemCount: _userReports.length,
                          itemBuilder: (context, index) =>
                              _buildReportCard(_userReports[index], isDark),
                        ),
                      ),
                    ),
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) {
    final severityColor =
        _getSeverityColor(report['gravedad'] as String? ?? '');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      elevation: isDark ? 0 : 1,
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        color: severityColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['tipo_incidente'] as String? ?? '-',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (report['gravedad'] as String? ?? '').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: severityColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.orange[200]!,
                      ),
                    ),
                    child: Text(
                      'Reportado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.orange[300] : Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                  height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
              const SizedBox(height: 10),
              _buildInfoRow(
                icon: Icons.directions_car_outlined,
                label: 'Vehiculo',
                value: report['vehiculo_placa'] as String? ?? '-',
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Conductor',
                value: report['conductor_nombre'] as String? ?? '-',
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                icon: Icons.route_outlined,
                label: 'Ruta',
                value: report['ruta_nombre'] != null
                    ? '${report['ruta_nombre']} (${report['origen']} -> ${report['destino']})'
                    : '-',
                isDark: isDark,
              ),
              const SizedBox(height: 6),
              _buildInfoRow(
                icon: Icons.schedule_outlined,
                label: 'Fecha y Hora',
                value: report['fecha_hora'] as String? ?? '-',
                isDark: isDark,
              ),
              if ((report['descripcion'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F1F) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_rounded,
                          size: 15,
                          color: isDark ? Colors.grey[400] : Colors.grey[500]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report['descripcion'] as String,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                    height: 1.4,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showReportDetails(report),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent[700],
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: const Text(
                      'Ver detalles',
                      style: TextStyle(fontSize: 12, color: Colors.white),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 15, color: isDark ? Colors.grey[400] : Colors.grey[600]),
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

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'alta':
        return Colors.redAccent;
      case 'critica':
        return Colors.deepOrange;
      case 'media':
        return Colors.orangeAccent;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.blueAccent.withOpacity(0.12)
                    : Colors.blueAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                size: 48,
                color: isDark ? Colors.blueAccent[100] : Colors.blueAccent[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin reportes aun',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra incidencias en las rutas para que el equipo pueda atenderlas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _showCreateReportDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[700],
                foregroundColor: Colors.white,
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('+ Crear reporte'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateReportDialog(
        onReportCreated: (_) => _loadReportsFromServer(),
      ),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  report['tipo_incidente'] as String? ?? '-',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getSeverityColor(report['gravedad'] as String? ?? '')
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (report['gravedad'] as String? ?? '').toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getSeverityColor(
                          report['gravedad'] as String? ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white12 : Colors.grey[200]),
                const SizedBox(height: 8),
                _buildDetailRow('Vehiculo',
                    report['vehiculo_placa'] as String? ?? '-', isDark),
                _buildDetailRow('Conductor',
                    report['conductor_nombre'] as String? ?? '-', isDark),
                if (report['ruta_nombre'] != null)
                  _buildDetailRow(
                    'Ruta',
                    '${report['ruta_nombre']} (${report['origen']} -> ${report['destino']})',
                    isDark,
                  ),
                _buildDetailRow('Fecha y Hora',
                    report['fecha_hora'] as String? ?? '-', isDark),
                const SizedBox(height: 12),
                Text(
                  'Descripcion',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  report['descripcion'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Dialogo para crear un nuevo reporte
// =============================================================================

class _CreateReportDialog extends StatefulWidget {
  final void Function(Map<String, dynamic> report) onReportCreated;

  const _CreateReportDialog({required this.onReportCreated});

  @override
  State<_CreateReportDialog> createState() => _CreateReportDialogState();
}

class _CreateReportDialogState extends State<_CreateReportDialog> {
  final _formKey = GlobalKey<FormState>();

  final _placaCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _dateTimeCtrl = TextEditingController();

  String? _selectedTipoIncidente;
  String? _selectedGravedad;

  Map<String, dynamic>? _assignmentData;
  bool _fetchingAssignment = false;
  String? _assignmentError;

  bool _submitting = false;

  static const _tiposIncidente = [
    'Averia',
    'Accidente',
    'Congestion de Trafico',
    'Retraso',
    'Falla Mecanica',
    'Otro',
  ];

  static const _gravedades = ['baja', 'media', 'alta', 'critica'];

  @override
  void dispose() {
    _placaCtrl.dispose();
    _descriptionCtrl.dispose();
    _dateTimeCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAssignmentData() async {
    final placa = _placaCtrl.text.trim().toUpperCase();
    if (placa.isEmpty) {
      setState(() {
        _assignmentError = 'Ingresa la placa del vehiculo';
        _assignmentData = null;
      });
      return;
    }

    setState(() {
      _fetchingAssignment = true;
      _assignmentError = null;
      _assignmentData = null;
    });

    try {
      final uri = Uri.parse(ApiService.reportsUrl).replace(
        queryParameters: {
          'action': 'get_assignment_data',
          'placa': placa,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (!response.body.trimLeft().startsWith('{')) {
        setState(() {
          _assignmentError =
              'El servidor respondio con HTTP ${response.statusCode}.';
          _fetchingAssignment = false;
        });
        return;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && decoded['success'] == true) {
        setState(() {
          _assignmentData = decoded['data'] as Map<String, dynamic>;
          _fetchingAssignment = false;
        });
      } else {
        setState(() {
          _assignmentError =
              decoded['error'] as String? ?? 'No se encontro la asignacion';
          _fetchingAssignment = false;
        });
      }
    } catch (e) {
      setState(() {
        _assignmentError = 'Error: $e';
        _fetchingAssignment = false;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;

    final combined =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      _dateTimeCtrl.text = '${combined.year.toString().padLeft(4, '0')}-'
          '${combined.month.toString().padLeft(2, '0')}-'
          '${combined.day.toString().padLeft(2, '0')} '
          '${combined.hour.toString().padLeft(2, '0')}:'
          '${combined.minute.toString().padLeft(2, '0')}:00';
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignmentData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Busca una asignacion valida antes de enviar'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('userId') ?? '') ?? 0;

      if (userId <= 0) {
        setState(() => _submitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'No se pudo obtener el usuario. Inicia sesion de nuevo.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            ),
          );
        }
        return;
      }

      final body = json.encode({
        'placa': _placaCtrl.text.trim().toUpperCase(),
        'id_usuario': userId,
        'tipo_incidente': _selectedTipoIncidente,
        'fecha_hora': _dateTimeCtrl.text.trim(),
        'descripcion': _descriptionCtrl.text.trim(),
        'gravedad': _selectedGravedad,
      });

      final response = await http
          .post(
            Uri.parse(ApiService.reportsUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (!response.body.trimLeft().startsWith('{')) {
        setState(() => _submitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'El servidor respondio con HTTP ${response.statusCode}.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            ),
          );
        }
        return;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          decoded['success'] == true) {
        final newReport = <String, dynamic>{
          'id_reporte': decoded['id_reporte'],
          'tipo_incidente': _selectedTipoIncidente,
          'gravedad': _selectedGravedad,
          'fecha_hora': _dateTimeCtrl.text.trim(),
          'descripcion': _descriptionCtrl.text.trim(),
          'vehiculo_placa': _assignmentData!['vehiculo_placa'],
          'vehiculo_modelo': _assignmentData!['vehiculo_modelo'],
          'conductor_nombre': _assignmentData!['conductor_nombre'],
          'ruta_nombre': _assignmentData!['ruta_nombre'],
          'origen': _assignmentData!['origen'],
          'destino': _assignmentData!['destino'],
        };

        if (mounted) {
          widget.onReportCreated(newReport);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Reporte creado exitosamente'),
                ],
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            ),
          );
        }
      } else {
        setState(() => _submitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  decoded['error'] as String? ?? 'Error al crear el reporte'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.assignment_late_outlined,
                            color: Colors.blueAccent[700], size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Nuevo reporte',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  Divider(
                      height: 24,
                      color: isDark ? Colors.white12 : Colors.grey[200]),

                  // Placa del vehiculo
                  Text('Vehiculo',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _placaCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Placa del vehiculo',
                            hintText: 'Ej: ABC1234',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Requerido';
                            return null;
                          },
                          onChanged: (_) {
                            if (_assignmentData != null ||
                                _assignmentError != null) {
                              setState(() {
                                _assignmentData = null;
                                _assignmentError = null;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              _fetchingAssignment ? null : _fetchAssignmentData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _fetchingAssignment
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Buscar'),
                        ),
                      ),
                    ],
                  ),

                  if (_assignmentError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _assignmentError!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                  if (_assignmentData != null) ...[
                    const SizedBox(height: 10),
                    _AssignmentInfoCard(data: _assignmentData!),
                  ],

                  const SizedBox(height: 16),

                  // Tipo de incidente
                  DropdownButtonFormField<String>(
                    value: _selectedTipoIncidente,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor:
                        isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Tipo de incidente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: _tiposIncidente
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedTipoIncidente = v),
                    validator: (v) =>
                        v == null ? 'Selecciona el tipo de incidente' : null,
                  ),
                  const SizedBox(height: 12),

                  // Gravedad
                  DropdownButtonFormField<String>(
                    value: _selectedGravedad,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor:
                        isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Gravedad',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    items: _gravedades
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g[0].toUpperCase() + g.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGravedad = v),
                    validator: (v) =>
                        v == null ? 'Selecciona la gravedad' : null,
                  ),
                  const SizedBox(height: 12),

                  // Fecha y hora
                  TextFormField(
                    controller: _dateTimeCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha y hora del incidente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today, size: 20),
                        onPressed: _pickDateTime,
                      ),
                    ),
                    onTap: _pickDateTime,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Selecciona la fecha y hora'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Descripcion
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descripcion del incidente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'La descripcion es requerida'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Enviar reporte'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Widget auxiliar: muestra la info de la asignacion encontrada
// =============================================================================

class _AssignmentInfoCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AssignmentInfoCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2B1A) : Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.green[800]! : Colors.green[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
              const SizedBox(width: 6),
              Text(
                'Asignacion encontrada',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.directions_car,
            text:
                '${data['vehiculo_placa']} — ${data['vehiculo_modelo'] ?? ''}',
          ),
          const SizedBox(height: 4),
          _InfoLine(
              icon: Icons.person,
              text: data['conductor_nombre'] as String? ?? ''),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.route,
            text:
                '${data['ruta_nombre']} (${data['origen']} -> ${data['destino']})',
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
