import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoWay - Usuarios',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const UserListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> users = [];
  bool isLoading = true;
  bool hasError = false;
  final String apiUrl = "http://127.0.0.1/GoWay/api/usuarios.php"; // Cambiar por tu IP local

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
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
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> addUser(User user, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nombre': user.name,
          'email': user.email,
          'password': password
        }),
      );

      if (response.statusCode == 200) {
        await fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario agregado correctamente')),
        );
      } else {
        throw Exception('Failed to add user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar usuario: $e')),
      );
    }
  }

  Future<void> updateUser(User user, [String password = '']) async {
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
        await fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado correctamente')),
        );
      } else {
        throw Exception('Failed to update user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar usuario: $e')),
      );
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl?id=$id'),
      );

      if (response.statusCode == 200) {
        await fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios GoWay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUsers,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

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
              onPressed: fetchUsers,
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
      onRefresh: fetchUsers,
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
                await addUser(newUser, passwordController.text);
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

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
                await updateUser(updatedUser, passwordController.text);
                Navigator.pop(context);
              },
              child: const Text('Actualizar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(int userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Usuario'),
          content: const Text('¿Estás seguro de que quieres eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await deleteUser(userId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      name: json['nombre'],
      email: json['email'],
    );
  }
}