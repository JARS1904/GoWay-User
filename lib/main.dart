// ██████╗  ██████╗  ██╗    ██╗ █████╗ ██╗   ██╗
// ██╔════╝ ██╔═══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
// ██║  ███╗██║   ██║██║ █╗ ██║███████║ ╚████╔╝
// ██║   ██║██║   ██║██║███╗██║██╔══██║  ╚██╔╝
// ╚██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║   ██║
//  ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
//
// main.dart - Punto de entrada principal de la aplicación GoWay
// Versión: 2.0.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:goway_user/login.dart';
import 'package:goway_user/registro_screen.dart';
import 'package:goway_user/route_selection_screen.dart';
import 'package:goway_user/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Punto de entrada principal de la aplicación Flutter.
///
/// Inicializa los bindings necesarios y lanza la aplicación MyApp.
void main() async {
  // Inicialización de bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Lanzamiento de la aplicación principal
  runApp(const MyApp());
}

/// Widget principal de la aplicación que configura el MaterialApp.
///
/// Responsabilidades:
/// - Configuración del tema claro/oscuro
/// - Definición de rutas nombradas
/// - Configuración global de comportamientos de UI
/// - Verificación de sesión persistida en SharedPreferences
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _checkSession();
  }

  /// Verifica si existe sesión guardada en SharedPreferences.
  /// Si existe, retorna MainNavigationWrapper.
  /// Si no existe, retorna LoginScreen.
  Future<Widget> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail');
    
    if (userEmail != null && userEmail.isNotEmpty) {
      return const MainNavigationWrapper();
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return MaterialApp(
              home: Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              ),
            );
          }
          final initialScreen = snapshot.data ?? const LoginScreen();
          return _buildMaterialApp(initialScreen);
        }
        // Pantalla de carga mientras verifica sesión
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  /// Construye el MaterialApp con la pantalla inicial apropiada.
  MaterialApp _buildMaterialApp(Widget initialScreen) {
    return MaterialApp(
      title: 'GoWay - Transporte Público',
      theme: _buildThemeData(), // Tema claro
      darkTheme: _buildThemeData(), // Tema oscuro (usando misma configuración)
      themeMode: ThemeMode.light, // Fuerza tema claro
      home: initialScreen, // Pantalla inicial dinámica
      debugShowCheckedModeBanner: false, // Oculta banner de debug

      // Rutas nombradas de la aplicación
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/rutas': (context) => const RouteSelectionScreen(),
        '/main': (context) => const MainNavigationWrapper(),
      },

      // Configuración global de UI
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // Evita escalado de texto
          ),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              overscroll: false, // Desactiva overscroll
              physics: const BouncingScrollPhysics(), // Física de scroll
            ),
            child: child!,
          ),
        );
      },
    );
  }

  /// Construye el ThemeData principal de la aplicación.
  ///
  /// Configura:
  /// - Esquema de colores basado en azul
  /// - Estilos de AppBar, cards y componentes de navegación
  /// - Diseño adaptado para móvil y tablet
  ThemeData _buildThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue, // Color semilla
        brightness: Brightness.light, // Tema claro
      ),
      useMaterial3: true, // Habilita Material 3

      // Configuración de AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true, // Centra el título
        elevation: 2, // Elevación sombra
        scrolledUnderElevation: 4, // Elevación al hacer scroll
      ),

      // Configuración de Cards
      cardTheme: CardThemeData(
        elevation: 2, // Elevación sombra
        margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Márgenes
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bordes redondeados
        ),
      ),

      // Configuración de BottomNavigationBar (versión móvil)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white, // Fondo blanco
        selectedItemColor: Colors.blueAccent[700], // Color seleccionado
        unselectedItemColor: Colors.grey[600], // Color no seleccionado
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600, // Negrita para seleccionado
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12, // Mismo tamaño para no seleccionado
        ),
        showUnselectedLabels: true, // Muestra siempre los labels
        type: BottomNavigationBarType.fixed, // Tipo fijo
        elevation: 4.0, // Elevación sombra
      ),

      // Configuración de NavigationRail (versión tablet)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white, // Fondo blanco
        selectedIconTheme:
            IconThemeData(color: Colors.blueAccent[700]), // Icono seleccionado
        unselectedIconTheme:
            IconThemeData(color: Colors.grey[600]), // Icono no seleccionado
        selectedLabelTextStyle: const TextStyle(
          color: Colors.blueAccent, // Texto seleccionado
          fontWeight: FontWeight.w600, // Negrita
        ),
        unselectedLabelTextStyle:
            const TextStyle(color: Colors.grey), // Texto no seleccionado
        elevation: 4, // Elevación sombra
        useIndicator: true, // Usa indicador visual
        indicatorColor: Colors.blueAccent.withOpacity(0.2), // Color indicador
      ),
    );
  }
}

/// Contenedor principal de navegación adaptable (mobile/tablet).
///
/// Gestiona:
/// - Navegación entre pantallas principales
/// - Adaptación automática al tipo de dispositivo
/// - Estado de las pantallas con IndexedStack
class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

