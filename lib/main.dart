// ██████╗  ██████╗  ██╗    ██╗ █████╗ ██╗   ██╗
// ██╔════╝ ██╔═══██╗██║    ██║██╔══██╗╚██╗ ██╔╝
// ██║  ███╗██║   ██║██║ █╗ ██║███████║ ╚████╔╝
// ██║   ██║██║   ██║██║███╗██║██╔══██║  ╚██╔╝
// ╚██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║   ██║
//  ╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝
//
// main.dart - Punto de entrada principal de la aplicación GoWay
// Versión: 2.1.0 | Última actualización: 03-05-2026

import 'package:flutter/material.dart';
import 'package:goway_user/screens/auth/login.dart';
import 'package:goway_user/screens/auth/registro_screen.dart';
import 'package:goway_user/screens/home/route_selection_screen.dart';
import 'package:goway_user/screens/profile/profile_screen.dart';
import 'package:goway_user/screens/auth/get_started_screen.dart';
import 'package:goway_user/screens/favorites/favorites_screen.dart';
import 'package:goway_user/screens/reports/reports_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goway_user/screens/map/map_screen.dart';
import 'package:goway_user/screens/profile/id_card_screen.dart';
import 'package:audioplayers/audioplayers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

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

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<bool> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    debugPrint('Verificando autenticación: token=$token');
    return token != null && token.isNotEmpty;
  }

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
    debugPrint('¿Ha visto onboarding?: $hasSeen');
    return hasSeen;
  }

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

  void _updateTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoWay - Transporte Público',
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: FutureBuilder<String>(
        future: _getInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (snapshot.data != null && snapshot.data != '/main') {
              Navigator.of(context).pushReplacementNamed(snapshot.data!);
            }
          });

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
      debugShowCheckedModeBanner: false,
      routes: {
        '/getstarted': (context) => const GetStartedScreen(),
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/rutas': (context) => const RouteSelectionScreen(),
        '/main': (context) =>
            MainNavigationWrapper(onThemeChange: _updateTheme),
      },
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

/// Contenedor principal de navegación adaptable (mobile/tablet)
class MainNavigationWrapper extends StatefulWidget {
  final Function(bool)? onThemeChange;

