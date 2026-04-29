import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/api_service.dart';
import 'package:reflexa_app/features/dashboard/therapist_dashboard.dart';
import 'package:reflexa_app/features/dashboard/profile_section.dart';
import 'package:reflexa_app/features/therapy/presentation/exercise_guide_screen.dart';
import 'package:reflexa_app/features/therapy/presentation/exercise_list_screen.dart';
import 'package:reflexa_app/features/therapy/presentation/todays_session_screen.dart';
import 'package:reflexa_app/features/nutrition/presentation/meal_plan_screen.dart';
import 'package:reflexa_app/features/progress/presentation/patient_progress_screen.dart';
import 'package:reflexa_app/features/therapy/presentation/therapist_list_screen.dart';
import 'package:reflexa_app/features/wellness/presentation/meditation_screen.dart';
import 'package:reflexa_app/core/services/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  final PageController _carouselController = PageController();
  int _carouselIndex = 0;

  // Exact brand colors from the provided HTML/Existing UI
  static const Color primaryColor = Color(0xFF006C55);
  static const Color bgColor = Color(0xFFF8FAF9);
  static const Color borderColor = Color(0xFFE8E8E8);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  final int _currentUserId = 2;
  final bleService = AppBluetoothService();
  bool _isConnected = false;
  bool _isBtOff = false;
  StreamSubscription? _bleSub;
  StreamSubscription? _btStateSub;

  String _userRole = 'patient';

  @override
  void initState() {
    super.initState();
    _isConnected = bleService.isConnected;
    _bleSub = bleService.connectionStream.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
    
    _btStateSub = fbp.FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() => _isBtOff = state != fbp.BluetoothAdapterState.on);
      }
    });
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted && doc.exists) {
        setState(() => _userRole = doc.data()?['role']?.toString().toLowerCase() ?? 'patient');
      }
    }
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _btStateSub?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTherapist = _userRole == 'therapist';
    
    if (isTherapist) return const TherapistDashboard();

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          TodaysSessionScreen(
            userId: _currentUserId,
            onBack: () => setState(() => _selectedIndex = 0),
          ),
          ExerciseListScreen(onBack: () => setState(() => _selectedIndex = 0)),
          const PatientProgressScreen(),
          const ProfileSection(),
          MeditationScreen(onBack: () => setState(() => _selectedIndex = 0)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home, color: primaryColor), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Exercises'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSearchBar(),
            const SizedBox(height: 8),
            _buildConnectionStatus(),
            const SizedBox(height: 12),
            _buildBannerCarousel(),
            const SizedBox(height: 12),
            _buildDotIndicators(),
            const SizedBox(height: 24),
            _buildTherapistSection(),
            const SizedBox(height: 24),
            _buildFeatureGrid(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeInDown(
        duration: const Duration(milliseconds: 600),
        child: GestureDetector(
          onTap: () {
            if (!_isConnected) _showPairingSheet();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isConnected ? const Color(0xFFEFFBF5) : const Color(0xFFFFF4F0),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (_isConnected ? const Color(0xFF006C55) : Colors.red).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? const Color(0xFF006C55) : Colors.red,
                    boxShadow: [
                      if (_isConnected) BoxShadow(color: const Color(0xFF006C55).withOpacity(0.4), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isConnected 
                    ? "Reflexa Pod Connected" 
                    : (_isBtOff ? "Bluetooth is Off" : "Device Not Connected"),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _isConnected ? const Color(0xFF006C55) : Colors.red.shade700,
                  ),
                ),
                const Spacer(),
                if (!_isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Pair Now",
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.check_circle, size: 20, color: Color(0xFF006C55)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search exercises, sessions...',
                style: GoogleFonts.manrope(color: Colors.grey.shade400, fontSize: 15),
              ),
            ),
            const VerticalDivider(width: 24, indent: 14, endIndent: 14),
            const Icon(Icons.mic, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 200,
      child: PageView(
        controller: _carouselController,
        onPageChanged: (idx) => setState(() => _carouselIndex = idx),
        children: [
          _bannerItem(
            title: "Start Session",
            subtitle: "Stay consistent, improve daily",
            buttonText: "Start Session",
            imageUrl: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&q=80&w=800",
            onPressed: _smartStartSession,
          ),
          _bannerItem(
            title: "Exercises",
            subtitle: "Explore all exercises",
            buttonText: "View Exercises",
            imageUrl: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=800",
            onPressed: () => setState(() => _selectedIndex = 2),
          ),
          _bannerItem(
            title: "Meditation",
            subtitle: "Relax your mind",
            buttonText: "Start Meditation",
            imageUrl: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&q=80&w=800",
            onPressed: () => setState(() => _selectedIndex = 5),
          ),
          _bannerItem(
            title: "Progress",
            subtitle: "Track your recovery",
            buttonText: "View Progress",
            imageUrl: "https://images.unsplash.com/photo-1543286386-713bdd548da4?auto=format&fit=crop&q=80&w=800",
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
          _bannerItem(
            title: "Eat Healthy",
            subtitle: "Nutrition tips and meals",
            buttonText: "View Meals",
            imageUrl: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&q=80&w=800",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealPlanScreen(onBack: () => Navigator.pop(context)))),
          ),
          _bannerItem(
            title: "Session History",
            subtitle: "Review past sessions",
            buttonText: "View History",
            imageUrl: "https://images.unsplash.com/photo-1506784983877-45594efa4cbe?auto=format&fit=crop&q=80&w=800",
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _bannerItem({required String title, required String subtitle, required String buttonText, required String imageUrl, required VoidCallback onPressed, bool isBlurred = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: DecorationImage(
          image: NetworkImage(imageUrl), 
          fit: BoxFit.cover, 
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          if (isBlurred) 
            Positioned.fill(child: Container(color: Colors.blue.withOpacity(0.1))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.manrope(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                const Spacer(),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9), 
                    foregroundColor: primaryColor, 
                    elevation: 0, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(buttonText, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: List.generate(6, (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _carouselIndex == index ? 24 : 6, 
        height: 6, 
        margin: const EdgeInsets.symmetric(horizontal: 3), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: _carouselIndex == index ? primaryColor : Colors.grey.shade300,
        ),
      )),
    );
  }

  Widget _buildTherapistSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('connections')
            .where('patientId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();

          final connections = snapshot.data?.docs ?? [];
          final acceptedConn = connections.firstWhere((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'accepted', orElse: () => connections.isNotEmpty ? connections.first : null as dynamic);

          if (acceptedConn == null) {
            return _buildNoTherapistCard();
          }

          final connData = acceptedConn.data() as Map<String, dynamic>;
          final status = connData['status'];
          final therapistId = connData['therapistId'];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(therapistId).get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const SizedBox.shrink();
              final therapistData = userSnapshot.data!.data() as Map<String, dynamic>;
              final name = therapistData['fullName'] ?? 'Your Therapist';
              final specialty = therapistData['specialist'] ?? 'Specialist';

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: status == 'accepted' ? const Color(0xFFEFFBF5) : const Color(0xFFFFF9EB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(status == 'accepted' ? Icons.check_circle : Icons.hourglass_empty, color: primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status == 'accepted' ? 'My Therapist' : 'Connection Pending',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Text(
                            status == 'accepted' ? '$name • $specialty' : 'Waiting for $name to accept',
                            style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    if (status != 'accepted')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => TherapistListScreen(onBack: () => Navigator.pop(context))));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Change'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoTherapistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.medical_services_outlined, color: primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need a Therapist?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Find an expert for your recovery', style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => TherapistListScreen(onBack: () => Navigator.pop(context))));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Find'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85,
        children: [
          _featureCard(
            "Today's Session", 
            "Start your therapy session", 
            const Color(0xFFEFFBF5), 
            "https://lh3.googleusercontent.com/aida-public/AB6AXuB4n4hFbRKVrf1kBYV8HU7Zf_azQVKTEd9lz2TjN5otfBfy9oHLSNQFkwWl8xuzWgOG-vCo9kioqNDZBnevkF_jpW5U3aMf8NpSKvxUBLdaPFIDe-BCRIHOR9dycgkQTfzFwaYm9BBuiiCdTFGC0FKFM8bmxxqpJVKBuh2hgwoEuMXsORCYgbA6bA3cvsPMrJdANCnH_X7tp9hCKxZFl15U6aRYoloK-qsSMM5vhV3rPa5dS6zbcpepNALukh4UOjO_u6DpXf-lzoXk", 
            _smartStartSession,
          ),
          _featureCard(
            "Exercises", 
            "Explore all exercises", 
            const Color(0xFFFFF9EB), 
            "https://lh3.googleusercontent.com/aida-public/AB6AXuBpG63oH3c_ZLlHONjj12JSRZZpEndSMV_em4uzWpnSBvMlhPv0MkLFXp_LkSvJusci67tBN8aXuxs8TEaqgKyrQ4PE4s054v_J-sPB_XExxoR0jMmZgMrko2dE_gp0Al_DeNpI617NbEl5VhDyMN96ulnPHtsLEj-oA0ZY94ieYqzoVLqDUvoxRnJiz7ehKOxoMp7jbouOPCwwOqUNBJ8vlgULrs5drYmIBOBDLiwhl7DgTuAKLLU-rSazbBNdjvVNd1PeO7t59i6k", 
            () => setState(() => _selectedIndex = 2),
          ),
          _featureCard("Meditation", "Relax and clear your mind", const Color(0xFFF5F3FF), "https://lh3.googleusercontent.com/aida-public/AB6AXuCPqQB8oKxSI16_GbknftIeQfvwl47OLEFn_8vTL7wenqTncQ5Q5yA8RiUehOH90L560455jEEbC3t_rpVRKOYgZg6qrlNpR-dHemof6aF3S_LqbN8Ntj9unUEd6hyImYIKRqHtjWP1FNdxN-0VQIOO5hTBH3JxnduPSIOxMxg7t5cW_-LxkVxmzrQSsTc2xSWqrk9gepQ0LBcpjG8aGWBYrXXp-CznjWwixOLFyVJYu0KuWW-FkhAJ1lvKUI0zUVCURNYnxubVu0-F", () {
            setState(() => _selectedIndex = 5);
          }),
          _featureCard("Progress", "Track your recovery", const Color(0xFFF0F7FF), "https://lh3.googleusercontent.com/aida-public/AB6AXuDyF5quRTjh7mQc6VlQzwWgDNr7Nt-n6f1xWgrZSVplE59mVdu4UvdcRTPWKhhkOR9URFfX1mrvH96NHm-y4--ILib4esCw5JbIp_v3edW7k3ou92n6cLnDOiGnExXHM2WYsPEqfXjlO-aKQoh_yNdDq8uvxW_h17n3x2bn9AOfgmrc0BrNpCfvW0aXvnQj9qdwC_9eFz3w5-ApkLoEy_GCk9tZRATv0WUdQHO-m58npQp68I2iIkpwUkIFlmeQJozHiGAVjycvRNwS", () {
            setState(() => _selectedIndex = 3);
          }),
          _featureCard("Session History", "Review past sessions", const Color(0xFFFFF4F0), "https://lh3.googleusercontent.com/aida-public/AB6AXuC7ieLyfykWH5r0r7S1Np9aRL_n-RodomUYztLWYUDfj-jYlcs-uytxq2MQT-tf4fKgFo_9jxebcnsH99q6KvuS-VPReZWJjIUWMcnqrECkwt5UvBiKcQs6Kv68lvgmLdICJx-sbyLz8mm3K4aS5kGMQZUYBvy5xsMZGZmkN6urEHgJXnKRXaCZmC9gt9f2g3wSUb9epvB51ICUsV5_RevVFJNNha1qOjdV0paxmsspvP0oFEP5qvBYSMxxVCveXGLcsGsGxK66KA8U", () {
            setState(() => _selectedIndex = 3);
          }),
          _featureCard("Eat Healthy", "Nutrition tips and recipes", const Color(0xFFF2FAF6), "https://lh3.googleusercontent.com/aida-public/AB6AXuDwTs6tnRUmdnO37IfpLgRGVCh4iLFIbsPlEKuTUuf9fnSzSq0OJNGKZl7KgCzRotenPK-YC-0DxwVIJB_0cO3jDcxDSPYUSk57dxbVn6sHNUQOrC6czlMHEBtl618XFrHVxe3SeBH1H0Fi6MyhTofVmsRQ-_unrdcTyRJ3Knle6vgXfKKe8crkWGZXeuwAhZM9tGwszJDs65NOmjHL4tG5UZocWYEiS42DGqFrcujTaaw1_w037B3R1uDta2Dz6qzaOIkssmSQnKdX", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MealPlanScreen(onBack: () => Navigator.pop(context))));
          }),
        ],
      ),
    );
  }

  Widget _featureCard(String title, String sub, Color col, String url, VoidCallback tap) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: tap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Image.network(url, fit: BoxFit.contain)),
                const SizedBox(height: 12),
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF191C1B)), textAlign: TextAlign.center),
                Text(sub, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _smartStartSession() {
    setState(() => _selectedIndex = 1);
  }

  Future<void> _launchFirstAssignment() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please connect your Reflexa Pod to start the session."),
          backgroundColor: Colors.redAccent,
        ),
      );
      _showPairingSheet();
      return;
    }

    final assignments = await ApiService.getPatientAssignments(_currentUserId);
    final active = assignments.where((a) => a['status'] == 'ASSIGNED').toList();
    if (active.isNotEmpty && mounted) {
      final a = active.first;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseGuideScreen(exerciseId: a['exercise'], exerciseName: a['exercise_name'], reps: a['reps'], assignmentId: a['id'])));
    }
  }

  void _showPairingSheet({VoidCallback? onSuccess}) {
    bleService.startManualScan();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Pair Reflexa Device", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Text("Ensure your pod is turned on and nearby.", style: GoogleFonts.manrope(color: Colors.grey)),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<fbp.ScanResult>>(
                stream: bleService.scanResults,
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, idx) {
                      final r = results[idx];
                      final name = r.device.advName.isNotEmpty ? r.device.advName : r.device.platformName;
                      if (!name.toLowerCase().contains("reflexa") && !name.toLowerCase().contains("pod")) return const SizedBox.shrink();
                      
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFEFFBF5), child: Icon(Icons.bluetooth, color: primaryColor)),
                        title: Text(name, style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                        subtitle: Text(r.device.remoteId.str),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Linking Reflexa Pod...")));
                          final success = await bleService.connectToMacAddress(r.device.remoteId.str);
                          if (success && onSuccess != null) {
                            onSuccess();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => bleService.stopManualScan());
  }
}
