// ██████╗ ███████╗██████╗ ███████╗██╗██╗
// ██╔══██╗██╔════╝██╔══██╗██╔════╝██║██║
// ██████╔╝█████╗  ██████╔╝█████╗  ██║██║
// ██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██║██║
// ██║     ███████╗██║  ██║███████╗██║███████╗
// ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝
//
// settings_screen.dart - Pantalla de Configuración
// Versión: 1.0.0 | Última actualización: 23-12-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

/// ---------------------------------------------------------------------------
/// [SettingsScreen]
/// ---------------------------------------------------------------------------
/// Pantalla de configuración de la aplicación GoWay.
///
/// Características principales:
/// - Switch para activar/desactivar modo oscuro
/// - Persistencia de preferencias con SharedPreferences
/// - AppBar consistente con el diseño de la aplicación
/// - Cambio de tema en tiempo real
///
class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChange;

  const SettingsScreen({
    super.key,
    required this.onThemeChange,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  /// -------------------------------------------------------------------------
  /// [_loadThemePreference]
  /// -------------------------------------------------------------------------
  /// Carga la preferencia de tema guardada en SharedPreferences.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  /// -------------------------------------------------------------------------
  /// [_saveThemePreference]
  /// -------------------------------------------------------------------------
  /// Guarda la preferencia de tema en SharedPreferences.
  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  /// -------------------------------------------------------------------------
  /// [_toggleDarkMode]
  /// -------------------------------------------------------------------------
  /// Alterna entre modo oscuro y modo claro.
  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveThemePreference(value);
    widget.onThemeChange(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0.8,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apariencia',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingOption(
              icon: _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              title: 'Modo Oscuro',
              subtitle:
                  _isDarkMode ? 'Modo oscuro activado' : 'Modo claro activado',
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
                activeColor: Colors.blueAccent[700],
                inactiveThumbColor: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Información',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Versión de la Aplicación',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '2.0.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// [_buildSettingOption]
  /// -------------------------------------------------------------------------
  /// Componente reutilizable para construir una opción de configuración.
  ///
  /// Parámetros:
  /// - icon: Ícono a mostrar
  /// - title: Título de la opción
  /// - subtitle: Subtítulo descriptivo
  /// - trailing: Widget a mostrar a la derecha (ej: Switch)
  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.blueAccent[700],
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
            ),
          ),
          trailing: trailing,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
