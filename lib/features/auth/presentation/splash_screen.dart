import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reflexa_app/features/auth/presentation/login_screen.dart';
import 'package:reflexa_app/features/dashboard/patient_dashboard.dart';
import 'package:reflexa_app/core/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    debugPrint('SplashScreen: Starting session check...');
    
    // First, check local storage flag
    final isPersistentLoggedIn = StorageService().isLoggedIn();
    if (!isPersistentLoggedIn) {
      debugPrint('SplashScreen: Persistent login flag is false, going to login.');
      _goToLogin();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('SplashScreen: User session not found in Firebase, going to login.');
      _goToLogin();
      return;
    }

    debugPrint('SplashScreen: User found: ${user.uid}. Fetching role...');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        debugPrint('SplashScreen: User document does not exist.');
        _goToLogin();
        return;
      }

      final roleRaw = doc.data()?['role']?.toString();
      final role = roleRaw?.toLowerCase();
      debugPrint('SplashScreen: User role detected: $role');

      if (!mounted) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (role == 'patient') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientDashboard()),
          );
        } else {
          _goToLogin();
        }
      });
    } catch (e) {
      debugPrint('SplashScreen: Error during session check: $e');
      if (!mounted) return;
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    debugPrint('SplashScreen: Navigating to LoginScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEDF2F1),
              const Color(0xFFF8FAF9),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006C55).withOpacity(0.1), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo.jpeg',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "REFLEXA",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: Color(0xFF006C55),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Smart Rehabilitation System",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006C55)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
