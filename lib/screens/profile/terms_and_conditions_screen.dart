// ██████╗ ███████╗██████╗ ███████╗██╗██╗
// ██╔══██╗██╔════╝██╔══██╗██╔════╝██║██║
// ██████╔╝█████╗  ██████╔╝█████╗  ██║██║
// ██╔═══╝ ██╔══╝  ██╔══██╗██╔══╝  ██║██║
// ██║     ███████╗██║  ██║██║     ██║███████╗
// ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
//
// terms_and_conditions_screen.dart - Pantalla de Términos y Condiciones
// Versión: 1.0.0 | Última actualización: 23-12-2025
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// [TermsAndConditionsScreen]
/// ---------------------------------------------------------------------------
/// Pantalla que muestra los Términos y Condiciones de la aplicación GoWay.
///
/// Características principales:
/// - Visualización completa de los términos en formato scrollable
/// - AppBar con navegación de vuelta atrás
/// - Logo de GoWay junto al título
/// - Secciones bien organizadas con títulos y contenido
/// - Botón "Entendido" para cerrar la pantalla
/// - Estilos consistentes con el resto de la aplicación
///
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  /// -------------------------------------------------------------------------
  /// [build]
  /// -------------------------------------------------------------------------
  /// Construye la interfaz de la pantalla de Términos y Condiciones.
  ///
  /// Incluye:
  /// - AppBar personalizado con estilo consistente
  /// - Contenido scrollable con múltiples secciones
  /// - Logo y título de bienvenida
  /// - Botón de acción para cerrar
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Términos y Condiciones',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0.8,
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: isTablet
          ? _buildTabletLayout(context, isDark)
          : _buildMobileLayout(context, isDark),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'lib/assets/images/logo.png',
                height: 40,
                width: 40,
              ),
              const SizedBox(width: 12),
              const Text(
                'Bienvenido a GoWay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0560fc),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            '1. Aceptación de términos',
            'Al usar esta aplicación, aceptas estos términos y condiciones en su totalidad. Si no estás de acuerdo con alguno de estos términos, por favor no uses la aplicación.',
            context,
          ),
          const SizedBox(height: 16),
          _buildSection(
            '2. Uso de la plataforma',
            'La aplicación está diseñada para ayudarte a encontrar rutas de transporte público de manera eficiente. Debes usar esta aplicación únicamente para fines legales y de acuerdo con estos términos.',
            context,
          ),
          const SizedBox(height: 16),
          _buildSection(
            '3. Responsabilidades del usuario',
            'Eres responsable de mantener la confidencialidad de tu cuenta y contraseña. También eres responsable de todas las actividades que ocurran bajo tu cuenta.',
            context,
          ),
          const SizedBox(height: 16),
          _buildSection(
            '4. Modificaciones de términos',
            'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios entrarán en vigor inmediatamente después de su publicación en la aplicación.',
            context,
          ),
          const SizedBox(height: 16),
          _buildSection(
            '5. Limitación de responsabilidad',
            'GoWay no se hace responsable por daños indirectos, incidentales, especiales o consecuentes derivados del uso o la imposibilidad de uso de la aplicación.',
            context,
          ),
          const SizedBox(height: 16),
          _buildSection(
            '6. Privacidad',
            'Tu privacidad es importante para nosotros. Por favor, consulta nuestra Política de Privacidad para obtener información sobre cómo recopilamos y usamos tus datos.',
            context,
          ),
          const SizedBox(height: 16),
          _buildSection(
            '7. Ley aplicable',
            'Estos términos se rigen por las leyes del país donde opera GoWay.',
            context,
          ),
          const SizedBox(height: 16),
          _buildSection(
            '8. Contacto',
            'Si tienes preguntas sobre estos términos, por favor contáctanos a través de la sección de soporte en la aplicación.',
            context,
          ),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'lib/assets/images/logo.png',
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Bienvenido a GoWay',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF0560fc),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildSection(
                '1. Aceptación de términos',
                'Al usar esta aplicación, aceptas estos términos y condiciones en su totalidad. Si no estás de acuerdo con alguno de estos términos, por favor no uses la aplicación.',
                context,
              ),
              const SizedBox(height: 20),
              _buildSection(
                '2. Uso de la plataforma',
                'La aplicación está diseñada para ayudarte a encontrar rutas de transporte público de manera eficiente. Debes usar esta aplicación únicamente para fines legales y de acuerdo con estos términos.',
                context,
              ),
              const SizedBox(height: 20),
              _buildSection(
                '3. Responsabilidades del usuario',
                'Eres responsable de mantener la confidencialidad de tu cuenta y contraseña. También eres responsable de todas las actividades que ocurran bajo tu cuenta.',
                context,
              ),
              const SizedBox(height: 20),
              _buildSection(
                '4. Modificaciones de términos',
                'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios entrarán en vigor inmediatamente después de su publicación en la aplicación.',
                context,
              ),
              const SizedBox(height: 20),
              _buildSection(
                '5. Limitación de responsabilidad',
                'GoWay no se hace responsable por daños indirectos, incidentales, especiales o consecuentes derivados del uso o la imposibilidad de uso de la aplicación.',
                context,
              ),
              const SizedBox(height: 20),
              _buildSection(
                '6. Privacidad',
                'Tu privacidad es importante para nosotros. Por favor, consulta nuestra Política de Privacidad para obtener información sobre cómo recopilamos y usamos tus datos.',
                context,
              ),
              const SizedBox(height: 20),
              _buildSection(
                '7. Ley aplicable',
                'Estos términos se rigen por las leyes del país donde opera GoWay.',
                context,
              ),
              const SizedBox(height: 20),
              _buildSection(
                '8. Contacto',
                'Si tienes preguntas sobre estos términos, por favor contáctanos a través de la sección de soporte en la aplicación.',
                context,
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// [_buildSection]
  /// -------------------------------------------------------------------------
  /// Componente reutilizable para construir una sección de los términos.
  ///
  /// Parámetros:
  /// - title: Título de la sección (ej: "1. Aceptación de Términos")
  /// - content: Contenido descriptivo de la sección
  ///
  /// Características:
  /// - Título en negrita de tamaño 16
  /// - Contenido en tamaño 14 con altura de línea mejorada
  /// - Espaciado consistente entre título y contenido
  Widget _buildSection(String title, String content, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
