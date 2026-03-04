// ██╗   ██╗███████╗███████╗██████╗ 
// ██║   ██║██╔════╝██╔════╝██╔══██╗
// ██║   ██║███████╗█████╗  ██████╔╝
// ██║   ██║╚════██║██╔══╝  ██╔══██╗
// ╚██████╔╝███████║███████╗██║  ██║
//  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝
//
// MODELO DE USUARIO - GOWAY TRANSPORTE
// Versión: 1.0.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

/// ---------------------------------------------------------------------------
/// [User]
/// ---------------------------------------------------------------------------
/// Modelo de datos que representa un usuario del sistema de transporte.
///
/// Atributos:
/// - id: Identificador único del usuario (requerido)
/// - name: Nombre completo del usuario (requerido)
/// - email: Correo electrónico del usuario (requerido)
///
/// Funcionalidades:
/// - Conversión desde/hacia JSON
/// - Validación básica de tipos
class User {
  /// Identificador único del usuario en la base de datos
  final int id;

  /// Nombre completo del usuario
  final String name;

  /// Correo electrónico válido del usuario
  final String email;

  /// Constructor principal
  User({
    required this.id,
    required this.name,
    required this.email,
  });

  /// -------------------------------------------------------------------------
  /// [fromJson]
  /// -------------------------------------------------------------------------
  /// Factory constructor que crea una instancia de User desde un mapa JSON.
  ///
  /// Parámetros:
  /// - json: Mapa con las claves 'id', 'nombre' y 'email'
  ///
  /// Conversiones:
  /// - Asegura que el id sea un entero (parsea desde string si es necesario)
  /// - Mapea 'nombre' del JSON a 'name' en el modelo
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final user = User.fromJson({'id': 1, 'nombre': 'Juan', 'email': 'juan@example.com'});
  /// ```
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()), // Conversión segura a int
      name: json['nombre'], // Mapeo de nombre en español
      email: json['email'],
    );
  }

  /// -------------------------------------------------------------------------
  /// [toJson]
  /// -------------------------------------------------------------------------
  /// Convierte la instancia de User a un mapa JSON.
  ///
  /// Retorno:
  /// - Mapa con las claves 'id', 'nombre' y 'email'
  ///
  /// Notas:
  /// - 'nombre' se mantiene en español para compatibilidad con la API
  /// - Estructura compatible con el endpoint de usuarios.php
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final json = user.toJson(); 
  /// {'id': 1, 'nombre': 'Juan', 'email': 'juan@example.com'}
  /// ```
  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': name, // Conserva nombre en español para la API
    'email': email,
  };

  /// -------------------------------------------------------------------------
  /// [toString]
  /// -------------------------------------------------------------------------
  /// Representación en String del objeto User (override implícito)
  ///
  /// Útil para logging y debugging:
  /// ```dart
  /// print(user); // User{id: 1, name: Juan, email: juan@example.com}
  /// ```
  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email}';
  }

  /// -------------------------------------------------------------------------
  /// [copyWith]
  /// -------------------------------------------------------------------------
  /// Crea una copia del usuario permitiendo modificar atributos específicos.
  ///
  /// Parámetros opcionales:
  /// - id: Nuevo identificador
  /// - name: Nuevo nombre
  /// - email: Nuevo email
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// final updatedUser = user.copyWith(name: 'Juan Pérez');
  /// ```
  User copyWith({
    int? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}