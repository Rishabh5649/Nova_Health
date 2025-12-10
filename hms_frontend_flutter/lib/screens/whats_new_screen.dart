import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final updates = [
      _UpdateItem(
        date: 'Dec 09, 2025',
        title: 'New Family Health Plan Add-ons',
        description: 'You can now add up to 6 family members to your Gold Membership! We have also added dedicated pediatric support for consistent care.',
        tag: 'PREMIUM',
        tagColor: Colors.amber[800]!,
        bgTagColor: Colors.amber[50]!,
        icon: Icons.workspace_premium_rounded,
        actionLabel: 'View Plans',
        actionRoute: '/patient/premium',
      ),
      _UpdateItem(
        date: 'Dec 07, 2025',
        title: 'Dental Coverage in Nova Protect',
        description: 'Great news! Your Nova Protect insurance plan now includes dental procedures up to \$500/year at no extra cost.',
        tag: 'INSURANCE',
        tagColor: Colors.purple,
        bgTagColor: Colors.purple[50]!,
        icon: Icons.shield_rounded,
        actionLabel: 'Check Coverage',
        actionRoute: '/patient/insurance',
      ),
      _UpdateItem(
        date: 'Dec 05, 2025',
        title: 'Faster Search Experience',
        description: 'We have completely revamped our search. You can now filter doctors by rating, distance, and fees instantly.',
        tag: 'SYSTEM',
        tagColor: Colors.blue,
        bgTagColor: Colors.blue[50]!,
        icon: Icons.bolt_rounded,
      ),
      _UpdateItem(
        date: 'Nov 28, 2025',
        title: 'Dark Mode is Here',
        description: 'Protect your eyes at night. Enable Dark Mode in settings for a comfortable viewing experience.',
        tag: 'APP',
        tagColor: Colors.grey[800]!,
        bgTagColor: Colors.grey[200]!,
        icon: Icons.dark_mode_rounded,
        actionLabel: 'Settings',
        actionRoute: '/patient/settings',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's New"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: updates.length,
        itemBuilder: (context, index) {
          final item = updates[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                    ),
                    if (index != updates.length - 1)
                      Container(
                        width: 2,
                        height: 140, // Approximate height
                        color: Colors.grey[200],
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.bgTagColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.tag,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: item.tagColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item.date,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(item.icon, size: 20, color: item.tagColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          if (item.actionLabel != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () {
                                  if (item.actionRoute != null) {
                                    context.push(item.actionRoute!);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: item.tagColor,
                                  side: BorderSide(color: item.tagColor.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  item.actionLabel!,
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _UpdateItem {
  final String date;
  final String title;
  final String description;
  final String tag;
  final Color tagColor;
  final Color bgTagColor;
  final IconData icon;
  final String? actionLabel;
  final String? actionRoute;

  _UpdateItem({
    required this.date,
    required this.title,
    required this.description,
    required this.tag,
    required this.tagColor,
     required this.bgTagColor,
    required this.icon,
    this.actionLabel,
    this.actionRoute,
  });
}
