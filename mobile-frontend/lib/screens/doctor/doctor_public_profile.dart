// Doctor public profile MVP
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';

class DoctorPublicProfileScreen extends ConsumerStatefulWidget {
  const DoctorPublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<DoctorPublicProfileScreen> createState() => _DoctorPublicProfileScreenState();
}

class _DoctorPublicProfileScreenState extends ConsumerState<DoctorPublicProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/doctors/${widget.userId}');
      
      // Fetch reviews
      List<dynamic> reviews = [];
      try {
        final reviewsRes = await dio.get('/reviews/doctor/${widget.userId}');
        reviews = reviewsRes.data as List<dynamic>;
      } catch (e) {
        debugPrint('Error loading reviews: $e');
      }
      
      if (!mounted) return;
      setState(() {
        _data = res.data as Map<String, dynamic>;
        _reviews = reviews;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading doctor profile: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = _data;
    final ratingAvg = (doc?['ratingAvg'] ?? 0).toDouble();
    final ratingCount = (doc?['ratingCount'] ?? 0).toInt();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor profile'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (doc?['name'] ?? 'Doctor').toString(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (doc?['specialties'] as List?)?.join(', ') ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Experience: ${doc?['yearsExperience'] ?? 0} years',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            if ((doc?['user']?['memberships'] as List?)?.isNotEmpty == true)
                              InkWell(
                                onTap: () {
                                  final orgId = doc?['user']['memberships'][0]['organization']['id'];
                                  if (orgId != null) {
                                    context.push('/organizations/$orgId');
                                  }
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.domain, size: 16, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      doc?['user']['memberships'][0]['organization']['name'] ?? 'Hospital',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Rating Summary Card
                  if (ratingCount > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                ratingAvg.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                              _buildStarRating(ratingAvg),
                              const SizedBox(height: 4),
                              Text(
                                '$ratingCount reviews',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  
                  Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(doc?['bio']?.toString().isNotEmpty == true
                      ? doc!['bio'].toString()
                      : 'No bio provided.'),
                  const SizedBox(height: 16),
                  Text('Qualifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text((doc?['qualifications'] as List?)?.join(', ') ?? 'Not specified'),
                  const SizedBox(height: 16),
                  Text('Base fees', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Base fee for consultation: ₹${doc?['baseFee'] ?? doc?['fees'] ?? 0}'),
                  const SizedBox(height: 24),
                  
                  // Book Appointment Button
                  FilledButton(
                    onPressed: () {
                      context.push('/appointments/book?doctorId=${doc?['userId']}');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Book appointment', style: TextStyle(fontSize: 16)),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Reviews Section
                  if (_reviews.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Patient Reviews',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_reviews.length} reviews',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Reviews List
                    ..._reviews.map((review) {
                      final rating = (review['rating'] ?? 0).toInt();
                      final comment = review['comment']?.toString() ?? '';
                      final createdAt = review['createdAt'] != null 
                        ? DateTime.parse(review['createdAt'])
                        : DateTime.now();
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
                                ),
                                Text(
                                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            if (comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                comment,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ] else if (ratingCount == 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to review this doctor',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

