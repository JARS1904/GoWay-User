import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http:/127.0.0.1"; // Cambiar por tu IP local
  static const String apiUrl = "$baseUrl/goway/api/usuarios.php";

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse(apiUrl));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<void> addUser(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nombre': name,
        'email': email,
        'password': password
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add user');
    }
  }

  static Future<void> updateUser(int id, String name, String email) async {
    final response = await http.put(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': id,
        'nombre': name,
        'email': email
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  static Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl?id=$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}