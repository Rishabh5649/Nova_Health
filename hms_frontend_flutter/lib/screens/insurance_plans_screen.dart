import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsurancePlansScreen extends StatelessWidget {
  const InsurancePlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Insurance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFFBA68C8)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nova Protect', style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Comprehensive Coverage', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Get secure with Nova Protect. Covers hospitalization, critical illnesses, and accidental emergencies with cashless claims at 5000+ network hospitals.',
                  style: GoogleFonts.poppins(color: Colors.white, height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Get Quote Now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Available Plans', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _InsurancePlanCard(
            title: 'Individual Basic',
            coverage: '\$5,000/yr',
            premium: '\$10/mo',
            features: const ['Hospitalization', 'Pre/Post Care', 'Day Care Procedures'],
          ),
          _InsurancePlanCard(
            title: 'Family Floater',
            coverage: '\$15,000/yr',
            premium: '\$25/mo',
            features: const ['Covers 2 Adults + 2 Kids', 'Maternity Benefits', 'No Claim Bonus'],
            isRecommended: true,
          ),
          _InsurancePlanCard(
            title: 'Senior Citizen',
            coverage: '\$10,000/yr',
            premium: '\$35/mo',
            features: const ['Pre-existing Diseases Day 1', 'Ayush Treatment', 'Home Hospitalization'],
          ),
        ],
      ),
    );
  }
}

class _InsurancePlanCard extends StatelessWidget {
  final String title;
  final String coverage;
  final String premium;
  final List<String> features;
  final bool isRecommended;

  const _InsurancePlanCard({
    required this.title,
    required this.coverage,
    required this.premium,
    required this.features,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isRecommended ? Border.all(color: Colors.purple, width: 2) : Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                'RECOMMENDED',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Cover: $coverage', style: GoogleFonts.poppins(color: Colors.green[700], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(f, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(premium, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: () {}, child: const Text('Select')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
