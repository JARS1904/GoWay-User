// ██╗      ██████╗  ██████╗ ██╗███╗   ██╗
// ██║     ██╔═══██╗██╔════╝ ██║████╗  ██║
// ██║     ██║   ██║██║  ███╗██║██╔██╗ ██║
// ██║     ██║   ██║██║   ██║██║██║╚██╗██║
// ███████╗╚██████╔╝╚██████╔╝██║██║ ╚████║
// ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝  ╚═══╝
//
// login.dart - Pantalla de Autenticación
// Versión: 1.1.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:goway_user/main.dart';
import 'package:goway_user/registro_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// ---------------------------------------------------------------------------
/// [LoginScreen]
/// ---------------------------------------------------------------------------
/// Pantalla principal de autenticación de usuarios.
///
/// Responsabilidades:
/// 1. Validar credenciales mediante API REST
/// 2. Gestionar el estado del formulario de login
/// 3. Navegar a la pantalla principal después de autenticación exitosa
/// 4. Manejar errores de conexión y validación
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// ---------------------------------------------------------------------------
/// [_LoginScreenState]
/// ---------------------------------------------------------------------------
/// Estado y lógica de la pantalla de login.
///
/// Atributos:
/// - _emailController: Controlador para campo de email
/// - _passwordController: Controlador para campo de contraseña
/// - _formKey: Llave global para el formulario
/// - _isLoading: Estado de carga durante autenticación
/// - _loginApiUrl: Endpoint para autenticación
class _LoginScreenState extends State<LoginScreen> {
  // -------------------------------------------------------------------------
  // CONTROLADORES Y ESTADO
  // -------------------------------------------------------------------------
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // -------------------------------------------------------------------------
  // CONFIGURACIÓN API
  // -------------------------------------------------------------------------
  /// URL del endpoint de autenticación
  final String _loginApiUrl = "http://192.168.109.4/GoWay/api/login.php";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------------
  /// [_login]
  /// -------------------------------------------------------------------------
  /// Maneja el proceso completo de autenticación:
  /// 1. Valida el formulario
  /// 2. Realiza petición HTTP al servidor
  /// 3. Guarda datos del usuario en SharedPreferences
  /// 4. Navega a la pantalla principal
  /// 5. Maneja errores y estados de carga
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
        // -----------------------------------------------------------------
        // GUARDADO DE DATOS DE SESIÓN
        // -----------------------------------------------------------------
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'userName', responseData['user']['name'] ?? 'Usuario');
        await prefs.setString('userEmail', _emailController.text.trim());

        // -----------------------------------------------------------------
        // NAVEGACIÓN A PANTALLA PRINCIPAL
        // -----------------------------------------------------------------
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const MainNavigationWrapper()),
        );
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 140),

                // -----------------------------------------------------------
                // LOGO DE LA APLICACIÓN
                // -----------------------------------------------------------
                Image.asset(
                  'lib/assets/images/logo.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 40),

                // -----------------------------------------------------------
                // TÍTULO DE LA PANTALLA
                // -----------------------------------------------------------
                const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // -----------------------------------------------------------
                // CAMPO DE EMAIL
                // -----------------------------------------------------------
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
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
                ),
                const SizedBox(height: 25),

                // -----------------------------------------------------------
                // CAMPO DE CONTRASEÑA
                // -----------------------------------------------------------
                TextFormField(
                  controller: _passwordController,
                  //obscureText: true, // Comentado para usar la opcion de mostrar/ocultar contraseña
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
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
                ),
                const SizedBox(height: 35),

                // -----------------------------------------------------------
                // BOTÓN DE INICIAR SESIÓN
                // -----------------------------------------------------------
                SizedBox(
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
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // -----------------------------------------------------------
                // ENLACE A REGISTRO
                // -----------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegistroScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Regístrate',
                        style: TextStyle(
                          color: Colors.blueAccent[700],
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
