// ██████╗  ██████╗  ██╗    ██╗ █████╗ ██╗   ██╗
// ██╔════╝ ██╔═══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
// ██║  ███╗██║   ██║██║ █╗ ██║███████║ ╚████╔╝
// ██║   ██║██║   ██║██║███╗██║██╔══██║  ╚██╔╝
// ╚██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║   ██║
//  ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
//
// main.dart - Punto de entrada principal
// Versión: 1.0.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:goway_user/login.dart';
import 'package:goway_user/registro_screen.dart';
import 'user_list_screen.dart';

// ----------------------------------------------------------------------------
// [ENTRY POINT]
// ----------------------------------------------------------------------------
/// Punto de ejecución inicial de la aplicación Flutter.
///
/// Responsabilidades principales:
/// 1. Inicializar los bindings esenciales de Flutter
/// 2. Lanzar el widget raíz de la aplicación (MyApp)
///
/// Nota técnica: WidgetsFlutterBinding.ensureInitialized() es requerido para:
/// - Uso de plugins nativos
/// - Llamadas a plataforma específica antes de runApp()
void main() async {
  // Inicialización de paquetes (si los tuvieras)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

// ----------------------------------------------------------------------------
// [MAIN APPLICATION WIDGET]
// ----------------------------------------------------------------------------
/// Configuración global de MaterialApp que establece:
/// - Temas visuales (claro/oscuro)
/// - Rutas de navegación
/// - Comportamientos globales de UI
///
/// Arquitectura:
///
///     MyApp (MaterialApp)
///     ├── Theme
///     ├── Routes
///     ├── UserListScreen (Home)
///     └── Global Behaviors
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ----------------------------------------------------------------------
      // CONFIGURACIÓN BÁSICA
      // ----------------------------------------------------------------------
      title: 'GoWay - Transporte Público',
      theme: _buildThemeData(),
      darkTheme: _buildThemeData(),
      themeMode: ThemeMode.light, // Puede ser cambiado a ThemeMode.system
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,

      // ----------------------------------------------------------------------
      // CONFIGURACIÓN DE RUTAS
      // ----------------------------------------------------------------------
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/users': (context) => const UserListScreen(),
        // Añadir más rutas según sea necesario
      },

      // ----------------------------------------------------------------------
      // COMPORTAMIENTOS GLOBALES
      // ----------------------------------------------------------------------
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler:
                TextScaler.linear(1.0), // Evita escalado de texto no deseado
          ),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              overscroll: false,
              physics: const BouncingScrollPhysics(),
            ),
            child: child!,
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // TEMA DE LA APLICACIÓN
  // --------------------------------------------------------------------------
  /// Construir el ThemeData principal con:
  /// - Material Design 3 habilitado
  /// - Paleta generada desde Colors.blue
  /// - Estilos consistentes para AppBar y Cards
  ///
  /// Parámetros clave:
  /// - seedColor: Colors.blue (#4285F4)
  /// - cardRadius: 12px
  /// - appBarElevation: 2dp
  ThemeData _buildThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        scrolledUnderElevation: 4,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
