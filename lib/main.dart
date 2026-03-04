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
import 'package:goway_user/screens/auth/login.dart';
import 'package:goway_user/screens/auth/registro_screen.dart';
import 'package:goway_user/screens/home/route_selection_screen.dart';
import 'package:goway_user/screens/profile/profile_screen.dart';
import 'package:goway_user/screens/auth/get_started_screen.dart';
import 'package:goway_user/screens/favorites/favorites_screen.dart';
import 'package:goway_user/screens/map/map_screen.dart';
import 'package:goway_user/screens/reports/reports_screen.dart';
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
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  /// Carga la preferencia de tema guardada en SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  /// Verifica si el usuario está autenticado (tiene un token válido)
  Future<bool> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    debugPrint('Verificando autenticación: token=$token');
    return token != null && token.isNotEmpty;
  }

  /// Verifica si el usuario ya ha visto el onboarding
  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
    debugPrint('¿Ha visto onboarding?: $hasSeen');
    return hasSeen;
  }

  /// Determina cuál pantalla mostrar (GetStarted, Login o Home)
  Future<String> _getInitialRoute() async {
    final hasSeenOnboarding = await _hasSeenOnboarding();
    if (!hasSeenOnboarding) {
      return '/getstarted';
    }

    final isAuthenticated = await _checkAuthentication();
    if (isAuthenticated) {
      return '/main';
    }

    return '/login';
  }

  /// Callback para actualizar el tema desde SettingsScreen
  void _updateTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoWay - Transporte Público',
      theme: _buildLightTheme(), // Tema claro
      darkTheme: _buildDarkTheme(), // Tema oscuro
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: FutureBuilder<String>(
        future: _getInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Navegar a la ruta apropiada
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (snapshot.data != null && snapshot.data != '/main') {
              Navigator.of(context).pushReplacementNamed(snapshot.data!);
            }
          });

          // Retornar la pantalla por defecto según la ruta
          switch (snapshot.data) {
            case '/getstarted':
              return const GetStartedScreen();
            case '/login':
              return const LoginScreen();
            case '/main':
            default:
              return MainNavigationWrapper(onThemeChange: _updateTheme);
          }
        },
      ),
      debugShowCheckedModeBanner: false, // Oculta banner de debug

      // Rutas nombradas de la aplicación
      routes: {
        '/getstarted': (context) => const GetStartedScreen(),
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/rutas': (context) => const RouteSelectionScreen(),
        '/main': (context) =>
            MainNavigationWrapper(onThemeChange: _updateTheme),
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

  /// Construye el ThemeData para el tema claro.
  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.blueAccent.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: Colors.blueAccent[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Colors.grey, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: Colors.blueAccent[700]);
          }
          return IconThemeData(color: Colors.grey[600]);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent[700],
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 4.0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: IconThemeData(color: Colors.blueAccent[700]),
        unselectedIconTheme: IconThemeData(color: Colors.grey[600]),
        selectedLabelTextStyle: const TextStyle(
            color: Colors.blueAccent, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
        elevation: 4,
        useIndicator: true,
        indicatorColor: Colors.blueAccent.withOpacity(0.2),
      ),
    );
  }

  /// Construye el ThemeData para el tema oscuro.
  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1F1F1F),
        indicatorColor: Colors.blueAccent.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.blueAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Colors.grey, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.blueAccent);
          }
          return IconThemeData(color: Colors.grey[500]);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1F1F1F),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 4.0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF1F1F1F),
        selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
        unselectedIconTheme: IconThemeData(color: Colors.grey[500]),
        selectedLabelTextStyle: const TextStyle(
            color: Colors.blueAccent, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: const TextStyle(color: Colors.grey),
        elevation: 4,
        useIndicator: true,
        indicatorColor: Colors.blueAccent.withOpacity(0.2),
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
  final Function(bool)? onThemeChange;

  const MainNavigationWrapper({super.key, this.onThemeChange});

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
  late List<Widget> _screens; // Lista de pantallas disponibles
  final GlobalKey _routeSelectionKey = GlobalKey();
  final GlobalKey _favoritesKey = GlobalKey();
  final GlobalKey _reportsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Inicialización de pantallas
    _screens = [
      RouteSelectionScreen(
          key: _routeSelectionKey), // Pantalla de inicio con GlobalKey
      FavoritesScreen(key: _favoritesKey), // Pantalla de rutas favoritas
      ReportsScreen(key: _reportsKey), // Pantalla de reportes
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
              onThemeChange: widget.onThemeChange,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.blueAccent : Colors.blueAccent[700]!;
    final unselectedColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;

    return Scaffold(
      body: Stack(
        children: [
          // Contenido principal: ocupa toda la pantalla, la barra flota encima
          Positioned.fill(
            child: MediaQuery(
              // Inyecta 96px de padding inferior para que los ListView/Scroll
              // dejen espacio al final y no queden tapados por la barra flotante
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.of(context).padding.copyWith(
                      bottom: MediaQuery.of(context).padding.bottom + 96,
                    ),
              ),
              child: Stack(
                children: List.generate(_screens.length, (i) {
                  return AnimatedOpacity(
                    opacity: i == _currentIndex ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: i != _currentIndex,
                      child: _screens[i],
                    ),
                  );
                }),
              ),
            ),
          ),
          // Barra de navegación flotante
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFloatingNavItem(
                    icon: _currentIndex == 0
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    label: 'Inicio',
                    isSelected: _currentIndex == 0,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () {
                      if (_currentIndex == 0) {
                        (_routeSelectionKey.currentState as dynamic)
                            ?.refreshFavorites();
                      }
                      setState(() => _currentIndex = 0);
                      (_routeSelectionKey.currentState as dynamic)
                          ?.refreshFavorites();
                    },
                  ),
                  _buildFloatingNavItem(
                    icon: _currentIndex == 1
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: 'Favoritos',
                    isSelected: _currentIndex == 1,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () {
                      if (_currentIndex == 1) {
                        (_favoritesKey.currentState as dynamic)?.refresh();
                      }
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  _buildFloatingNavItem(
                    icon: _currentIndex == 2
                        ? Icons.description_rounded
                        : Icons.description_outlined,
                    label: 'Reportes',
                    isSelected: _currentIndex == 2,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () {
                      if (_currentIndex == 2) {
                        (_reportsKey.currentState as dynamic)?.refresh();
                      }
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  _buildFloatingNavItem(
                    icon: _currentIndex == 3
                        ? Icons.person_rounded
                        : Icons.person_outline_rounded,
                    label: 'Perfil',
                    isSelected: _currentIndex == 3,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un ítem de la barra de navegación flotante con animaciones.
  Widget _buildFloatingNavItem({
    String? iconAsset,
    IconData? icon,
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              child: iconAsset != null
                  ? Image.asset(iconAsset, width: 24, height: 24, color: color)
                  : Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: color,
                fontSize: isSelected ? 12.0 : 11.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el layout para dispositivos tablet.
  ///
  /// Características:
  /// - NavigationRail lateral con labels debajo de los iconos
  /// - Divisor vertical
  /// - Área de contenido principal
  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.blueAccent : Colors.blueAccent[700];
    final unselectedColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Scaffold(
      body: Row(
        children: [
          // Barra de navegación lateral
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (index == _currentIndex) {
                if (index == 0)
                  (_routeSelectionKey.currentState as dynamic)
                      ?.refreshFavorites();
                if (index == 1)
                  (_favoritesKey.currentState as dynamic)?.refresh();
                if (index == 2)
                  (_reportsKey.currentState as dynamic)?.refresh();
              }
              setState(() => _currentIndex = index);
              // Recargar favoritos cuando se vuelve a la pantalla de inicio
              if (index == 0) {
                (_routeSelectionKey.currentState as dynamic)
                    ?.refreshFavorites();
              }
            },
            labelType: NavigationRailLabelType.all, // Labels siempre visibles
            backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            groupAlignment: 0.0, // Centra los iconos verticalmente
            // Destinos de navegación
            destinations: [
              NavigationRailDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: _currentIndex == 0 ? selectedColor : unselectedColor,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: selectedColor,
                ),
                label: Text(
                  'Inicio',
                  style: TextStyle(
                    color: _currentIndex == 0 ? selectedColor : unselectedColor,
                  ),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: _currentIndex == 1 ? selectedColor : unselectedColor,
                ),
                selectedIcon: Icon(
                  Icons.favorite_rounded,
                  color: selectedColor,
                ),
                label: Text(
                  'Favoritos',
                  style: TextStyle(
                    color: _currentIndex == 1 ? selectedColor : unselectedColor,
                  ),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.description_outlined,
                  color: _currentIndex == 2 ? selectedColor : unselectedColor,
                ),
                selectedIcon: Icon(
                  Icons.description_rounded,
                  color: selectedColor,
                ),
                label: Text(
                  'Reportes',
                  style: TextStyle(
                    color: _currentIndex == 2 ? selectedColor : unselectedColor,
                  ),
                ),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: _currentIndex == 3 ? selectedColor : unselectedColor,
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: selectedColor,
                ),
                label: Text(
                  'Perfil',
                  style: TextStyle(
                    color: _currentIndex == 3 ? selectedColor : unselectedColor,
                  ),
                ),
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
