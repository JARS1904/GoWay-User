// ██████╗ ███████╗ ██████╗ ██╗██████╗ ████████╗███████╗ ██████╗
// ██╔══██╗██╔════╝██╔════╝ ██║██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗
// ██████╔╝█████╗  ██║  ███╗██║██████╔╝   ██║   █████╗  ██║   ██║
// ██╔══██╗██╔══╝  ██║   ██║██║██╔══██╗   ██║   ██╔══╝  ██║   ██║
// ██║  ██║███████╗╚██████╔╝██║██║  ██║   ██║   ███████╗╚██████╔╝
// ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝
//
// PANTALLA DE REGISTRO - GOWAY TRANSPORTE
// Versión: 1.0.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

/// ---------------------------------------------------------------------------
/// [RegistroScreen]
/// ---------------------------------------------------------------------------
/// Pantalla de registro de nuevos usuarios para el sistema de transporte GoWay.
///
/// Características principales:
/// - Formulario de registro con validación
/// - Integración con API REST para creación de usuarios
/// - Diseño consistente con el tema de la aplicación
/// - Manejo de estados de carga y errores
///
/// Flujo principal:
/// 1. Usuario completa formulario
/// 2. Validación local de campos
/// 3. Envío seguro a la API
/// 4. Retroalimentación visual
/// 5. Redirección a login o manejo de errores
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

/// ---------------------------------------------------------------------------
/// [_RegistroScreenState]
/// ---------------------------------------------------------------------------
/// Estado y lógica de la pantalla de registro.
///
/// Atributos:
/// - _formKey: Clave global para el manejo del formulario
/// - _isLoading: Indicador de carga durante peticiones HTTP
/// - Controladores para campos de texto (nombre, email, contraseña, confirmación)
/// - _apiUrl: Endpoint de la API para registro
class _RegistroScreenState extends State<RegistroScreen> {
  // Controladores para los campos del formulario
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // URL de la API de registro (ajustar según configuración)
  final String _apiUrl = "http://192.168.30.101/GoWay/api/usuarios.php";

  @override
  void dispose() {
    // Limpieza de los controladores al destruir el widget
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------------
  /// [_registrarUsuario]
  /// -------------------------------------------------------------------------
  /// Maneja el proceso de registro del usuario:
  /// 1. Valida el formulario
  /// 2. Envía datos a la API
  /// 3. Maneja respuesta/errores
  ///
  /// Flujo:
  /// - Activa estado de carga
  /// - Realiza petición POST
  /// - Procesa respuesta
  /// - Navega a login o muestra errores
  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que las contraseñas coincidan
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);
      print('Respuesta del servidor: $responseData'); // Debug

      if (response.statusCode == 201) {
        // Registro exitoso - redirigir a login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        // Manejo de errores del servidor
        String errorMsg = responseData['error'] ?? 'Error en el registro';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      // Manejo de errores de conexión
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
                const SizedBox(height: 80),

                // Logo de la aplicación
                Image.asset(
                  'lib/assets/images/logo.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 40),

                // Título
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo de Nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
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
                ),
                const SizedBox(height: 25),

                // Campo de Email
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
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  //obscureText: true, // Comentado para usar el botón de mostrar/ocultar contraseña
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
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
                ),
                const SizedBox(height: 25),

                // Campo de Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  //obscureText: true, // Comentado para usar el botón de mostrar/ocultar contraseña
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
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
                ),
                const SizedBox(height: 35),

                // Botón de Registro
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registrarUsuario,
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
                            'REGISTRARSE',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Texto para ir al login si ya se tiene una cuenta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '!Ya tienes cuenta¡ ',
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
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // Elimina padding interno
                        minimumSize: Size.zero, // Reduce tamaño mínimo
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Inicia Sesión',
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
