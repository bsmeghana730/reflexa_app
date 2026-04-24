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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Active Cases', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Container(
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
                  Text('John Doe', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  Text('Post-stroke Recovery', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  // --- REQUESTS TAB ---
  Widget _buildRequests() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('Patient Requests', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87)), backgroundColor: Colors.white, elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 2,
        itemBuilder: (context, idx) => FadeInLeft(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Alice Smith', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                    Text('ACL Tear | Chennai, IN', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
                  ]),
                ),
                TextButton(onPressed: () {}, child: Text('Accept', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))),
                TextButton(onPressed: () {}, child: const Text('Reject', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PATIENTS TAB ---
  Widget _buildPatients() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('My Patients', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87)), backgroundColor: Colors.white, elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 3,
        itemBuilder: (context, idx) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: primaryColor, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Patient Unit $idx', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                Text('Daily Rehab • 4 exercises', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey)),
              ]),
              const Spacer(),
              const Icon(Icons.chat_bubble_outline, size: 20, color: primaryColor),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: primaryColor, child: const Icon(Icons.add)),
    );
  }

  // --- TRACKING TAB ---
  Widget _buildTracking() {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text('Patient Tracking', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.black87)), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _trackCard('John Doe', '80%', 'Completed 4/5 sessions'),
          _trackCard('Alice Smith', '45%', 'Goal: Mobility Improvement'),
        ],
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
