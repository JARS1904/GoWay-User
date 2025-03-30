// ██████╗  ██████╗  ██╗    ██╗ █████╗ ██╗   ██╗
// ██╔════╝ ██╔═══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
// ██║  ███╗██║   ██║██║ █╗ ██║███████║ ╚████╔╝
// ██║   ██║██║   ██║██║███╗██║██╔══██║  ╚██╔╝
// ╚██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║   ██║
//  ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
//
// main.dart - Punto de entrada principal
// Versión: 2.0.0 | Última actualización: 29-03-2025}
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
/// Responsabilidades principales:
/// 1. Inicializar los bindings de Flutter
/// 2. Cargar cualquier configuración inicial necesaria
/// 3. Lanzar la aplicación con MyApp como widget raíz
///
/// Configuración inicial requerida:
/// - WidgetsFlutterBinding.ensureInitialized() para paquetes nativos
void main() async {
  // Inicialización de bindings y paquetes
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

// ----------------------------------------------------------------------------
// [MAIN APPLICATION WIDGET]
// ----------------------------------------------------------------------------
/// Configuración global de MaterialApp con estructura de navegación mejorada.
///
/// Arquitectura principal:
///
///     MyApp (MaterialApp)
///     ├── Theme (configuración visual global)
///     ├── Routes (gestión de navegación)
///     ├── LoginScreen (punto de entrada inicial)
///     └── MainNavigationWrapper (contiene la navegación inferior)
///         ├── UserListScreen (pantalla de inicio)
///         └── ProfileScreen (pantalla de perfil)
///
/// Características clave:
/// - Gestión centralizada de rutas
/// - Configuración de tema consistente
/// - Comportamientos globales de UI
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ----------------------------------------------------------------------
      // CONFIGURACIÓN BÁSICA
      // ----------------------------------------------------------------------
      /// Configuración esencial de la aplicación:
      /// - Título mostrado en el sistema operativo
      /// - Temas claro/oscuro
      /// - Pantalla inicial (LoginScreen)
      /// - Desactivación del banner de debug
      title: 'GoWay - Transporte Público',
      theme: _buildThemeData(),
      darkTheme: _buildThemeData(),
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,

      // ----------------------------------------------------------------------
      // CONFIGURACIÓN DE RUTAS
      // ----------------------------------------------------------------------
      /// Mapeo de rutas nombradas para navegación global:
      /// - '/login': Pantalla de autenticación
      /// - '/registro': Pantalla de creación de cuenta
      /// - '/main': Contenedor principal con navegación inferior
      ///
      /// Uso recomendado:
      /// Navigator.pushNamed(context, '/ruta');
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/main': (context) => const MainNavigationWrapper(),
      },

      // ----------------------------------------------------------------------
      // COMPORTAMIENTOS GLOBALES
      // ----------------------------------------------------------------------
      /// Personalizaciones globales de UI:
      /// - Escalado de texto consistente en todos los dispositivos
      /// - Comportamiento de scroll personalizado para toda la app
      /// - Desactivación del overscroll glow
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
  /// Construye el ThemeData principal con configuraciones extendidas.
  ///
  /// Elementos configurados:
  /// - Esquema de colores basado en azul
  /// - Estilo de AppBar consistente
  /// - Diseño de tarjetas estandarizado
  /// - Configuración específica para BottomNavigationBar
  ///
  /// @return ThemeData completamente configurado
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
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
/// Funcionalidades clave:
/// - Gestiona la navegación entre pantallas principales
/// - Mantiene el estado de cada pantalla con IndexedStack
/// - Proporciona una barra de navegación inferior consistente
///
/// Flujo de trabajo:
/// 1. Carga los datos del usuario al iniciar
/// 2. Construye la interfaz con las pantallas disponibles
/// 3. Maneja los cambios entre pestañas
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
/// Atributos principales:
/// - _currentIndex: Controla la pantalla visible (0 = Inicio, 1 = Perfil)
/// - _screens: Lista de widgets/pantallas disponibles
///
/// Ciclo de vida:
/// 1. initState: Inicializa las pantallas y carga datos del usuario
/// 2. build: Construye la interfaz con la pantalla activa y la barra de navegación
class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    /// Inicialización de pantallas disponibles:
    /// - Índice 0: UserListScreen (Pantalla principal)
    /// - Índice 1: ProfileScreen con datos cargados asíncronamente
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

  /// -------------------------------------------------------------------------
  /// [_loadUserData]
  /// -------------------------------------------------------------------------
  /// Carga los datos del usuario desde SharedPreferences.
  ///
  /// Proceso:
  /// 1. Obtiene la instancia de SharedPreferences
  /// 2. Recupera los valores guardados para nombre y email
  /// 3. Retorna un Map con los datos o valores por defecto
  ///
  /// @return Future<Map<String, String>> con los datos del usuario
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
      /// ---------------------------------------------------------------------
      /// [IndexedStack]
      /// ---------------------------------------------------------------------
      /// Mantiene todas las pantallas en el árbol de widgets pero solo
      /// muestra la activa. Preserva el estado de cada pantalla.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      /// ---------------------------------------------------------------------
      /// [BottomNavigationBar]
      /// ---------------------------------------------------------------------
      /// Barra de navegación inferior con:
      /// - Dos items: Inicio (Home) y Perfil (Person)
      /// - Manejo de cambios de pestaña mediante setState
      /// - Estilo consistente con el tema de la aplicación
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              "lib/assets/icons/icon_home.png",
              width: 24,
              height: 24,
              color: _currentIndex == 0
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              "lib/assets/icons/icon_user.png",
              width: 24,
              height: 24,
              color: _currentIndex == 1
                  ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                  : Theme.of(context)
                      .bottomNavigationBarTheme
                      .unselectedItemColor,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
