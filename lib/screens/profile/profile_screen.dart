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
              centerTitle: false,
              elevation: 0,
              backgroundColor:
                  isDark ? const Color(0xFF121212) : Colors.grey[50],
              foregroundColor: isDark ? Colors.white : Colors.black,
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
            Visibility(
              visible: false,
              child: _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Editar Perfil',
                onTap: () => _showEditProfileDialog(),
                isDark: isDark,
              ),
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
                      Visibility(
                        visible: false,
                        child: _buildProfileOption(
                          icon: Icons.person_outline,
                          title: 'Editar Perfil',
                          onTap: () => _showEditProfileDialog(),
                          tabletMode: true,
                          isDark: isDark,
                        ),
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
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.blueAccent.withValues(alpha: 0.12),
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

  void _showEditProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: widget.userName);
    final emailController = TextEditingController(text: widget.userEmail);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.blueAccent[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Nombre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tu nombre completo',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blueAccent[700]!,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Correo Electrónico',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'tu.email@ejemplo.com',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1F1F1F) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.blueAccent[700]!,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Perfil actualizado correctamente',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(bool isDark, {bool tabletMode = false}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: tabletMode ? 8 : 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.red.withValues(alpha: 0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(),
          borderRadius: BorderRadius.circular(15),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.logout,
                size: tabletMode ? 28 : 24,
                color: Colors.red[600],
              ),
            ),
            title: Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontSize: tabletMode ? 20 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: tabletMode ? 30 : 24,
              color: Colors.red[400],
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

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.logout,
                          color: Colors.red[600],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¿Estás seguro que deseas cerrar sesión?',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Sesión cerrada correctamente',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red[600],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.all(16),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            // Aquí iría la lógica para cerrar sesión
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
}
