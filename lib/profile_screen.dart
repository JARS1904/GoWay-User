// ██████╗ ███████╗██████╗ ███████╗██╗██╗     ███████╗
// ██╔══██╗██╔════╝██╔══██╗██╔════╝██║██║     ██╔════╝
// ██████╔╝█████╗  ██████╔╝█████╗  ██║██║     █████╗  
// ██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██║██║     ██╔══╝  
// ██║     ███████╗██║  ██║███████╗██║███████╗███████╗
// ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚══════╝
//
// profile_screen.dart - Pantalla de Perfil de Usuario
// Versión: 1.0.0 | Última actualización: ${DateTime.now().toString().substring(0, 10)}
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

/// ---------------------------------------------------------------------------
/// [ProfileScreen]
/// ---------------------------------------------------------------------------
/// Pantalla que muestra la información del usuario y permite cerrar sesión.
///
/// Características principales:
/// - Muestra avatar, nombre y email del usuario
/// - Botón para cerrar sesión con confirmación
/// - Diseño consistente con el tema de la aplicación
/// - Integración con SharedPreferences para gestión de sesión
///
/// Parámetros requeridos:
/// - userName: Nombre completo del usuario
/// - userEmail: Correo electrónico del usuario
class ProfileScreen extends StatelessWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  /// -------------------------------------------------------------------------
  /// [_cerrarSesion]
  /// -------------------------------------------------------------------------
  /// Maneja el proceso de cierre de sesión:
  /// 1. Limpia todos los datos almacenados localmente
  /// 2. Navega a la pantalla de login
  /// 3. Elimina todas las rutas anteriores del stack de navegación
  ///
  /// Parámetros:
  /// - context: Contexto de construcción para navegación
  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Elimina todos los datos de sesión

    // Navega al login y limpia el historial de navegación
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  /// -------------------------------------------------------------------------
  /// [build]
  /// -------------------------------------------------------------------------
  /// Construye la interfaz de usuario de la pantalla de perfil.
  ///
  /// Estructura visual:
  /// 1. Avatar con inicial del usuario
  /// 2. Tarjeta con información del usuario
  /// 3. Botón de cierre de sesión
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ---------------------------------------------------------------
            // Avatar del Usuario
            // ---------------------------------------------------------------
            /// Muestra un círculo con la inicial del nombre del usuario
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent[700],
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------------------------------------------------------------
            // Información del Usuario
            // ---------------------------------------------------------------
            /// Tarjeta con los detalles del usuario usando el tema de la app
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Nombre'),
                      subtitle: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Correo electrónico'),
                      subtitle: Text(
                        userEmail,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // ---------------------------------------------------------------
            // Botón de Cerrar Sesión
            // ---------------------------------------------------------------
            /// Botón destacado para cerrar sesión con diálogo de confirmación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoConfirmacion(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// [_mostrarDialogoConfirmacion]
  /// -------------------------------------------------------------------------
  /// Muestra un diálogo de confirmación antes de cerrar la sesión.
  ///
  /// Parámetros:
  /// - context: Contexto para mostrar el diálogo
  void _mostrarDialogoConfirmacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              _cerrarSesion(context); // Ejecuta el cierre de sesión
            },
            child: const Text(
              'Salir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}