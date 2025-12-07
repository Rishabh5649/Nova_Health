// Notifications center placeholder screen
import 'package:flutter/material.dart';

class NotificationsCenterScreen extends StatelessWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text('Notification ${index + 1}'),
              subtitle: const Text('This is a placeholder notification.'),
            ),
          );
        },
      ),
    );
  }
}
