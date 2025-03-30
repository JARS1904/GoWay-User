// ██╗   ██╗███████╗███████╗██████╗    ███████╗ ██████╗██████╗ ███████╗███████╗███╗   ██╗
// ██║   ██║██╔════╝██╔════╝██╔══██╗   ██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║
// ██║   ██║███████╗█████╗  ██████╔╝   ███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║
// ██║   ██║╚════██║██╔══╝  ██╔══██    ╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║
// ╚██████╔╝███████║███████╗██║  ██    ███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║
//  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
//
// PANTALLA DE LISTADO DE USUARIOS - GOWAY TRANSPORTE
// Versión: 1.0.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';

/// ---------------------------------------------------------------------------
/// [UserListScreen]
/// ---------------------------------------------------------------------------
/// Pantalla principal para la gestión de usuarios del sistema de transporte.
///
/// Características:
/// - Muestra lista paginada de usuarios
/// - Operaciones CRUD completas
/// - Integración con API PHP mediante HTTP
/// - Manejo de estados: loading, error, vacío
///
/// Estado:
/// - StatefulWidget para manejo de datos dinámicos
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

/// ---------------------------------------------------------------------------
/// [_UserListScreenState]
/// ---------------------------------------------------------------------------
/// Estado y lógica de la pantalla de usuarios.
///
/// Variables de estado:
/// - users: Listado actual de usuarios
/// - isLoading: Indicador de carga
/// - hasError: Indicador de error
/// - apiUrl: Endpoint de la API (ajustar IP según entorno)
class _UserListScreenState extends State<UserListScreen> {
  List<User> users = [];
  bool isLoading = true;
  bool hasError = false;
  final String apiUrl =
      "http://192.168.30.101/GoWay/api/usuarios.php"; // Asegúrate de usar la IP correcta

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Carga inicial de datos al iniciar
  }

  /// -------------------------------------------------------------------------
  /// [_fetchUsers]
  /// -------------------------------------------------------------------------
  /// Obtiene el listado de usuarios desde la API.
  ///
  /// Flujo:
  /// 1. Activa estado de carga
  /// 2. Realiza petición GET
  /// 3. Procesa respuesta (éxito/error)
  /// 4. Actualiza estado UI
  Future<void> _fetchUsers() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          users = data.map((json) => User.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Error al cargar usuarios: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showSnackbar('Error: $e');
    }
  }

  /// -------------------------------------------------------------------------
  /// [_addUser]
  /// -------------------------------------------------------------------------
  /// Agrega un nuevo usuario mediante POST.
  ///
  /// Parámetros:
  /// - user: Objeto User con datos básicos
  /// - password: Contraseña en texto plano (se hashea en backend)
  Future<void> _addUser(User user, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
            {'nombre': user.name, 'email': user.email, 'password': password}),
      );

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 201) {
        // 201 es el código para creación exitosa
        await _fetchUsers(); // Actualiza la lista
        _showSnackbar('Usuario agregado correctamente');
      } else {
        throw Exception('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Error al agregar: $e');
      print('Error detallado: $e'); // Debug
    }
  }

  /// -------------------------------------------------------------------------
  /// [_updateUser]
  /// -------------------------------------------------------------------------
  /// Actualiza un usuario existente mediante PUT.
  ///
  /// Parámetros:
  /// - user: Objeto User con datos actualizados
  /// - password: Nueva contraseña (opcional)
  Future<void> _updateUser(User user, [String password = '']) async {
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': user.id,
          'nombre': user.name,
          'email': user.email,
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        await _fetchUsers();
        _showSnackbar('Usuario actualizado correctamente');
      } else {
        throw Exception('Error al actualizar usuario: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Error al actualizar usuario: $e');
    }
  }

  /// -------------------------------------------------------------------------
  /// [_deleteUser]
  /// -------------------------------------------------------------------------
  /// Elimina un usuario mediante DELETE.
  ///
  /// Parámetros:
  /// - id: ID del usuario a eliminar
  Future<void> _deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl?id=$id'),
      );

      if (response.statusCode == 200) {
        await _fetchUsers();
        _showSnackbar('Usuario eliminado correctamente');
      } else {
        throw Exception('Error al eliminar usuario: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackbar('Error al eliminar usuario: $e');
    }
  }

  /// -------------------------------------------------------------------------
  /// [_showSnackbar]
  /// -------------------------------------------------------------------------
  /// Muestra un mensaje temporal en la parte inferior.
  ///
  /// Parámetros:
  /// - message: Texto a mostrar
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// -------------------------------------------------------------------------
  /// [_showAddUserDialog]
  /// -------------------------------------------------------------------------
  /// Muestra diálogo modal para agregar nuevo usuario.
  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUser = User(
                  id: 0, // El ID será asignado por la base de datos
                  name: nameController.text,
                  email: emailController.text,
                );
                await _addUser(newUser, passwordController.text);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// [_showEditUserDialog]
  /// -------------------------------------------------------------------------
  /// Muestra diálogo modal para editar usuario existente.
  ///
  /// Parámetros:
  /// - user: Usuario a editar
  void _showEditUserDialog(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña (opcional)'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedUser = User(
                  id: user.id,
                  name: nameController.text,
                  email: emailController.text,
                );
                await _updateUser(updatedUser, passwordController.text);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// [_showDeleteDialog]
  /// -------------------------------------------------------------------------
  /// Muestra diálogo de confirmación para eliminar usuario.
  ///
  /// Parámetros:
  /// - userId: ID del usuario a eliminar
  void _showDeleteDialog(int userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Usuario'),
          content:
              const Text('¿Estás seguro de que quieres eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteUser(userId);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// [build]
  /// -------------------------------------------------------------------------
  /// Construye la interfaz principal de la pantalla.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios GoWay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// [_buildBody]
  /// -------------------------------------------------------------------------
  /// Construye el cuerpo principal según el estado actual.
  ///
  /// Estados posibles:
  /// - Loading: Muestra indicador de carga
  /// - Error: Muestra mensaje de error y botón de reintento
  /// - Vacío: Muestra mensaje "No hay usuarios"
  /// - Listado: Muestra la lista de usuarios
  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error al cargar los usuarios'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchUsers,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados'));
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user.id.toString()),
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditUserDialog(user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(user.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
