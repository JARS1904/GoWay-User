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

  String _searchQuery = '';
  String _selectedFilter = 'Todas';
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  List<Map<String, dynamic>> get _filteredReports {
    return _userReports.where((r) {
      final searchLower = _searchQuery.toLowerCase();
      final tipo = (r['tipo_incidente'] as String? ?? '').toLowerCase();
      final desc = (r['descripcion'] as String? ?? '').toLowerCase();
      final ruta = (r['ruta_nombre'] as String? ?? '').toLowerCase();

      final matchesSearch = tipo.contains(searchLower) ||
          desc.contains(searchLower) ||
          ruta.contains(searchLower);

      final gravedad = (r['gravedad'] as String? ?? '').toLowerCase();
      bool matchesFilter = true;
      if (_selectedFilter != 'Todas') {
        String filterValue = _selectedFilter.toLowerCase();
        if (filterValue == 'crítica') filterValue = 'critica';
        matchesFilter = gravedad == filterValue;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedReports {
    final filtered = _filteredReports;
    final startIndex = _currentPage * _itemsPerPage;
    if (startIndex >= filtered.length) return [];
    return filtered.skip(startIndex).take(_itemsPerPage).toList();
  }

  int get _totalPages {
    final length = _filteredReports.length;
    return (length == 0) ? 1 : (length / _itemsPerPage).ceil();
  }

  void refresh() => _loadReportsFromServer();

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
            _currentPage = 0;
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
            icon: const Icon(Icons.search_rounded),
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: ReportSearchDelegate(
                  initialSearchQuery: _searchQuery,
                  reports: _userReports,
                ),
              );
              if (result != null) {
                setState(() {
                  _searchQuery = result;
                  _currentPage = 0;
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: _showCreateReportDialog,
          backgroundColor: Colors.blueAccent[700],
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add),
        ),
      ),
      body: _loadingReports
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilter(isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReportsFromServer,
                    color: isDark ? Colors.white : Colors.blueAccent[700],
                    backgroundColor:
                        isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    child: _userReports.isEmpty
                        ? _buildEmptyState(isDark, false)
                        : (_filteredReports.isEmpty
                            ? _buildEmptyState(isDark, true)
                            : ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                children: [
                                  ..._paginatedReports.map((report) =>
                                      _buildReportCard(report, isDark)),
                                  _buildPaginationControls(isDark),
                                ],
                              )),
                  ),
                ),
              ],
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
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: _showCreateReportDialog,
          backgroundColor: Colors.blueAccent[700],
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add),
        ),
      ),
      body: _loadingReports
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilter(isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReportsFromServer,
                    color: isDark ? Colors.white : Colors.blueAccent[700],
                    backgroundColor:
                        isDark ? const Color(0xFF1E1E1E) : Colors.grey[50],
                    child: _userReports.isEmpty
                        ? _buildEmptyState(isDark, false)
                        : (_filteredReports.isEmpty
                            ? _buildEmptyState(isDark, true)
                            : Center(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 1000),
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 24, 24, 100),
                                    children: [
                                      ..._paginatedReports.map((report) =>
                                          _buildReportCard(report, isDark)),
                                      _buildPaginationControls(isDark),
                                    ],
                                  ),
                                ),
                              )),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report, bool isDark) =>
      _ReportCard(report: report, isDark: isDark);

  Widget _buildEmptyState(bool isDark, [bool isFilterEmpty = false]) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
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
                      isFilterEmpty
                          ? Icons.search_off_rounded
                          : Icons.assignment_outlined,
                      size: 48,
                      color: Colors.blueAccent[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isFilterEmpty ? 'Sin coincidencias' : 'Sin reportes aun',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFilterEmpty
                        ? 'No se encontraron reportes con los filtros actuales.'
                        : 'Registra incidencias en las rutas para que el equipo pueda atenderlas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Column(
      children: [
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Resultados para: "$_searchQuery"',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _currentPage = 0;
                  }),
                ),
              ],
            ),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildFilterChip('Todas', isDark),
              _buildFilterChip('Crítica', isDark),
              _buildFilterChip('Alta', isDark),
              _buildFilterChip('Media', isDark),
              _buildFilterChip('Baja', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _currentPage = 0;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent[700]
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
            border:
                isDark ? null : Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentPage > 0
                        ? Colors.blueAccent[700]
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 16,
                    color: _currentPage > 0
                        ? Colors.white
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Página ${_currentPage + 1} de $_totalPages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _currentPage < _totalPages - 1
                        ? Colors.blueAccent[700]
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: _currentPage < _totalPages - 1
                        ? Colors.white
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateReportDialog() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateReportDialog(
        onReportCreated: (_) => _loadReportsFromServer(),
      ),
    );
  }
}

