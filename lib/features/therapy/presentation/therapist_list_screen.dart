import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TherapistListScreen extends StatefulWidget {
  final VoidCallback onBack;
  const TherapistListScreen({super.key, required this.onBack});

  @override
  State<TherapistListScreen> createState() => _TherapistListScreenState();
}

class _TherapistListScreenState extends State<TherapistListScreen> {
  static const Color primaryGreen = Color(0xFF006C55);
  static const Color bgColor = Color(0xFFF8FAF9);
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _handleConnect(String therapistId) async {
    if (_currentUserId == null) return;

    try {
      // Check if connection already exists
      final existing = await FirebaseFirestore.instance
          .collection('connections')
          .where('patientId', isEqualTo: _currentUserId)
          .where('therapistId', isEqualTo: therapistId)
          .get();

      if (existing.docs.isNotEmpty) {
        final status = existing.docs.first.data()['status'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request already $status')),
          );
        }
        return;
      }

      // Create new request
      await FirebaseFirestore.instance.collection('connections').add({
        'patientId': _currentUserId,
        'therapistId': therapistId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Find a Therapist',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'therapist')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          final therapists = snapshot.data?.docs ?? [];

          if (therapists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No therapists found',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: therapists.length,
            itemBuilder: (context, index) {
              final therapist = therapists[index].data() as Map<String, dynamic>;
              final therapistId = therapists[index].id;
              final name = therapist['fullName'] ?? 'Unknown';
              final specialty = therapist['specialist'] ?? 'Specialist';
              final exp = therapist['experience'] ?? 'N/A';

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
                              name,
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '$specialty • $exp Exp',
                              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('connections')
                            .where('patientId', isEqualTo: _currentUserId)
                            .where('therapistId', isEqualTo: therapistId)
                            .snapshots(),
                        builder: (context, connSnapshot) {
                          final hasConn = connSnapshot.hasData && connSnapshot.data!.docs.isNotEmpty;
                          String status = 'Connect';
                          bool isPending = false;
                          bool isAccepted = false;

                          if (hasConn) {
                            final connData = connSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            status = connData['status'] ?? 'Connect';
                            isPending = status == 'pending';
                            isAccepted = status == 'accepted';
                            status = status[0].toUpperCase() + status.substring(1);
                          }

                          return ElevatedButton(
                            onPressed: (isPending || isAccepted) ? null : () => _handleConnect(therapistId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAccepted ? Colors.grey : primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(status),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
