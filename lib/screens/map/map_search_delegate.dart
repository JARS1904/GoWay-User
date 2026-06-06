import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:goway_user/services/nominatim_service.dart';

class MapSearchDelegate extends SearchDelegate<LatLng?> {
  @override
  String get searchFieldLabel => 'Ej. Parque Central, Jalpa...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
        toolbarHeight: 64, // Ligeramente más pequeño
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
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildBody(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    if (query.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return _DebouncedSearch(
      query: query,
      onSelected: (location) => close(context, location),
    );
  }
}

class _DebouncedSearch extends StatefulWidget {
  final String query;
  final Function(LatLng) onSelected;

  const _DebouncedSearch({
    required this.query,
    required this.onSelected,
  });

  @override
  State<_DebouncedSearch> createState() => _DebouncedSearchState();
}

class _DebouncedSearchState extends State<_DebouncedSearch> {
  Timer? _debounce;
  Future<List<NominatimPlace>>? _future;

  @override
  void initState() {
    super.initState();
    _scheduleSearch();
  }

  @override
  void didUpdateWidget(covariant _DebouncedSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _scheduleSearch();
    }
  }

  void _scheduleSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _future = NominatimService.searchAddress(widget.query);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_future == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<NominatimPlace>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al buscar',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron resultados',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final place = results[index];
            return ListTile(
              leading: Image.asset(
                'lib/assets/icons/icons8-marcador-filled.png',
                color: Colors.redAccent[700],
                width: 28,
                height: 28,
              ),
              title: Text(
                place.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              onTap: () => widget.onSelected(place.location),
            );
          },
        );
      },
    );
  }
}
