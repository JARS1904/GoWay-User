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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'terms_and_conditions_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final Function(bool)? onThemeChange;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.onThemeChange,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: isTablet
          ? null
          : AppBar(
              title: const Text(
                'Mi Perfil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              elevation: 0.8,
              backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Cerrar sesión',
                  onPressed: _showLogoutDialog,
                ),
              ],
            ),
      body: isTablet ? _buildTabletLayout(isDark) : _buildMobileLayout(isDark),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userEmail,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            _buildProfileOption(
              icon: Icons.person_outline,
              title: 'Editar Perfil',
              onTap: () => _showEditProfileDialog(),
              isDark: isDark,
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
              isDark: isDark,
            ),
            _buildProfileOption(
              icon: Icons.settings,
              title: 'Configuración',
              onTap: () => _navigateToSettings(context),
              isDark: isDark,
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

  Widget _buildTabletLayout(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Card(
          elevation: 8,
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.userEmail,
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: VerticalDivider(
                    thickness: 1,
                    width: 1,
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                ),

                // Columna derecha - Opciones del perfil
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Opciones del Perfil',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildProfileOption(
                        icon: Icons.person_outline,
                        title: 'Editar Perfil',
                        onTap: () => _showEditProfileDialog(),
                        tabletMode: true,
                        isDark: isDark,
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
                        isDark: isDark,
                      ),
                      _buildProfileOption(
                        icon: Icons.settings,
                        title: 'Configuración',
                        onTap: () => _navigateToSettings(context),
                        tabletMode: true,
                        isDark: isDark,
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
    bool isDark = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: tabletMode ? 8 : 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: tabletMode ? 30 : 24,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
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
    // Remover token y datos de sesión
    await prefs.remove('authToken');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('rememberMe');
    debugPrint('Sesión cerrada: authToken removido');

    if (!mounted) return;

    // Usar pushReplacementNamed para limpiar el stack de navegación
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onThemeChange: widget.onThemeChange,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Limpiar SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Ir a la pantalla de login
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
