import 'package:flutter/material.dart';
import 'package:goway_user/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen>
    with TickerProviderStateMixin {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late final AnimationController _entryController;

  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _fieldsFade;
  late final Animation<Offset> _fieldsSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _footerFade;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      ),
    );

    _fieldsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );
    _fieldsSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    _footerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Las contraseñas no coinciden',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.redAccent[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiService.usuariosUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('¡Registro exitoso!',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const LoginScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        }
      } else {
        if (mounted) {
          String errorMsg = responseData['error'] ?? 'Error en el registro';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(errorMsg,
                          style: const TextStyle(color: Colors.white))),
                ],
              ),
              backgroundColor: Colors.redAccent[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Error de conexión: ${e.toString()}',
                        style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.redAccent[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  // ─────────────────────────────────────────
  // MÓVIL
  // ─────────────────────────────────────────
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),

              // Logo
              FadeTransition(
                opacity: _logoFade,
                child: SlideTransition(
                  position: _logoSlide,
                  child: Center(
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      height: 72,
                      width: 72,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Título
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ingresa tu información personal',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'para crear tu cuenta',
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Campos
              FadeTransition(
                opacity: _fieldsFade,
                child: SlideTransition(
                  position: _fieldsSlide,
                  child: Column(
                    children: [
                      _buildNombreField(),
                      const SizedBox(height: 16),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Botón
              FadeTransition(
                opacity: _buttonFade,
                child: SlideTransition(
                  position: _buttonSlide,
                  child: _buildRegisterButton(),
                ),
              ),

              const SizedBox(height: 48),

              // Footer
              FadeTransition(
                opacity: _footerFade,
                child: _buildLoginLink(),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // TABLET
  // ─────────────────────────────────────────
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Panel izquierdo
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueAccent[400]!,
                  Colors.blueAccent[700]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.12,
                    child: Image.asset(
                      'lib/assets/images/login.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Center(
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'lib/assets/images/logo.png',
                            height: 90,
                            width: 90,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'GoWay',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tu plataforma de movilidad',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Panel derecho
        Expanded(
          flex: 5,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Crear cuenta',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ingresa tu información personal para crear tu cuenta',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      FadeTransition(
                        opacity: _fieldsFade,
                        child: SlideTransition(
                          position: _fieldsSlide,
                          child: Column(
                            children: [
                              _buildNombreField(),
                              const SizedBox(height: 16),
                              _buildEmailField(),
                              const SizedBox(height: 16),
                              _buildPasswordField(),
                              const SizedBox(height: 16),
                              _buildConfirmPasswordField(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _buttonFade,
                        child: SlideTransition(
                          position: _buttonSlide,
                          child: _buildRegisterButton(),
                        ),
                      ),
                      const SizedBox(height: 48),
                      FadeTransition(
                        opacity: _footerFade,
                        child: _buildLoginLink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // WIDGETS COMPARTIDOS
  // ─────────────────────────────────────────

  static const _fieldRadius = BorderRadius.all(Radius.circular(20));

  Widget _buildNombreField() {
    return TextFormField(
      controller: _nombreController,
      decoration: InputDecoration(
        labelText: 'Nombre completo',
        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: _fieldRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Colors.blueAccent[700]!,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su nombre';
        }
        if (value.length < 3) {
          return 'El nombre debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: _fieldRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Colors.blueAccent[700]!,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su correo';
        }
        if (!value.contains('@') || !value.contains('.')) {
          return 'Ingrese un correo válido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: _fieldRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Colors.blueAccent[700]!,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su contraseña';
        }
        if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirmar contraseña',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        border: OutlineInputBorder(borderRadius: _fieldRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: BorderSide(
            color: Colors.blueAccent[700]!,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: _fieldRadius,
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor confirme su contraseña';
        }
        if (value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registrarUsuario,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent[700],
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              Colors.blueAccent[700]!.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  key: ValueKey('text'),
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const LoginScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Text(
            'Inicia sesión',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
