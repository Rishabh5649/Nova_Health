import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../core/theme_provider.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _editMode = false;

  Map<String, dynamic>? _data;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // Added email controller
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _genderCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/patients/me');
      final json = res.data as Map<String, dynamic>;
      _data = json;
      _nameCtrl.text = json['name']?.toString() ?? '';
      _emailCtrl.text = json['user']?['email']?.toString() ?? ''; // Load email
      _phoneCtrl.text = json['user']?['phone']?.toString() ?? '';
      _addressCtrl.text = json['address']?.toString() ?? '';
      _genderCtrl.text = json['gender']?.toString() ?? '';
      _bloodGroupCtrl.text = json['bloodGroup']?.toString() ?? '';
      
      final allergies = json['allergies'];
      if (allergies is List) {
        _allergiesCtrl.text = allergies.join(', ');
      }
      
      if (json['dob'] != null) {
        _dob = DateTime.tryParse(json['dob']);
      }
    } catch (_) {
      // ignore errors for now
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final Map<String, dynamic> data = {
        'name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(), // Send email
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        'allergies': _allergiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      };

      // Only send immutable fields if they are not already set in _data
      if (_data?['dob'] == null && _dob != null) {
        data['dob'] = _dob!.toIso8601String();
      }
      if (_data?['gender'] == null && _genderCtrl.text.trim().isNotEmpty) {
        data['gender'] = _genderCtrl.text.trim();
      }
      if (_data?['bloodGroup'] == null && _bloodGroupCtrl.text.trim().isNotEmpty) {
        data['bloodGroup'] = _bloodGroupCtrl.text.trim();
      }

      await dio.patch('/patients/me', data: data);
      await _load();
      if (mounted) {
        setState(() => _editMode = false);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _calculateAge() {
    if (_dob == null) return '-';
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age.toString();
  }

  Future<void> _pickDate() async {
    // Only allow picking date if it's not already set in backend
    if (_data?['dob'] != null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Dynamic Colors
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final iconColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final inputFillColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.close : Icons.edit_outlined),
            onPressed: _loading
                ? null
                : () {
                    setState(() => _editMode = !_editMode);
                  },
          ),
        ],
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
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: Colors.indigoAccent,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildSectionHeader(context, 'Basic details', subTextColor),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                             _editMode
                              ? _buildTextField(_nameCtrl, 'Full name', Icons.person_outline, textColor, subTextColor, inputFillColor, iconColor)
                              : _buildInfoRow('Full name', _data?['name']?.toString() ?? '-', Icons.person_outline, textColor, subTextColor, iconColor),
                            Divider(color: borderColor),
                            
                            // Age & Gender Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow('Age', _calculateAge(), Icons.cake_outlined, textColor, subTextColor, iconColor),
                                ),
                                Container(width: 1, height: 40, color: borderColor),
                                Expanded(
                                  child: (_editMode && _data?['gender'] == null)
                                    ? _buildTextField(_genderCtrl, 'Gender', Icons.wc, textColor, subTextColor, inputFillColor, iconColor)
                                    : _buildInfoRow('Gender', _genderCtrl.text.isEmpty ? '-' : _genderCtrl.text, Icons.wc, textColor, subTextColor, iconColor),
                                ),
                              ],
                            ),
                            Divider(color: borderColor),
                            
                            // DOB (Immutable if set)
                            GestureDetector(
                              onTap: (_editMode && _data?['dob'] == null) ? _pickDate : null,
                              child: AbsorbPointer(
                                child: _buildInfoRow(
                                  'Date of Birth', 
                                  _dob == null ? (_editMode ? 'Tap to select' : '-') : _dob!.toIso8601String().split('T')[0], 
                                  Icons.calendar_today_rounded, 
                                  textColor, 
                                  subTextColor, 
                                  iconColor
                                ),
                              ),
                            ),
                            if (_editMode && _data?['dob'] != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 40, bottom: 8),
                                child: Text('Cannot be changed', style: TextStyle(fontSize: 10, color: Colors.redAccent.withOpacity(0.8))),
                              ),

                            Divider(color: borderColor),
                            
                            // Blood Group (Immutable if set)
                            (_editMode && _data?['bloodGroup'] == null)
                              ? _buildTextField(_bloodGroupCtrl, 'Blood Group', Icons.bloodtype_outlined, textColor, subTextColor, inputFillColor, iconColor)
                              : _buildInfoRow('Blood Group', _bloodGroupCtrl.text.isEmpty ? '-' : _bloodGroupCtrl.text, Icons.bloodtype, textColor, subTextColor, iconColor),
                            if (_editMode && _data?['bloodGroup'] != null)
                               Padding(
                                padding: const EdgeInsets.only(left: 40, bottom: 8),
                                child: Text('Cannot be changed', style: TextStyle(fontSize: 10, color: Colors.redAccent.withOpacity(0.8))),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Medical Info', subTextColor),
                      const SizedBox(height: 12),
                       Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            _editMode 
                              ? _buildTextField(_allergiesCtrl, 'Allergies (comma separated)', Icons.warning_amber_rounded, textColor, subTextColor, inputFillColor, iconColor)
                              : _buildInfoRow('Allergies', _allergiesCtrl.text.isEmpty ? '-' : _allergiesCtrl.text, Icons.warning_amber_rounded, textColor, subTextColor, iconColor),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionHeader(context, 'Contact & Address', subTextColor),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            _editMode
                              ? _buildTextField(_emailCtrl, 'Email', Icons.email_outlined, textColor, subTextColor, inputFillColor, iconColor, keyboardType: TextInputType.emailAddress)
                              : _buildInfoRow('Email', _data?['user']?['email']?.toString() ?? '-', Icons.email_outlined, textColor, subTextColor, iconColor),
                             Divider(color: borderColor),
                            _editMode
                              ? _buildTextField(_phoneCtrl, 'Phone', Icons.phone_outlined, textColor, subTextColor, inputFillColor, iconColor, keyboardType: TextInputType.phone)
                              : _buildInfoRow('Phone', _data?['user']?['phone']?.toString() ?? '-', Icons.phone_outlined, textColor, subTextColor, iconColor),
                             Divider(color: borderColor),
                             _editMode
                              ? _buildTextField(_addressCtrl, 'Address', Icons.location_on_outlined, textColor, subTextColor, inputFillColor, iconColor, maxLines: 3)
                              : _buildInfoRow('Address', _data?['address']?.toString() ?? '-', Icons.location_on_outlined, textColor, subTextColor, iconColor),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      if (_editMode)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1), // Indigo
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            icon: _saving
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text('Save Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.7),
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color textColor, Color subTextColor, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(color: subTextColor, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.poppins(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    Color textColor, 
    Color subTextColor, 
    Color fillColor, 
    Color iconColor,
    {TextInputType? keyboardType, int maxLines = 1}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: textColor),
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor),
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: subTextColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
        ),
      ),
    );
  }
}
