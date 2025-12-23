// ██████╗ ███████╗██████╗ ███████╗██╗██╗     ███████╗
// ██╔══██╗██╔════╝██╔══██╗██╔════╝██║██║     ██╔════╝
// ██████╔╝█████╗  ██████╔╝█████╗  ██║██║     █████╗
// ██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██║██║     ██╔══╝
// ██║     ███████╗██║  ██║███████╗██║███████╗███████╗
// ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝╚══════╝
//
// profile_screen.dart - Pantalla de Perfil de Usuario
// Versión: 2.0.0 | Última actualización: 29-03-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

/*
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';

/// ---------------------------------------------------------------------------
/// [ProfileScreen]
/// ---------------------------------------------------------------------------
/// Pantalla que muestra la información del usuario y permite cerrar sesión.
///
/// Características principales:
/// - Versión móvil: Diseño vertical compacto
/// - Versión tablet: Diseño expandido con mejor uso del espacio
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
  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: .8,
        backgroundColor: Colors.white,
      ),
      body:
          isTablet ? _buildTabletLayout(context) : _buildMobileLayout(context),
    );
  }

  /// -------------------------------------------------------------------------
  /// [_buildMobileLayout]
  /// -------------------------------------------------------------------------
  /// Construye la interfaz para dispositivos móviles (vertical)
  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
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
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text(
                      'Nombre',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text(
                      'Correo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarDialogoConfirmacion(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.red),
                ),
              ),
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20,
              ),
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
    );
  }

  /// -------------------------------------------------------------------------
  /// [_buildTabletLayout]
  /// -------------------------------------------------------------------------
  /// Construye la interfaz optimizada para tablets (diseño horizontal)
  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección izquierda (Avatar y botón)
            Column(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.blueAccent[700],
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarDialogoConfirmacion(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.logout, size: 22),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 40),

            // Sección derecha (Información)
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Perfil',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent[700],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildProfileInfoRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Nombre Completo',
                        value: userName,
                      ),
                      const SizedBox(height: 25),
                      _buildProfileInfoRow(
                        icon: Icons.email_outlined,
                        title: 'Correo Electrónico',
                        value: userEmail,
                      ),
                      const SizedBox(height: 25),
                      _buildProfileInfoRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Miembro desde',
                        value: 'Enero 2023', // Puedes hacerlo dinámico
                      ),
                    ],
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
  /// [_buildProfileInfoRow]
  /// -------------------------------------------------------------------------
  /// Componente reutilizable para mostrar información del perfil en tablet
  Widget _buildProfileInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Colors.blueAccent[700]),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// -------------------------------------------------------------------------
  /// [_mostrarDialogoConfirmacion]
  /// -------------------------------------------------------------------------
  /// Muestra diálogo de confirmación para cerrar sesión
  void _mostrarDialogoConfirmacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.blueAccent[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cerrarSesion(context);
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
*/

// ---------------------------------------------------------------------------
// Version alternativa (esta en desarrollo, no usar en producción)
// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'terms_and_conditions_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: isTablet
          ? null
          : AppBar(
              title: const Text(
                'Mi Perfil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              elevation: 2,
              scrolledUnderElevation: 4,
              backgroundColor: Colors.white10, // O usa el color de tu fondo
              surfaceTintColor: Colors.transparent,
            ),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blueAccent[700],
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userEmail,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Editar Perfil',
              onTap: () => _showEditProfileDialog(),
            ),
            /*
            _buildProfileOption(
              icon: Icons.history,
              title: 'Historial de Viajes',
              onTap: () => _showComingSoonSnackbar(),
            ),
            _buildProfileOption(
              icon: Icons.credit_card,
              title: 'Métodos de Pago',
              onTap: () => _showComingSoonSnackbar(),
            ),
            */
            _buildProfileOption(
              icon: Icons.description_outlined,
              title: 'Términos y condiciones',
              onTap: () => _showTermsAndConditions(),
            ),
            _buildProfileOption(
              icon: Icons.settings,
              title: 'Configuración',
              onTap: () => _showComingSoonSnackbar(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.all(40),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda - Información del perfil
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.blueAccent[700],
                        child: Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.userEmail,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Separador vertical
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: VerticalDivider(thickness: 1, width: 1),
                ),

                // Columna derecha - Opciones del perfil
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opciones del Perfil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildProfileOption(
                        icon: Icons.person_outline,
                        title: 'Editar Perfil',
                        onTap: () => _showEditProfileDialog(),
                        tabletMode: true,
                      ),
                      /*
                      _buildProfileOption(
                        icon: Icons.history,
                        title: 'Historial de Viajes',
                        onTap: () => _showComingSoonSnackbar(),
                        tabletMode: true,
                      ),
                      _buildProfileOption(
                        icon: Icons.credit_card,
                        title: 'Métodos de Pago',
                        onTap: () => _showComingSoonSnackbar(),
                        tabletMode: true,
                      ),
                      */
                      _buildProfileOption(
                        icon: Icons.description_outlined,
                        title: 'Términos y condiciones',
                        onTap: () => _showTermsAndConditions(),
                        tabletMode: true,
                      ),
                      _buildProfileOption(
                        icon: Icons.settings,
                        title: 'Configuración',
                        onTap: () => _showComingSoonSnackbar(),
                        tabletMode: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool tabletMode = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: tabletMode ? 8 : 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: tabletMode ? 28 : 24,
                color: Colors.blueAccent[700],
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: tabletMode ? 20 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: tabletMode ? 30 : 24,
              color: Colors.grey[400],
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: tabletMode ? 12 : 8,
              horizontal: tabletMode ? 16 : 8,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showComingSoonSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Próximamente! Esta función estará disponible pronto'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: widget.userName);
    final emailController = TextEditingController(text: widget.userEmail);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí iría la lógica para guardar los cambios
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Perfil actualizado correctamente')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsAndConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );
  }
}
