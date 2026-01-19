import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class OrganizationDetailsScreen extends ConsumerStatefulWidget {
  const OrganizationDetailsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrganizationDetailsScreen> createState() => _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState extends ConsumerState<OrganizationDetailsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _org;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/organizations/${widget.orgId}');
      if (mounted) {
        setState(() {
          _org = res.data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading org: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMap() async {
    if (_org == null) return;
    final lat = _org!['latitude'];
    final lng = _org!['longitude'];
    
    Uri? url;
    
    if (lat != null && lng != null) {
      // Open Google Maps with coordinates
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      // Fallback to address search
      final address = _org!['address'];
      if (address != null && address.toString().isNotEmpty) {
        url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
      }
    }

    if (url != null) {
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
           debugPrint('Could not launch $url');
        }
      } catch (e) {
        debugPrint('Error launching map: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_org == null) return const Scaffold(body: Center(child: Text('Organization not found')));

    final members = _org!['members'] as List? ?? [];
    // Filter doctors (already done in backend but good to be safe)
    final doctors = members.where((m) => m['user']['role'] == 'DOCTOR').toList();

    return Scaffold(
      appBar: AppBar(title: Text(_org!['name'] ?? 'Organization')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Info
          Text(
            _org!['name'] ?? '',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_org!['yearEstablished'] != null)
            Text(
              'Est. ${_org!['yearEstablished']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          const SizedBox(height: 8),

          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                (_org!['ratingAvg'] ?? 0.0).toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_org!['ratingCount'] ?? 0} reviews)',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Address & Map Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: _openMap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.blue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _org!['address'] ?? 'No address provided',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view on map & get directions',
                            style: TextStyle(color: Colors.blue[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Branches
          if ((_org!['branches'] as List?)?.isNotEmpty == true) ...[
             Text('Branches', style: Theme.of(context).textTheme.titleLarge),
             const SizedBox(height: 12),
             ...(_org!['branches'] as List).map((b) => Padding(
               padding: const EdgeInsets.only(bottom: 8),
               child: Row(children: [
                 const Icon(Icons.store_mall_directory, size: 20, color: Colors.grey),
                 const SizedBox(width: 12),
                 Text(b.toString(), style: const TextStyle(fontSize: 16)),
               ]),
             )),
             const SizedBox(height: 24),
          ],

          // Doctors List
          Text('Our Doctors', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Sorted by seniority',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          
          if (doctors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No doctors listed yet.'),
            )
          else
            ...doctors.map((m) {
              final user = m['user'];
              final profile = user['doctorProfile'];
              final name = user['name'] ?? 'Doctor';
              final specialties = (profile?['specialties'] as List?)?.join(', ') ?? 'General';
              final exp = profile?['yearsExperience'] ?? 0;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.person),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(specialties),
                      const SizedBox(height: 2),
                      Text('$exp years experience', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                      // Navigate to doctor profile
                      // If we are already in a stack, pushing another might be okay.
                      // Or we can replace.
                      context.push('/doctors/${user['id']}'); 
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

