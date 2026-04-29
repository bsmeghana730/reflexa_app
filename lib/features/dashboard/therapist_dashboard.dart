import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reflexa_app/features/dashboard/profile_section.dart';

class TherapistDashboard extends StatefulWidget {
  const TherapistDashboard({super.key});

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  int _selectedIndex = 0;
  static const Color primaryColor = Color(0xFF006C55);
  static const Color bgColor = Color(0xFFF8FAF9);
  static const Color borderColor = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHome(),
          _buildRequests(),
          _buildPatients(),
          _buildTracking(),
          const ProfileSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add_outlined), activeIcon: Icon(Icons.person_add), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // --- HOME TAB ---
  Widget _buildHome() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, Dr.', style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey.shade600)),
            Text('Reflexa Dashboard', style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: primaryColor)),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _featureCard('Assign Exercise', Icons.fitness_center, Colors.blue.shade50, () => setState(() => _selectedIndex = 2)),
                _featureCard('Track Progress', Icons.trending_up, Colors.orange.shade50, () => setState(() => _selectedIndex = 3)),
                _featureCard('Requests', Icons.notification_important_outlined, Colors.red.shade50, () => setState(() => _selectedIndex = 1)),
                _featureCard('Web Panel', Icons.laptop_mac, Colors.green.shade50, () {}),
              ],
            ),
            const SizedBox(height: 32),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(String title, IconData icon, Color color, VoidCallback tap) {
    return FadeInUp(
      child: GestureDetector(
        onTap: tap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Cases', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('connections')
              .where('therapistId', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'accepted')
              .limit(5)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();

            final activeCases = snapshot.data?.docs ?? [];

            if (activeCases.isEmpty) {
              return Text('No active cases', style: GoogleFonts.manrope(color: Colors.grey));
            }

            return Column(
              children: activeCases.map((doc) {
                final patientId = (doc.data() as Map<String, dynamic>)['patientId'];
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox.shrink();
                    final patientData = userSnapshot.data!.data() as Map<String, dynamic>;
                    final name = patientData['fullName'] ?? 'Unknown';
                    final disability = patientData['disabilities'] ?? 'General Recovery';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(backgroundColor: Color(0xFFEFFBF5), child: Icon(Icons.person, color: primaryColor)),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                              Text(disability, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- REQUESTS TAB ---
  Widget _buildRequests() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Patient Requests', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('connections')
            .where('therapistId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No pending requests', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, idx) {
              final connDoc = requests[idx];
              final connData = connDoc.data() as Map<String, dynamic>;
              final patientId = connData['patientId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();
                  final patientData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = patientData['fullName'] ?? 'Unknown';
                  final disability = patientData['disabilities'] ?? 'None';
                  final location = patientData['country'] ?? 'Unknown';

                  return FadeInLeft(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                                Text('$disability | $location', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _handleRequest(connDoc.id, 'accepted'),
                            child: const Text('Accept', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: () => _handleRequest(connDoc.id, 'rejected'),
                            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleRequest(String connId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('connections').doc(connId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- PATIENTS TAB ---
  Widget _buildPatients() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('My Patients', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('connections')
            .where('therapistId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final patients = snapshot.data?.docs ?? [];

          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No patients yet', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: patients.length,
            itemBuilder: (context, idx) {
              final patientId = (patients[idx].data() as Map<String, dynamic>)['patientId'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();
                  final patientData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = patientData['fullName'] ?? 'Unknown';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: primaryColor, child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                            Text('Daily Rehab • Active', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chat_bubble_outline, size: 20, color: primaryColor),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: primaryColor, child: const Icon(Icons.add)),
    );
  }

  // --- TRACKING TAB ---
  Widget _buildTracking() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('Please log in'));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Patient Tracking', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('connections')
            .where('therapistId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final patients = snapshot.data?.docs ?? [];

          if (patients.isEmpty) return Center(child: Text('No patients to track', style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600)));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: patients.length,
            itemBuilder: (context, idx) {
              final patientId = (patients[idx].data() as Map<String, dynamic>)['patientId'];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox.shrink();
                  final patientData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final name = patientData['fullName'] ?? 'Unknown';
                  return _trackCard(name, '0%', 'No sessions recorded yet');
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _trackCard(String name, String prog, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(prog, style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: primaryColor)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: 0.8, backgroundColor: bgColor, color: primaryColor, minHeight: 8),
          ),
          const SizedBox(height: 12),
          Text(status, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