// =============================================================================
// Tarjeta de reporte expandible
// =============================================================================

class _ReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final bool isDark;

  const _ReportCard({required this.report, required this.isDark});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  static Color _colorForSeverity(String severity) {
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

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isDark = widget.isDark;
    final severityColor =
        _colorForSeverity(report['gravedad'] as String? ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isDark ? null : Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (siempre visible) ──────────────────────
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
                          //report['tipo_incidente'] as String? ?? '-',
                          (report['tipo_incidente'] as String? ?? '-')
                              .split(' ')
                              .map((w) => w.isEmpty
                                  ? ''
                                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
                              .join(' '),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (report['gravedad'] as String? ?? '')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: severityColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                report['fecha_hora'] as String? ?? '-',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                            color: isDark
                                ? Colors.orange[300]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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
              // ── Contenido expandible ──────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Divider(
                              height: 1,
                              color:
                                  isDark ? Colors.white12 : Colors.grey[200]),
                          const SizedBox(height: 10),
                          _infoRow(
                            context,
                            Icons.directions_car_outlined,
                            'Vehiculo',
                            [
                              report['vehiculo_placa'] as String? ?? '-',
                              if ((report['vehiculo_modelo'] as String? ?? '')
                                  .isNotEmpty)
                                report['vehiculo_modelo'] as String,
                            ].join(' · '),
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _infoRow(
                            context,
                            Icons.person_outline,
                            'Conductor',
                            report['conductor_nombre'] as String? ?? '-',
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _infoRow(
                            context,
                            Icons.route_outlined,
                            'Ruta',
                            report['ruta_nombre'] ?? '-',
                            /*
                            report['ruta_nombre'] != null
                                ? '${report['ruta_nombre']} (${report['origen']} → ${report['destino']})'
                                : '-',
                            */
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _infoRow(
                            context,
                            Icons.schedule_outlined,
                            'Fecha y Hora',
                            report['fecha_hora'] as String? ?? '-',
                            isDark,
                          ),
                          if ((report['descripcion'] as String? ?? '')
                              .isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F1F1F)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[500]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      report['descripcion'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _infoRow(BuildContext context, IconData icon, String label,
      String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 13,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
  bool _esRetorno = false;

  List<Map<String, String>> _tiposIncidente = [];
  List<Map<String, String>> _gravedades = [];
  bool _loadingOptions = true;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      final uri = Uri.parse(ApiService.reportsUrl).replace(
        queryParameters: {'action': 'get_options'},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (!response.body.trimLeft().startsWith('{')) {
        if (mounted) {
          setState(() {
            _optionsError = 'Respuesta no válida del servidor';
            _loadingOptions = false;
          });
        }
        return;
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && decoded['success'] == true) {
        if (mounted) {
          setState(() {
            _tiposIncidente = (decoded['tipos_incidencia'] as List)
                .map((e) => {
                      'id': e['id'].toString(),
                      'nombre': e['nombre'].toString()
                    })
                .toList();
            _gravedades = (decoded['niveles_gravedad'] as List)
                .map((e) => {
                      'id': e['id'].toString(),
                      'nombre': e['nombre'].toString()
                    })
                .toList();
            _loadingOptions = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _optionsError = 'Error al cargar opciones';
            _loadingOptions = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _optionsError = 'Error de conexión';
          _loadingOptions = false;
        });
      }
    }
  }

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
        'es_retorno': _esRetorno,
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

    const fieldRadius = BorderRadius.all(Radius.circular(20));

    InputDecoration _fieldDecoration(String label,
        {IconData? icon, Widget? suffix, bool isMultiline = false}) {
      return InputDecoration(
        isDense: true,
        labelText: label,
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Icon(icon,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
              )
            : null,
        prefixIconConstraints: icon != null
            ? const BoxConstraints(minWidth: 44, minHeight: 48)
            : null,
        suffixIcon: suffix,
        border: const OutlineInputBorder(borderRadius: fieldRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: Colors.blueAccent[700]!, width: 1.8),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 16, vertical: isMultiline ? 14 : 10),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: Container(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 1,
            maxWidth: MediaQuery.of(context).size.width,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle bar ──────────────────────────────────
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Header ──────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.12),
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

                    // ── Placa + botón buscar ─────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _placaCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _fieldDecoration(
                              'Placa del vehículo',
                              icon: Icons.directions_car_outlined,
                            ).copyWith(hintText: 'Ej: ABC1234'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
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
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _fetchingAssignment
                                ? null
                                : _fetchAssignmentData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent[700],
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.blueAccent[700]!
                                  .withValues(alpha: 0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _fetchingAssignment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Buscar',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
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
                      _AssignmentInfoCard(
                          data: _assignmentData!, esRetorno: _esRetorno),
                      if (_assignmentData!['id_ruta_retorno'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Es trayecto de regreso',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[800],
                                  ),
                            ),
                            Switch(
                              value: _esRetorno,
                              activeColor: Colors.blueAccent[700],
                              onChanged: (val) =>
                                  setState(() => _esRetorno = val),
                            ),
                          ],
                        ),
                      ],
                    ],

                    const SizedBox(height: 16),

                    // ── Opciones dinámicas ───────────────────────────
                    if (_loadingOptions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_optionsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Text(_optionsError!,
                                  style:
                                      const TextStyle(color: Colors.redAccent)),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _loadingOptions = true;
                                    _optionsError = null;
                                  });
                                  _fetchOptions();
                                },
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Tipo de incidente
                      FormField<String>(
                        initialValue: _selectedTipoIncidente,
                        validator: (v) => v == null
                            ? 'Selecciona el tipo de incidente'
                            : null,
                        builder: (state) {
                          return DropdownMenu<String>(
                            requestFocusOnTap: false,
                            enableFilter: false,
                            expandedInsets: EdgeInsets.zero,
                            menuHeight: 300,
                            initialSelection: _selectedTipoIncidente,
                            label: const Text('Tipo de incidente'),
                            errorText: state.errorText,
                            leadingIcon: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(Icons.warning_amber_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ),
                            inputDecorationTheme: InputDecorationTheme(
                              isDense: true,
                              constraints: state.hasError
                                  ? null
                                  : const BoxConstraints(maxHeight: 48),
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                    color: Colors.blueAccent[700]!, width: 1.8),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                    color: Colors.redAccent, width: 1.2),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                    color: Colors.redAccent, width: 1.8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 16),
                            ),
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white),
                              shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              elevation: const WidgetStatePropertyAll(8),
                            ),
                            dropdownMenuEntries: _tiposIncidente
                                .map((t) => DropdownMenuEntry(
                                      value: t['id']!,
                                      label: t['nombre']!,
                                      style: MenuItemButton.styleFrom(
                                        foregroundColor: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        textStyle:
                                            const TextStyle(fontSize: 14),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                      ),
                                    ))
                                .toList(),
                            onSelected: (newValue) {
                              setState(() {
                                _selectedTipoIncidente = newValue;
                              });
                              state.didChange(newValue);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Gravedad
                      FormField<String>(
                        initialValue: _selectedGravedad,
                        validator: (v) =>
                            v == null ? 'Selecciona la gravedad' : null,
                        builder: (state) {
                          return DropdownMenu<String>(
                            requestFocusOnTap: false,
                            enableFilter: false,
                            expandedInsets: EdgeInsets.zero,
                            menuHeight: 300,
                            initialSelection: _selectedGravedad,
                            label: const Text('Gravedad'),
                            errorText: state.errorText,
                            leadingIcon: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(Icons.bar_chart_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ),
                            inputDecorationTheme: InputDecorationTheme(
                              isDense: true,
                              constraints: state.hasError
                                  ? null
                                  : const BoxConstraints(maxHeight: 48),
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                    color: Colors.blueAccent[700]!, width: 1.8),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                    color: Colors.redAccent, width: 1.2),
                              ),
                              focusedErrorBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                                borderSide: BorderSide(
                                    color: Colors.redAccent, width: 1.8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0, horizontal: 16),
                            ),
                            menuStyle: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white),
                              shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              elevation: const WidgetStatePropertyAll(8),
                            ),
                            dropdownMenuEntries: _gravedades
                                .map((g) => DropdownMenuEntry(
                                      value: g['id']!,
                                      label: g['nombre']!,
                                      style: MenuItemButton.styleFrom(
                                        foregroundColor: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        textStyle:
                                            const TextStyle(fontSize: 14),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                      ),
                                    ))
                                .toList(),
                            onSelected: (newValue) {
                              setState(() {
                                _selectedGravedad = newValue;
                              });
                              state.didChange(newValue);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Fecha y hora ─────────────────────────────────
                    TextFormField(
                      controller: _dateTimeCtrl,
                      readOnly: true,
                      onTap: _pickDateTime,
                      decoration: _fieldDecoration(
                        'Fecha y hora del incidente',
                        icon: Icons.calendar_today_outlined,
                        suffix: IconButton(
                          icon: const Icon(Icons.edit_calendar_outlined,
                              size: 20),
                          onPressed: _pickDateTime,
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Selecciona la fecha y hora'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // ── Descripción ──────────────────────────────────
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 3,
                      decoration: _fieldDecoration(
                        'Descripción del incidente',
                        isMultiline: true,
                      ).copyWith(
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'La descripción es requerida'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Botones ──────────────────────────────────────
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
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent[700],
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.blueAccent[700]!
                                  .withValues(alpha: 0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Enviar reporte',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
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
  final bool esRetorno;

  const _AssignmentInfoCard({
    required this.data,
    this.esRetorno = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasRetorno = data['id_ruta_retorno'] != null;

    final String rName = esRetorno && hasRetorno
        ? (data['ruta_retorno_nombre'] ?? 'N/A')
        : data['ruta_nombre'];
    final String rOri = esRetorno && hasRetorno
        ? (data['ruta_retorno_origen'] ?? 'N/A')
        : data['origen'];
    final String rDes = esRetorno && hasRetorno
        ? (data['ruta_retorno_destino'] ?? 'N/A')
        : data['destino'];

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
                '${data['vehiculo_placa']} - ${data['vehiculo_modelo'] ?? ''}',
          ),
          const SizedBox(height: 4),
          _InfoLine(
              icon: Icons.person,
              text: data['conductor_nombre'] as String? ?? ''),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.route,
            text: rName,
            //text: '$rName ($rOri -> $rDes)',
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

class ReportSearchDelegate extends SearchDelegate<String> {
  final String initialSearchQuery;
  final List<Map<String, dynamic>> reports;

  ReportSearchDelegate({this.initialSearchQuery = '', required this.reports}) {
    query = initialSearchQuery;
  }

  @override
  String get searchFieldLabel => 'Buscar reportes...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
        toolbarHeight: 64,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Colors.blueAccent[700]!, width: 1.8),
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          fontSize: 16,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => close(context, query),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      close(context, query);
    });
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (query.trim().isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF121212) : Colors.grey[50],
        child: Center(
          child: Text(
            'Busca por tipo, descripción o ruta',
            style:
                TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
        ),
      );
    }

    final searchLower = query.toLowerCase();
    final filtered = reports.where((r) {
      final tipo = (r['tipo_incidente'] as String? ?? '').toLowerCase();
      final desc = (r['descripcion'] as String? ?? '').toLowerCase();
      final ruta = (r['ruta_nombre'] as String? ?? '').toLowerCase();

      return tipo.contains(searchLower) ||
          desc.contains(searchLower) ||
          ruta.contains(searchLower);
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        color: isDark ? const Color(0xFF121212) : Colors.grey[50],
        child: Center(
          child: Text(
            'No se encontraron reportes',
            style:
                TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      color: isDark ? const Color(0xFF121212) : Colors.grey[50],
      child: ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final report = filtered[index];
          final tipoOriginal = report['tipo_incidente'] as String? ?? '-';
          final tipo = tipoOriginal
              .split(' ')
              .map((w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
              .join(' ');

          return ListTile(
            leading: Icon(Icons.assignment_outlined,
                color: isDark ? Colors.grey[300] : Colors.grey[700]),
            title: Text(tipo,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(report['ruta_nombre'] ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
            onTap: () {
              query = tipoOriginal;
              close(context, query);
            },
          );
        },
      ),
    );
  }
}