/// Estado del contenedor principal de navegación.
///
/// Maneja:
/// - Índice de pantalla actual
/// - Estado de expansión del NavigationRail (tablet)
/// - Carga de datos de usuario
class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0; // Índice de pantalla actual (0 = Inicio, 1 = Perfil)
  bool _extended = false; // Estado de expansión del NavigationRail (tablet)
  late List<Widget> _screens; // Lista de pantallas disponibles

  @override
  void initState() {
    super.initState();
    // Inicialización de pantallas
    _screens = [
      const RouteSelectionScreen(), // Pantalla de inicio
      FutureBuilder(
        future: _loadUserData(), // Carga datos de usuario
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            // Pantalla de perfil con datos de usuario
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

  /// Carga los datos del usuario desde SharedPreferences.
  ///
  /// Retorna un Map con:
  /// - name: Nombre del usuario
  /// - email: Email del usuario
  Future<Map<String, String>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName') ?? 'Usuario',
      'email': prefs.getString('userEmail') ?? 'email@ejemplo.com',
    };
  }

  /// Determina si el dispositivo es una tablet basado en el ancho de pantalla.
  ///
  /// Considera tablet cualquier dispositivo con ancho >= 600px
  bool get _isTablet {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    // Selecciona el layout según el tipo de dispositivo
    return _isTablet ? _buildTabletLayout() : _buildMobileLayout();
  }

  /// Construye el layout para dispositivos móviles.
  ///
  /// Características:
  /// - BottomNavigationBar con 2 opciones
  /// - Íconos en cápsula con efecto de selección
  /// - Labels que cambian de color al seleccionarse
  Widget _buildMobileLayout() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex, // Pantalla actual
        children: _screens, // Lista de pantallas
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) =>
            setState(() => _currentIndex = index), // Cambio de pantalla
        selectedLabelStyle: TextStyle(
          color: Colors.blueAccent[700], // Texto azul para seleccionado
          fontWeight: FontWeight.w600, // Negrita
        ),
        unselectedLabelStyle: TextStyle(
          color: Colors.grey[600], // Texto gris para no seleccionado
        ),
        items: [
          // Ítem de Inicio
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              decoration: BoxDecoration(
                color: _currentIndex == 0
                    ? Colors.blueAccent
                        .withOpacity(0.2) // Fondo azul claro para seleccionado
                    : Colors.transparent, // Transparente para no seleccionado
                borderRadius: BorderRadius.circular(20), // Forma de cápsula
              ),
              child: Image.asset(
                "lib/assets/icons/icon_home.png",
                width: 24,
                height: 24,
                color: _currentIndex == 0
                    ? Colors.blueAccent[700] // Azul para seleccionado
                    : Colors.grey[600], // Gris para no seleccionado
              ),
            ),
            label: 'Inicio',
          ),
          // Ítem de Perfil
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
              decoration: BoxDecoration(
                color: _currentIndex == 1
                    ? Colors.blueAccent
                        .withOpacity(0.2) // Fondo azul claro para seleccionado
                    : Colors.transparent, // Transparente para no seleccionado
                borderRadius: BorderRadius.circular(20), // Forma de cápsula
              ),
              child: Image.asset(
                "lib/assets/icons/icon_user.png",
                width: 24,
                height: 24,
                color: _currentIndex == 1
                    ? Colors.blueAccent[700] // Azul para seleccionado
                    : Colors.grey[600], // Gris para no seleccionado
              ),
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  /// Construye el layout para dispositivos tablet.
  ///
  /// Características:
  /// - NavigationRail lateral expandible
  /// - Divisor vertical
  /// - Área de contenido principal
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Barra de navegación lateral
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            extended: _extended, // Estado de expansión
            minExtendedWidth: 150, // Ancho mínimo expandido
            leading: Column(
              children: [
                const SizedBox(height: 16),
                // Botón para expandir/contraer
                IconButton(
                  icon: Icon(
                      _extended ? Icons.chevron_left : Icons.chevron_right),
                  onPressed: () => setState(() => _extended = !_extended),
                  tooltip: _extended ? 'Contraer barra' : 'Expandir barra',
                ),
              ],
            ),
            // Destinos de navegación
            destinations: [
              NavigationRailDestination(
                icon: Image.asset(
                  "lib/assets/icons/icon_home.png",
                  width: 24,
                  height: 24,
                  color: _currentIndex == 0
                      ? Colors.blueAccent[700] // Azul para seleccionado
                      : Colors.grey[600], // Gris para no seleccionado
                ),
                selectedIcon: Image.asset(
                  "lib/assets/icons/icon_home.png",
                  width: 24,
                  height: 24,
                  color:
                      Colors.blueAccent[700], // Siempre azul para seleccionado
                ),
                label: Text(
                  'Inicio',
                  style: TextStyle(
                    color: _currentIndex == 0
                        ? Colors.blueAccent[700] // Azul para seleccionado
                        : Colors.grey[600], // Gris para no seleccionado
                  ),
                ),
                padding: const EdgeInsets.only(top: 3, bottom: 5),
              ),
              NavigationRailDestination(
                icon: Image.asset(
                  "lib/assets/icons/icon_user.png",
                  width: 24,
                  height: 24,
                  color: _currentIndex == 1
                      ? Colors.blueAccent[700] // Azul para seleccionado
                      : Colors.grey[600], // Gris para no seleccionado
                ),
                selectedIcon: Image.asset(
                  "lib/assets/icons/icon_user.png",
                  width: 24,
                  height: 24,
                  color:
                      Colors.blueAccent[700], // Siempre azul para seleccionado
                ),
                label: Text(
                  'Perfil',
                  style: TextStyle(
                    color: _currentIndex == 1
                        ? Colors.blueAccent[700] // Azul para seleccionado
                        : Colors.grey[600], // Gris para no seleccionado
                  ),
                ),
                padding: const EdgeInsets.only(top: 3, bottom: 5),
              ),
            ],
          ),
          // Divisor vertical
          const VerticalDivider(thickness: 1, width: 1),
          // Contenido principal
          Expanded(
            child: IndexedStack(
              index: _currentIndex, // Pantalla actual
              children: _screens, // Lista de pantallas
            ),
          ),
        ],
      ),
    );
  }
}
