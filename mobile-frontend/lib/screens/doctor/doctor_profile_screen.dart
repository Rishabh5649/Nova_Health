import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _specsCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();


  bool _loading = false;
  String? _userId;
  double _ratingAvg = 0;
  int _ratingCount = 0;
  String? _orgAddress;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _feeCtrl.dispose();
    _expCtrl.dispose();
    _specsCtrl.dispose();
    _qualCtrl.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final session = ref.read(authControllerProvider).session;
      if (session != null) {
        _userId = session.user['id'].toString();
        final userName = session.user['name']?.toString() ?? '';
        
        // Fetch doctor profile from backend using userId
        final dio = ref.read(apiClientProvider).dio;
        try {
          final res = await dio.get('/doctors/$_userId');
          final data = res.data as Map<String, dynamic>;
          
          if (!mounted) return;
          
          // Set name from backend data or session
          _nameCtrl.text = data['name']?.toString() ?? userName;
          _bioCtrl.text = data['bio']?.toString() ?? '';
          _feeCtrl.text = (data['fees'] ?? data['baseFee'] ?? 0).toString();
          _expCtrl.text = (data['yearsExperience'] ?? 0).toString();
          _ratingAvg = (data['ratingAvg'] ?? 0).toDouble();
          _ratingCount = (data['ratingCount'] ?? 0).toInt();
          
          final specs = (data['specialties'] as List?)?.cast<String>() ?? [];
          _specsCtrl.text = specs.join(', ');
          
          final quals = (data['qualifications'] as List?)?.cast<String>() ?? [];
          _qualCtrl.text = quals.join(', ');
          
          // Fetch organization details for address
          final orgId = session.user['memberships']?[0]?['organizationId'];
          if (orgId != null) {
            try {
              final orgRes = await dio.get('/organizations/$orgId');
              if (mounted) {
                setState(() {
                  _orgAddress = orgRes.data['address'];
                });
              }
            } catch (e) {
              debugPrint('Error fetching org details: $e');
            }
          }

        } catch (e) {
          debugPrint('Error fetching doctor profile: $e');
          if (!mounted) return;
          // If backend fetch fails, at least set the name from session
          _nameCtrl.text = userName;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      final dio = ref.read(apiClientProvider).dio;
      final data = {
        'bio': _bioCtrl.text.trim(),
        'fees': int.tryParse(_feeCtrl.text) ?? 0,
        'yearsExperience': int.tryParse(_expCtrl.text) ?? 0,
        'specialties': _specsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'qualifications': _qualCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),

      };

      // Use the /doctors/me endpoint for updating own profile
      await dio.patch('/doctors/me', data: data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      
      // Reload to show updated data
      await _loadProfile();
      
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading && _userId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  helperText: 'Name cannot be changed here',
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
                readOnly: true, 
              ),
              const SizedBox(height: 16),
              // Rating Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      _ratingAvg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($_ratingCount reviews)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioCtrl,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _feeCtrl,
                      decoration: const InputDecoration(labelText: 'Consultation Fee'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _expCtrl,
                      decoration: const InputDecoration(labelText: 'Years Experience'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specsCtrl,
                decoration: const InputDecoration(labelText: 'Specialties (comma separated)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qualCtrl,
                decoration: const InputDecoration(labelText: 'Qualifications (comma separated)'),
              ),

              if (_orgAddress != null) ...[
                const SizedBox(height: 24),
                const Text('Hospital Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(_orgAddress!),
                    subtitle: const Text('Tap to open in Maps'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () async {
                      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_orgAddress!)}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

