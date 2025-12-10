import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme_provider.dart';
import '../features/patient/patient_service.dart'; // For API access if needed, or better: separate provider

class PatientSettingsScreen extends ConsumerStatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  ConsumerState<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends ConsumerState<PatientSettingsScreen> {
  // Mock state for now, will integrate with backend shortly
  bool _shareMedicalHistory = false;
  bool _notificationsEnabled = true;
  bool _localStorageEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final patient = await ref.read(patientServiceProvider).getMe();
      if (mounted) {
        setState(() {
          _shareMedicalHistory = patient.isMedicalHistoryShared;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _updatePrivacy(bool value) async {
    setState(() => _shareMedicalHistory = value);
    try {
      await ref.read(patientServiceProvider).updateMe({
        'isMedicalHistoryShared': value,
      });
    } catch (e) {
      debugPrint('Error updating privacy: $e');
      // Revert on error
      if (mounted) {
        setState(() => _shareMedicalHistory = !value);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to update setting', style: GoogleFonts.poppins())),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Dynamic Theme Colors
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final iconColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Settings & Privacy',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [const Color(0xFF0F172A), const Color(0xFF000000)]
                  : [const Color(0xFFF8F9FA), const Color(0xFFE2E8F0)],
              ),
            ),
          ),
          
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionHeader('Privacy', subTextColor),
                _buildSwitchTile(
                  icon: Icons.privacy_tip_rounded,
                  color: Colors.indigoAccent,
                  title: 'Share Medical History',
                  subtitle: 'Allow organizations to view your records',
                  value: _shareMedicalHistory,
                  onChanged: _updatePrivacy,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Appearance', subTextColor),
                _buildSwitchTile(
                  icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.purpleAccent,
                  title: isDark ? 'Dark Mode' : 'Light Mode',
                  subtitle: 'Switch between light and dark themes',
                  value: isDark,
                  onChanged: (val) {
                     ref.read(themeProvider.notifier).toggleTheme();
                  },
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Account', subTextColor),
                _buildActionTile(
                  icon: Icons.person_rounded,
                  color: Colors.blueAccent,
                  title: 'Manage Account',
                  onTap: () => context.push('/coming-soon?title=Manage%20Account'),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                ),
                _buildActionTile(
                   icon: Icons.delete_forever_rounded,
                   color: Colors.redAccent,
                   title: 'Delete Account',
                   textColor: Colors.redAccent,
                   onTap: () => context.push('/coming-soon?title=Delete%20Account'),
                   cardColor: cardColor,
                   borderColor: borderColor,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Preferences', subTextColor),
                 _buildSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  color: Colors.orangeAccent,
                  title: 'Notifications',
                  subtitle: 'Receive app notifications',
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                 _buildSwitchTile(
                  icon: Icons.storage_rounded,
                  color: Colors.tealAccent,
                  title: 'Local Storage',
                  subtitle: 'Save data locally for offline access',
                  value: _localStorageEnabled,
                  onChanged: (val) {
                    setState(() => _localStorageEnabled = val);
                  },
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Support', subTextColor),
                _buildActionTile(
                   icon: Icons.help_outline_rounded,
                   color: Colors.greenAccent,
                   title: 'Help & Feedback',
                   onTap: () => context.push('/coming-soon?title=Help'),
                   cardColor: cardColor,
                   borderColor: borderColor,
                   textColor: textColor,
                ),
                _buildActionTile(
                   icon: Icons.person_add_rounded,
                   color: Colors.pinkAccent,
                   title: 'Invite a Friend',
                   onTap: () => context.push('/coming-soon?title=Invite'),
                   cardColor: cardColor,
                   borderColor: borderColor,
                   textColor: textColor,
                ),

                 const SizedBox(height: 48),
                 Center(
                   child: Column(
                     children: [
                       Image.asset(
                         'assets/images/logo.png', 
                         width: 48, 
                         height: 48, 
                         color: isDark ? Colors.white24 : Colors.black26
                       ),
                       const SizedBox(height: 8),
                       Text(
                         'Nova Health v1.0.0',
                         style: GoogleFonts.poppins(
                           color: isDark ? Colors.white24 : Colors.black26,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         'Helpline: +1-800-NOVA-HEL\nEmail: support@novahealth.com',
                         textAlign: TextAlign.center,
                         style: GoogleFonts.poppins(
                           color: isDark ? Colors.white24 : Colors.black26,
                           fontSize: 12,
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(isDarkTheme() ? 0.5 : 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  
  bool isDarkTheme() {
    return ref.read(themeProvider) == ThemeMode.dark;
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDarkTheme() ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: subTextColor, fontSize: 12),
        ),
        trailing: Switch.adaptive(
          value: value,
          activeColor: color,
          inactiveTrackColor: isDarkTheme() ? Colors.white10 : Colors.black12,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDarkTheme() ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, 
            fontSize: 15,
            color: textColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded, 
          size: 16, 
          color: isDarkTheme() ? Colors.white24 : Colors.black26
        ),
      ),
    );
  }
}
