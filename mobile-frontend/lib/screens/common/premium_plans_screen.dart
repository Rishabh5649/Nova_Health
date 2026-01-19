import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PremiumPlansScreen extends StatelessWidget {
  const PremiumPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Plans')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Choose Your Plan',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock exclusive benefits and prioritize your health.',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout: Column on mobile, Row on wide screens if possible (though mobile-first assumption)
                // For this request, "3 vertical columns" suggests a comparison table style or just simple vertical cards stack on mobile.
                // Given "3 vertical columns" usually implies side-by-side on desktop, but on mobile it's tight.
                // I will use a horizontally scrollable row for "columns" or just vertical stack for better UX.
                // The prompt says "3 vertical columns the difference between all three". 
                // Let's try to make them look like columns in a row if space permits, or vertically stacked cards.
                
                if (constraints.maxWidth > 800) {
                   return Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(child: _PlanCard(
                         title: 'Telemed Plus',
                         price: '₹1,299/mo',
                         color: Colors.teal,
                         features: const ['Unlimited Video Calls', 'Free Follow-ups', 'Digital Rx'],
                         isPopular: false,
                       )),
                       const SizedBox(width: 16),
                       Expanded(child: _PlanCard(
                         title: 'Gold Membership',
                         price: '₹1,699/mo',
                         color: Colors.amber,
                         features: const ['Priority Booking', 'Zero Platform Fees', 'Priority Support', '10% Off Meds'],
                         isPopular: true,
                       )),
                       const SizedBox(width: 16),
                       Expanded(child: _PlanCard(
                         title: 'Family Health',
                         price: '₹2,499/mo',
                         color: Colors.indigo,
                         features: const ['Up to 4 Members', 'Shared Records', '20% Off Pediatrics', 'Dedicated Care Manager'],
                         isPopular: false,
                       )),
                     ],
                   );
                } else {
                   // Stack vertically on mobile
                   return Column(
                     children: [
                       _PlanCard(
                         title: 'Telemed Plus',
                         price: '₹1,299/mo',
                         color: Colors.teal,
                         features: const ['Unlimited Video Calls', 'Free Follow-ups', 'Digital Rx'],
                         isPopular: false,
                       ),
                       const SizedBox(height: 24),
                       _PlanCard(
                         title: 'Gold Membership',
                         price: '₹1,699/mo',
                         color: Colors.amber,
                         features: const ['Priority Booking', 'Zero Platform Fees', 'Priority Support', '10% Off Meds'],
                         isPopular: true,
                       ),
                       const SizedBox(height: 24),
                       _PlanCard(
                         title: 'Family Health',
                         price: '₹2,499/mo',
                         color: Colors.indigo,
                         features: const ['Up to 4 Members', 'Shared Records', '20% Off Pediatrics', 'Dedicated Care Manager'],
                         isPopular: false,
                       ),
                     ],
                   );
                }
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('Need Help Choosing?', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Our agents are here to help you find the best plan.', style: GoogleFonts.poppins(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Contact Sales'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final Color color;
  final List<String> features;
  final bool isPopular;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.color,
    required this.features,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isPopular ? color : Colors.grey[200]!, width: isPopular ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(price, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 24),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(f, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]))),
                  ],
                ),
              )),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected $title')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Choose Plan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'MOST POPULAR',
                style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
              ),
            ),
          ),
      ],
    );
  }
}
