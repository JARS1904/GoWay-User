// ██╗██████╗      ██████╗ █████╗ ██████╗ ██████╗
// ██║██╔══██╗    ██╔════╝██╔══██╗██╔══██╗██╔══██╗
// ██║██║  ██║    ██║     ███████║██████╔╝██║  ██║
// ██║██║  ██║    ██║     ██╔══██║██╔══██╗██║  ██║
// ██║██████╔╝    ╚██████╗██║  ██║██║  ██║██████╔╝
// ╚═╝╚═════╝      ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
//
// id_card_screen.dart - Tarjeta de Identificación Digital
// Versión: 2.0.0 | Última actualización: 23-03-2026
// Autores: José Armando Rodríguez Segovia
//          Miguel Ángel Peralta González
//          Santiago de Jesús Juarez Pérez
//          Emilio Domíngez Silva
// Mantenido por: Hydra. Inc

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:goway_user/services/api_service.dart';

/// Pantalla que muestra la tarjeta de identificación digital del usuario.
class IdCardScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;
  final int? userId;
  final String? userPhone;
  final String? userRegistrationDate;
  final String? userType;

  const IdCardScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
    this.userId,
    this.userPhone,
    this.userRegistrationDate,
    this.userType,
  });

  @override
  State<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends State<IdCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _photoLoadError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Genera el contenido del QR con los datos del usuario
  String get _qrData {
    final id = widget.userId != null
        ? '#${widget.userId.toString().padLeft(6, '0')}'
        : 'N/A';
    return 'GoWay | $id | ${widget.userName} | ${widget.userEmail}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mi Tarjeta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[100],
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCard(isDark),
                  const SizedBox(height: 20),
                  _buildHintText(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── TARJETA PRINCIPAL ───────────────────────────────────────────────────

  Widget _buildCard(bool isDark) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF1976D2),
            Color(0xFF1A88E0),
            Color(0xFF0D47A1),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: _buildDecorativeBackground()),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 18),
                  _buildUserInfo(),
                  const SizedBox(height: 18),
                  _buildCardFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ENCABEZADO (foto + logo GoWay) ──────────────────────────────────────

  Widget _buildCardHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.8), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 34,
            backgroundColor: Colors.blueAccent[200],
            backgroundImage: (widget.userPhotoUrl != null && !_photoLoadError)
                ? NetworkImage(ApiService.buildPhotoUrl(widget.userPhotoUrl)!)
                : null,
            onBackgroundImageError:
                (widget.userPhotoUrl != null && !_photoLoadError)
                    ? (_, __) {
                        if (!_photoLoadError) {
                          setState(() => _photoLoadError = true);
                        }
                      }
                    : null,
            child: (widget.userPhotoUrl == null || _photoLoadError)
                ? Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
        const Spacer(),
        // Logo GoWay
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  const Text(
                    'GoWay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Transporte Público',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            if (widget.userType != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5), width: 1),
                ),
                child: Text(
                  widget.userType!,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─── INFORMACIÓN DEL USUARIO ─────────────────────────────────────────────

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        _buildInfoLabel('NOMBRE COMPLETO'),
        const SizedBox(height: 3),
        Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),

        // Email
        _buildInfoLabel('CORREO ELECTRÓNICO'),
        const SizedBox(height: 3),
        Text(
          widget.userEmail,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),

        // Tipo de usuario
        _buildInfoLabel('TIPO DE USUARIO'),
        const SizedBox(height: 3),
        Text(
          widget.userType ?? 'Pasajero',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 14),

        // QR Code
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: QrImageView(
            data: _qrData,
            version: QrVersions.auto,
            size: 70,
            gapless: false,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1565C0),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1565C0),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ID + Fecha de registro en fila
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoLabel('ID DE USUARIO'),
                const SizedBox(height: 3),
                Text(
                  widget.userId != null
                      ? '#${widget.userId.toString().padLeft(6, '0')}'
                      : '——',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (widget.userRegistrationDate != null) ...[
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoLabel('MIEMBRO DESDE'),
                  const SizedBox(height: 3),
                  Text(
                    _formatRegistrationDate(widget.userRegistrationDate!),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            // Badge verificado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded,
                      color: Colors.greenAccent[200], size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Activo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── PIE DE TARJETA ───────────────────────────────────────────────────────

  Widget _buildCardFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Emisión: ${_today()}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildInfoLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.45),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildHintText(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline_rounded,
            size: 13, color: isDark ? Colors.grey[600] : Colors.grey[500]),
        const SizedBox(width: 5),
        Text(
          'Esta es tu identificación digital GoWay',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeBackground() {
    return CustomPaint(painter: _CardPatternPainter());
  }

  String _today() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  /// Formatea la fecha de registro (YYYY-MM-DD → DD/MM/YYYY)
  String _formatRegistrationDate(String raw) {
    try {
      final parts = raw.split(' ')[0].split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return raw;
  }
}

// ─── PAINTER DE FONDO ─────────────────────────────────────────────────────

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(Offset(size.width + 10, -10), 60.0 * i, paint);
    }

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(-20, size.height + 20), radius: 50.0 * i),
        -math.pi / 2,
        math.pi / 2,
        false,
        arcPaint,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 60
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.7, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