  const MainNavigationWrapper({super.key, this.onThemeChange});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  bool _isMenuOpen = false;
  List<Widget> _screens = []; // ✅ Inicializado vacío (ya no es late)
  final GlobalKey _routeSelectionKey = GlobalKey();
  final GlobalKey _favoritesKey = GlobalKey();
  final GlobalKey _reportsKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  // Variables para datos del usuario
  String _userName = 'Usuario';
  String _userEmail = 'email@ejemplo.com';
  String? _userPhotoUrl;
  int? _userId;
  String? _userPhone;
  String? _userRegistrationDate;
  String? _userType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('userName') ?? 'Usuario';
        _userEmail = prefs.getString('userEmail') ?? 'email@ejemplo.com';
        _userPhotoUrl = prefs.getString('userPhotoUrl');
        final rawId =
            prefs.getString('userId') ?? prefs.getInt('userId')?.toString();
        _userId = rawId != null ? int.tryParse(rawId) : null;
        _userPhone = prefs.getString('userPhone');
        _userRegistrationDate = prefs.getString('userRegistrationDate');
        _userType = prefs.getString('userType');
        _isLoading = false;
      });
      _initializeScreens();
    }
  }

  void _initializeScreens() {
    _screens = [
      RouteSelectionScreen(
        key: _routeSelectionKey,
        userPhotoUrl: _userPhotoUrl,
        userName: _userName,
      ),
      FavoritesScreen(key: _favoritesKey),
      ReportsScreen(key: _reportsKey),
      ProfileScreen(
        key: _profileKey,
        userName: _userName,
        userEmail: _userEmail,
        userPhotoUrl: _userPhotoUrl,
        userId: _userId,
        userPhone: _userPhone,
        userRegistrationDate: _userRegistrationDate,
        userType: _userType,
        onThemeChange: widget.onThemeChange,
      ),
    ];
    // Forzar reconstrucción después de inicializar las screens
    if (mounted) setState(() {});
  }

  bool get _isTablet {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width >= 600;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Mostrar loading mientras se cargan los datos o las screens
    if (_isLoading || _screens.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isTablet ? _buildTabletLayout() : _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = Colors.blueAccent[700]!;
    final unselectedColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
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
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isMenuOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isMenuOpen ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: () => setState(() => _isMenuOpen = false),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            left: 16,
            right: 16,
            bottom: _isMenuOpen ? 90 : 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isMenuOpen ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: _buildPopupMenu(isDark),
              ),
            ),
          ),
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
                      FocusManager.instance.primaryFocus?.unfocus();
                      (_routeSelectionKey.currentState as dynamic)?.refresh();
                      setState(() => _currentIndex = 0);
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
                      FocusManager.instance.primaryFocus?.unfocus();
                      (_favoritesKey.currentState as dynamic)?.refresh();
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  _buildCenterActionButton(isDark),
                  _buildFloatingNavItem(
                    icon: _currentIndex == 2
                        ? Icons.description_rounded
                        : Icons.description_outlined,
                    label: 'Reportes',
                    isSelected: _currentIndex == 2,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor,
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      (_reportsKey.currentState as dynamic)?.refresh();
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
                    onTap: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      (_profileKey.currentState as dynamic)?.refresh();
                      setState(() => _currentIndex = 3);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = Colors.blueAccent[700];
    final unselectedColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (index == 0) {
                    (_routeSelectionKey.currentState as dynamic)?.refresh();
                  } else if (index == 1) {
                    (_favoritesKey.currentState as dynamic)?.refresh();
                  } else if (index == 2) {
                    (_reportsKey.currentState as dynamic)?.refresh();
                  } else if (index == 3) {
                    (_profileKey.currentState as dynamic)?.refresh();
                  }
                  setState(() => _currentIndex = index);
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor:
                    isDark ? const Color(0xFF1F1F1F) : Colors.white,
                groupAlignment: 0.0,
                trailing: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _buildCenterActionButton(isDark),
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined,
                        color: _currentIndex == 0
                            ? selectedColor
                            : unselectedColor),
                    selectedIcon:
                        Icon(Icons.home_rounded, color: selectedColor),
                    label: Text('Inicio',
                        style: TextStyle(
                            color: _currentIndex == 0
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite_border_rounded,
                        color: _currentIndex == 1
                            ? selectedColor
                            : unselectedColor),
                    selectedIcon:
                        Icon(Icons.favorite_rounded, color: selectedColor),
                    label: Text('Favoritos',
                        style: TextStyle(
                            color: _currentIndex == 1
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.description_outlined,
                        color: _currentIndex == 2
                            ? selectedColor
                            : unselectedColor),
                    selectedIcon:
                        Icon(Icons.description_rounded, color: selectedColor),
                    label: Text('Reportes',
                        style: TextStyle(
                            color: _currentIndex == 2
                                ? selectedColor
                                : unselectedColor)),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline_rounded,
                        color: _currentIndex == 3
                            ? selectedColor
                            : unselectedColor),
                    selectedIcon:
                        Icon(Icons.person_rounded, color: selectedColor),
                    label: Text('Perfil',
                        style: TextStyle(
                            color: _currentIndex == 3
                                ? selectedColor
                                : unselectedColor)),
                  ),
                ],
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isMenuOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isMenuOpen ? 1.0 : 0.0,
                child: GestureDetector(
                  onTap: () => setState(() => _isMenuOpen = false),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            left: 100,
            bottom: _isMenuOpen ? 40 : 10,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isMenuOpen ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: _buildPopupMenu(isDark, isTablet: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterActionButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMenuOpen = !_isMenuOpen;
        });
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: Colors.blueAccent[700],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent[700]!.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]),
        child: Icon(
          _isMenuOpen ? Icons.close_rounded : Icons.add_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPopupMenu(bool isDark, {bool isTablet = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: isTablet ? 220 : null,
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.map_outlined,
                  color: isDark ? Colors.grey[500] : Colors.grey[600]),
              title: Text('Ir al mapa',
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.normal)),
              onTap: () {
                setState(() => _isMenuOpen = false);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MapScreen()));
              },
            ),
            Divider(
                height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
            ListTile(
              leading: Icon(Icons.badge_outlined,
                  color: isDark ? Colors.grey[500] : Colors.grey[600]),
              title: Text('Mi tarjeta',
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.normal)),
              onTap: () {
                setState(() => _isMenuOpen = false);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => IdCardScreen(
                              userName: _userName,
                              userEmail: _userEmail,
                              userPhotoUrl: _userPhotoUrl,
                              userId: _userId,
                              userPhone: _userPhone,
                              userRegistrationDate: _userRegistrationDate,
                              userType: _userType,
                            )));
              },
            ),
            Divider(
                height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
            ListTile(
              leading: Icon(Icons.volume_up_outlined,
                  color: isDark ? Colors.grey[500] : Colors.grey[600]),
              title: Text('Bajan por favor',
                  style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.normal)),
              onTap: () async {
                setState(() => _isMenuOpen = false);
                final player = AudioPlayer();
                await player.setVolume(1.0);
                await player
                    .play(AssetSource('sounds/ElevenLabs_Bajan_por_favor.mp3'));
              },
            ),
          ],
        ),
      ),
    );
  }
}
