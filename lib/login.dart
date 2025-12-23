import 'package:flutter/material.dart';
import 'package:goway_user/registro_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores y estado
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Configuración API
  final String _loginApiUrl = "http://192.168.30.101/GoWay/api/login.php";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_loginApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        
        // Guardar token de autenticación (crucial para recordar sesión)
        if (responseData['token'] != null) {
          await prefs.setString('authToken', responseData['token']);
        }
        
        await prefs.setString(
            'userName', responseData['user']['name'] ?? 'Usuario');
        await prefs.setString('userEmail', _emailController.text.trim());

        if (_rememberMe) {
          await prefs.setBool('rememberMe', true);
        }

        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? 'Error desconocido')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  // ----------------------------
  // MÓVIL (DISEÑO ORIGINAL)
  // ----------------------------
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'lib/assets/images/logo.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 40),
              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _buildEmailField(),
              const SizedBox(height: 25),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _buildRememberForgotRow(),
              const SizedBox(height: 35),
              _buildLoginButton(),
              const SizedBox(height: 20),
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // TABLET (CON COLOR DE FONDO PARA LA IMAGEN)
  // ----------------------------
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Panel izquierdo con imagen y color de fondo
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blueAccent[700]!.withValues(alpha: 0.6),
                  Colors.blueAccent[700]!.withValues(alpha: 1.0),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Imagen con opacidad
                Opacity(
                  opacity: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('lib/assets/images/login.png'),
                        scale: 1.0,
                        //fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Panel derecho con formulario
        Expanded(
          flex: 5,
          child: Container(
            color: Colors.grey[50],
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 70),
                      // Logo y textos de bienvenida alineados
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Image.asset(
                              'lib/assets/images/logo.png',
                              height: 60,
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenido a GoWay',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Ingresa tus credenciales para continuar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                      _buildEmailField(),
                      SizedBox(height: 25),
                      _buildPasswordField(),
                      SizedBox(height: 20),
                      _buildRememberForgotRow(),
                      SizedBox(height: 35),
                      _buildLoginButton(),
                      SizedBox(height: 25),
                      _buildRegisterLink(),
                      SizedBox(height: 40),
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

  // ----------------------------
  // CAMPOS DE ENTRADA
  // ----------------------------
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Correo Electrónico',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su correo';
        }
        if (!value.contains('@')) {
          return 'Ingrese un correo válido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon:
              Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      obscureText: _obscurePassword,
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

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /*
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) => setState(() => _rememberMe = value!),
            ),
            const Text('Remember me'),
          ],
        ),
        
        TextButton(
          onPressed: () {/* TODO: Add forgot password */},
          child: Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.blueAccent[700]),
          ),
        ),
        */
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'INICIAR SESIÓN',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿No tienes cuenta? '),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const RegistroScreen()),
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: Text(
            'Regístrate',
            style: TextStyle(
              color: Colors.blueAccent[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
