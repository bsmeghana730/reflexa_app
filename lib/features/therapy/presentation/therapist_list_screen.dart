import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class TherapistListScreen extends StatelessWidget {
  final VoidCallback onBack;
  const TherapistListScreen({super.key, required this.onBack});

  static const Color primaryGreen = Color(0xFF006C55);
  static const Color bgColor = Color(0xFFF8FAF9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: onBack,
        ),
        title: Text(
          'Find a Therapist',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: 4,
        itemBuilder: (context, index) {
          return FadeInUp(
            delay: Duration(milliseconds: 100 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.person, color: primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. Therapist ${index + 1}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Orthopedic Specialist • 5 Yrs Exp',
                          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Request connection logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request sent to Therapist!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Connect'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
