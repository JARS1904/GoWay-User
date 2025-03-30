// ██████╗  ██████╗  ██╗    ██╗ █████╗ ██╗   ██╗
// ██╔════╝ ██╔═══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
// ██║  ███╗██║   ██║██║ █╗ ██║███████║ ╚████╔╝
// ██║   ██║██║   ██║██║███╗██║██╔══██║  ╚██╔╝
// ╚██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║   ██║
//  ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
//
// main.dart - Punto de entrada principal
// Versión: 2.0.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:goway_user/login.dart';
import 'package:goway_user/registro_screen.dart';
import 'package:goway_user/user_list_screen.dart';
import 'package:goway_user/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------------
// [ENTRY POINT]
// ----------------------------------------------------------------------------
/// Punto de ejecución inicial de la aplicación Flutter.
///
/// Cambios principales en la versión 2.0:
/// - Implementación de navegación con BottomNavigationBar
/// - Gestión de estado de usuario con SharedPreferences
/// - Nueva arquitectura de navegación
void main() async {
  // Inicialización de bindings y paquetes
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

// ----------------------------------------------------------------------------
// [MAIN APPLICATION WIDGET]
// ----------------------------------------------------------------------------
/// Configuración global de MaterialApp con nueva estructura de navegación.
///
/// Novedades en la arquitectura:
///
///     MyApp (MaterialApp)
///     ├── Theme
///     ├── Routes
///     ├── LoginScreen (Punto inicial)
///     └── MainNavigationWrapper (Home después de login)
///         ├── UserListScreen (Inicio)
///         └── ProfileScreen (Perfil)
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
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,

      // ----------------------------------------------------------------------
      // CONFIGURACIÓN DE RUTAS
      // ----------------------------------------------------------------------
      /// Rutas principales de la aplicación:
      /// - /login: Pantalla de autenticación
      /// - /registro: Pantalla de creación de cuenta
      /// - /main: Contenedor principal con navegación inferior
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/main': (context) => const MainNavigationWrapper(),
      },

      // ----------------------------------------------------------------------
      // COMPORTAMIENTOS GLOBALES
      // ----------------------------------------------------------------------
      /// Configuraciones globales de UI:
      /// - Escalado de texto consistente
      /// - Comportamiento de scroll personalizado
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
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
  /// Construye el ThemeData principal con configuraciones extendidas:
  /// - Nueva configuración para BottomNavigationBar
  /// - Mantiene consistencia con el diseño existente
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent[700],
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 4.0, // Añadido para asegurar visibilidad
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// [MainNavigationWrapper]
/// ---------------------------------------------------------------------------
/// Widget contenedor principal que maneja la navegación inferior.
///
/// Responsabilidades:
/// 1. Gestionar el índice de la pantalla activa
/// 2. Mantener el estado de las pantallas con IndexedStack
/// 3. Cargar los datos del usuario para la pantalla de perfil
/// 4. Proporcionar la BottomNavigationBar
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

/// ---------------------------------------------------------------------------
/// [_MainNavigationWrapperState]
/// ---------------------------------------------------------------------------
/// Estado del contenedor principal de navegación.
///
/// Atributos:
/// - _currentIndex: Índice de la pantalla activa (0 = Inicio, 1 = Perfil)
/// - _screens: Lista de pantallas disponibles
///
/// Métodos clave:
/// - _loadUserData: Carga asíncrona de datos del usuario desde SharedPreferences
/// - build: Construye la interfaz con IndexedStack y BottomNavigationBar
class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    _screens = [
      const UserListScreen(),
      FutureBuilder(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return ProfileScreen(
              userName: snapshot.data?['name'] ?? 'Usuario',
              userEmail: snapshot.data?['email'] ?? 'email@ejemplo.com',
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    ];
  }

  Future<Map<String, String>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName') ?? 'Usuario',
      'email': prefs.getString('userEmail') ?? 'email@ejemplo.com',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}