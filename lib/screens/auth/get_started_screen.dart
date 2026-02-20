import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late AnimationController _buttonController;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '¡Bienvenido a GoWay!',
      description:
          'Tu aplicación para gestionar transporte público de forma fácil y rápida',
      icon: Icons.directions_bus,
      color: const Color(0xFF6366F1),
      gradientEnd: const Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      title: 'Rastreo en Tiempo Real',
      description:
          'Sigue tus rutas de transporte en tiempo real y nunca llegues tarde',
      icon: Icons.location_on,
      color: const Color(0xFF10B981),
      gradientEnd: const Color(0xFF059669),
    ),
    OnboardingPage(
      title: 'Gestiona tus Preferencias',
      description: 'Personaliza tus rutas favoritas, horarios y notificaciones',
      icon: Icons.settings,
      color: const Color(0xFF3B82F6),
      gradientEnd: const Color(0xFF1D4ED8),
    ),
    OnboardingPage(
      title: '¡Comienza tu Viaje!',
      description:
          'Inicia sesión y descubre todas las características de GoWay',
      icon: Icons.rocket_launch,
      color: const Color(0xFFEC4899),
      gradientEnd: const Color(0xFFBE185D),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _floatingController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingAsCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    debugPrint('Onboarding marcado como completado');
  }

  void _goToLogin() async {
    await _markOnboardingAsCompleted();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToLogin();
    }
  }

  void _skipOnboarding() {
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      body: Stack(
        children: [
          // Fondo con gradientes animados
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _pages[_currentPage].color.withOpacity(0.08),
                  _pages[_currentPage].gradientEnd.withOpacity(0.04),
                ],
              ),
            ),
          ),
          // Círculos de fondo decorativos animados
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    20 * _floatingController.value,
                    -20 * _floatingController.value,
                  ),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _pages[_currentPage].color.withOpacity(0.1),
                          _pages[_currentPage].color.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -15 * _floatingController.value,
                    15 * _floatingController.value,
                  ),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _pages[_currentPage].gradientEnd.withOpacity(0.08),
                          _pages[_currentPage].gradientEnd.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header con Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.9 + (_animationController.value * 0.1),
                            child: Text(
                              '${_currentPage + 1}/${_pages.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _pages[_currentPage].color,
                                letterSpacing: 1.5,
                              ),
                            ),
                          );
                        },
                      ),
                      if (_currentPage < _pages.length - 1)
                        GestureDetector(
                          onTap: _skipOnboarding,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[900]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _pages[_currentPage]
                                      .color
                                      .withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Saltar',
                                style: TextStyle(
                                  color: _pages[_currentPage].color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Page View
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(_pages[index], isDark);
                    },
                  ),
                ),
                // Indicators y Botones
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Page indicators mejorados
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              height: 8,
                              width: _currentPage == index ? 28 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? _pages[_currentPage].color
                                    : (isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: _currentPage == index
                                    ? [
                                        BoxShadow(
                                          color: _pages[_currentPage]
                                              .color
                                              .withOpacity(0.5),
                                          blurRadius: 12,
                                          spreadRadius: 3,
                                        ),
                                      ]
                                    : [],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Botón principal con efectos premium
                      MouseRegion(
                        onEnter: (_) => _buttonController.forward(),
                        onExit: (_) => _buttonController.reverse(),
                        child: GestureDetector(
                          onTap: _nextPage,
                          child: AnimatedBuilder(
                            animation: _buttonController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1 - (_buttonController.value * 0.04),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _pages[_currentPage]
                                            .color
                                            .withOpacity(0.4 +
                                                (_buttonController.value *
                                                    0.2)),
                                        blurRadius:
                                            20 + (_buttonController.value * 10),
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _nextPage,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: double.infinity,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _pages[_currentPage].color,
                                              _pages[_currentPage].gradientEnd,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Shimmer effect
                                            Positioned.fill(
                                              child: ShaderMask(
                                                shaderCallback: (bounds) {
                                                  return LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [
                                                      Colors.white
                                                          .withOpacity(0),
                                                      Colors.white.withOpacity(
                                                          0.3 +
                                                              (_buttonController
                                                                      .value *
                                                                  0.3)),
                                                      Colors.white
                                                          .withOpacity(0),
                                                    ],
                                                    stops: const [0, 0.5, 1],
                                                  ).createShader(bounds);
                                                },
                                                child: Container(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            // Text
                                            Center(
                                              child: Text(
                                                _currentPage ==
                                                        _pages.length - 1
                                                    ? '¡Comienza Ahora!'
                                                    : 'Siguiente',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page, bool isDark) {
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.4, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon con animaciones múltiples
              AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      8 * _floatingController.value - 4,
                    ),
                    child: child!,
                  );
                },
                child: ScaleTransition(
                  scale: _animationController,
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.05).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            page.color.withOpacity(0.2),
                            page.gradientEnd.withOpacity(0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: page.color.withOpacity(0.25),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        page.icon,
                        size: 80,
                        color: page.color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 56),
              // Title con animación de entrada
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.2, 1, curve: Curves.easeOut),
                  ),
                ),
                child: Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.7,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: page.color.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Description con animación de entrada retrasada
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.35, 1, curve: Curves.easeOut),
                  ),
                ),
                child: Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.7,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color gradientEnd;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradientEnd,
  });
}
