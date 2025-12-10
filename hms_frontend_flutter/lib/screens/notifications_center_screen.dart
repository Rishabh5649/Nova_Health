import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/notifications_service.dart';

class NotificationsCenterScreen extends ConsumerStatefulWidget {
  const NotificationsCenterScreen({super.key});

  @override
  ConsumerState<NotificationsCenterScreen> createState() => _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends ConsumerState<NotificationsCenterScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(notificationsServiceProvider).getAll();
      if (mounted) {
        setState(() {
          _notifications = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No notifications', style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    final isRead = n['read'] == true;
                    final type = n['type'] ?? 'SYSTEM';
                    final date = DateTime.tryParse(n['createdAt'] ?? '') ?? DateTime.now();

                    IconData icon;
                    Color color;
                    if (type == 'APPOINTMENT') {
                      icon = Icons.calendar_today_rounded;
                      color = Colors.blue;
                    } else if (type == 'PROMO') {
                      icon = Icons.local_offer_rounded;
                      color = Colors.orange;
                    } else {
                      icon = Icons.info_rounded;
                      color = Colors.purple;
                    }

                    return Card(
                      elevation: isRead ? 0 : 2,
                      color: isRead ? Colors.transparent : Theme.of(context).cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isRead ? BorderSide(color: Colors.grey.withOpacity(0.2)) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        title: Text(
                          n['title'] ?? 'Notification',
                          style: GoogleFonts.poppins(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(n['message'] ?? ''),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM d, h:mm a').format(date),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () async {
                           if (!isRead) {
                             await ref.read(notificationsServiceProvider).markAsRead(n['id']);
                             // refresh locally
                             setState(() {
                               n['read'] = true;
                             });
                           }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
