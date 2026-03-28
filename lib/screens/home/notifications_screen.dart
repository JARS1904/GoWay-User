import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:goway_user/models/notification_model.dart';
import 'package:goway_user/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _userId;
  final Set<int> _expandedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');

    if (_userId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final url = Uri.parse('${ApiService.notificationsUrl}?action=get_notifications&id_usuario=$_userId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> notifs = data['notificaciones'];
          setState(() {
            _notifications = notifs.map((n) => NotificationModel.fromJson(n)).toList();
            _isLoading = false;
          });
          
          _markAsRead();
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    if (_userId == null) return;
    try {
      await http.post(
        Uri.parse(ApiService.notificationsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'mark_as_read',
          'id_usuario': _userId,
        }),
      );
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No tienes notificaciones', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final isUnread = notif.leido == 0;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? (isUnread ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFF1A1A1A)) 
                            : (isUnread ? Colors.blue.withOpacity(0.04) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnread 
                              ? (isDark ? Colors.blueAccent.withOpacity(0.4) : Colors.blueAccent.withOpacity(0.2)) 
                              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
                          width: 1,
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              if (_expandedIndices.contains(index)) {
                                _expandedIndices.remove(index);
                              } else {
                                _expandedIndices.add(index);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icono con gradiente
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _getIconGradient(notif.tipo),
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getIconGradient(notif.tipo)[0].withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getIconData(notif.tipo), 
                                    color: Colors.white, 
                                    size: 20
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Contenido
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notif.titulo,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.black87,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(notif.fechaCreacion),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif.mensaje,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          height: 1.3,
                                        ),
                                        maxLines: _expandedIndices.contains(index) ? null : 2,
                                        overflow: _expandedIndices.contains(index) ? TextOverflow.visible : TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Indicador de no leído
                                if (isUnread) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    margin: const EdgeInsets.only(top: 15),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getIconData(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
      case 'urgente':
        return Icons.warning_rounded;
      case 'info':
      case 'general':
        return Icons.info_rounded;
      case 'promocion':
        return Icons.local_offer_rounded;
      case 'sistema':
        return Icons.settings_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  List<Color> _getIconGradient(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
      case 'urgente':
        return [Colors.redAccent[400]!, Colors.orangeAccent[400]!];
      case 'info':
      case 'general':
        return [Colors.blueAccent[700]!, Colors.lightBlueAccent];
      case 'promocion':
        return [Colors.orangeAccent[400]!, Colors.yellow[700]!];
      case 'sistema':
        return [Colors.blueGrey[700]!, Colors.grey[500]!];
      default:
        return [Colors.blueAccent[700]!, Colors.lightBlueAccent];
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoy, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Ayer, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
