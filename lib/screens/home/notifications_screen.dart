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
  
  String _searchQuery = '';
  String _selectedFilter = 'Todas'; // 'Todas', 'Leídas', 'No_leídas'

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

  List<NotificationModel> get _filteredNotifications {
    return _notifications.where((n) {
      bool matchesSearch = n.titulo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           n.mensaje.toLowerCase().contains(_searchQuery.toLowerCase());
      bool matchesFilter = true;
      String tipo = n.tipo.toLowerCase();
      
      switch (_selectedFilter) {
        case 'Alertas':
          matchesFilter = tipo == 'alerta' || tipo == 'urgente';
          break;
        case 'Promociones':
          matchesFilter = tipo == 'promocion';
          break;
        case 'Cierres':
          matchesFilter = tipo == 'cierre' || tipo == 'cierres';
          break;
        case 'General':
          matchesFilter = tipo == 'general' || tipo == 'info' || tipo == 'sistema';
          break;
        case 'Todas':
        default:
          matchesFilter = true;
          break;
      }
      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _getDateGroup(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day));

      if (difference.inDays == 0) {
        return 'Hoy';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return 'Esta semana';
      } else {
        return 'Anteriores';
      }
    } catch (e) {
      return 'Anteriores';
    }
  }



  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day));

      final timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      
      if (difference.inDays == 0) {
        return 'Hoy, $timeString';
      } else if (difference.inDays == 1) {
        return 'Ayer, $timeString';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} $timeString';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredNotifs = _filteredNotifications;
    
    // Group notifications
    Map<String, List<NotificationModel>> groupedNotifs = {};
    for (var n in filteredNotifs) {
      String group = _getDateGroup(n.fechaCreacion);
      if (!groupedNotifs.containsKey(group)) {
        groupedNotifs[group] = [];
      }
      groupedNotifs[group]!.add(n);
    }
    
    // Ordered groups
    List<String> groupOrder = ['Hoy', 'Ayer', 'Esta semana', 'Anteriores'];
    List<String> presentGroups = groupOrder.where((g) => groupedNotifs.containsKey(g)).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Notificaciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Search and Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[50], // Lighter grey for classic textfield feel
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) => setState(() => _searchQuery = value),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildFilterChip('Todas', isDark, filterValue: 'Todas'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Alertas', isDark, filterValue: 'Alertas'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Promociones', isDark, filterValue: 'Promociones'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cierres', isDark, filterValue: 'Cierres'),
                      const SizedBox(width: 8),
                      _buildFilterChip('General', isDark, filterValue: 'General'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Notifications List
                Expanded(
                  child: _notifications.isEmpty
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
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: presentGroups.length,
                          itemBuilder: (context, groupIndex) {
                            String group = presentGroups[groupIndex];
                            List<NotificationModel> groupItems = groupedNotifs[group]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                                  child: Text(
                                    group,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                ...groupItems.map((notif) => _buildNotificationItem(notif, isDark)).toList(),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark, {required String filterValue}) {
    bool isSelected = _selectedFilter == filterValue;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blueAccent[700] 
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notif, bool isDark) {
    bool isUnread = notif.leido == 0;
    
    // Pick the initial if it's a message, otherwise use icon
    String? initialLetter;
    if (notif.titulo.toLowerCase().contains("mensaje")) {
      initialLetter = "M"; // Initial for message, or we could extract sender
    }
    
    bool isExpanded = false;

    return StatefulBuilder(
      key: ValueKey(notif.hashCode),
      builder: (context, setState) {
        return Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(notif.tipo, isDark),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: initialLetter != null 
                            ? Text(
                                initialLetter, 
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold,
                                  color: _getIconColor(notif.tipo, isDark),
                                )
                              )
                            : Icon(
                                _getIconData(notif.tipo),
                                color: _getIconColor(notif.tipo, isDark),
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header info: Date and Time
                            Text(
                              _formatDateTime(notif.fechaCreacion),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Title with unread indicator
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isUnread) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 6, right: 6),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent[700],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    notif.titulo,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Message body
                            Text(
                              notif.mensaje,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                height: 1.4,
                              ),
                              maxLines: isExpanded ? null : 1,
                              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Chevron icon
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.chevron_right,
                            color: isDark ? Colors.grey[700] : Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Divider mapping the structure
            Row(
              children: [
                const SizedBox(width: 80), // offset past the icon
                Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ],
        );
      }
    );
  }

  IconData _getIconData(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
      case 'urgente':
        return Icons.warning_rounded; // Solid warning
      case 'cierre':
      case 'cierres':
        return Icons.block_outlined; // Or Icons.do_not_disturb_alt
      case 'promocion':
        return Icons.local_offer; // Solid tag
      case 'general':
      case 'info':
      case 'sistema':
      default:
        return Icons.notifications_none_rounded; // Default bell icon
    }
  }

  Color _getIconColor(String tipo, bool isDark) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
      case 'urgente':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      case 'cierre':
      case 'cierres':
        return isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
      case 'promocion':
        return isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
      case 'general':
      case 'info':
      case 'sistema':
      default:
        return isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    }
  }

  Color _getIconBackgroundColor(String tipo, bool isDark) {
    switch (tipo.toLowerCase()) {
      case 'alerta':
      case 'urgente':
        return isDark ? const Color(0xFFDC2626).withOpacity(0.2) : const Color(0xFFFEE2E2);
      case 'cierre':
      case 'cierres':
        return isDark ? const Color(0xFF4F46E5).withOpacity(0.2) : const Color(0xFFE0E7FF);
      case 'promocion':
        return isDark ? const Color(0xFFEA580C).withOpacity(0.2) : const Color(0xFFFFEDD5);
      case 'general':
      case 'info':
      case 'sistema':
      default:
        return isDark ? const Color(0xFF374151).withOpacity(0.5) : const Color(0xFFF3F4F6);
    }
  }
}
