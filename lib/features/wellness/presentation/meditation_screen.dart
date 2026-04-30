import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/features/wellness/presentation/meditation_session_page.dart';

class MeditationScreen extends StatefulWidget {
  final VoidCallback onBack;

  const MeditationScreen({super.key, required this.onBack});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  final Color primaryColor = const Color(0xFF2F7D6D);
  final Color bgColor = const Color(0xFFF9FAFB);
  final Color secondaryText = const Color(0xFF6B7280);

  final List<Map<String, dynamic>> _relaxSessions = [
    {'title': 'Breathing Reset', 'duration': '5 min', 'icon': Icons.air_rounded},
    {'title': 'Focus Booster', 'duration': '8 min', 'icon': Icons.center_focus_strong_rounded},
    {'title': 'Stress Release', 'duration': '10 min', 'icon': Icons.spa_rounded},
    {'title': 'Morning Energy', 'duration': '6 min', 'icon': Icons.wb_sunny_rounded},
  ];

  final List<Map<String, dynamic>> _sleepSessions = [
    {'title': 'Deep Sleep Relaxation', 'duration': '20 min', 'icon': Icons.nights_stay_rounded},
    {'title': 'Night Calm', 'duration': '10 min', 'icon': Icons.bedtime_rounded},
  ];

  final List<Map<String, dynamic>> _recoverySessions = [
    {'title': 'Ocean Breath', 'duration': '10 min', 'icon': Icons.water_rounded},
    {'title': 'Forest Healing', 'duration': '12 min', 'icon': Icons.park_rounded},
    {'title': 'Body Awareness', 'duration': '15 min', 'icon': Icons.accessibility_new_rounded},
    {'title': 'Positive Mindset', 'duration': '7 min', 'icon': Icons.sentiment_very_satisfied_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D1B20), size: 20),
        ),
        title: Text(
          "Meditation",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF1D1B20),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                FadeInDown(child: _buildMindStatus()),
                const SizedBox(height: 32),
                FadeInUp(delay: const Duration(milliseconds: 100), child: _buildRecommended()),
                const SizedBox(height: 32),
                FadeInUp(delay: const Duration(milliseconds: 200), child: _buildCategoryList("Relax", _relaxSessions)),
                const SizedBox(height: 24),
                FadeInUp(delay: const Duration(milliseconds: 300), child: _buildCategoryList("Sleep", _sleepSessions)),
                const SizedBox(height: 24),
                FadeInUp(delay: const Duration(milliseconds: 400), child: _buildCategoryList("Recovery", _recoverySessions)),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMindStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Mind Today",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.self_improvement_rounded, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Moderate",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "A short breathing exercise could help clear your thoughts.",
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommended() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommended Session",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.air_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "5 min",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Breathing Reset",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "A quick reset to calm your nervous system and regain focus.",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MeditationPlayerPage(
                          title: "Breathing Reset",
                          durationMinutes: 5,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Start Now",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(String category, List<Map<String, dynamic>> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 16),
        ...sessions.map((session) => _buildSessionItem(session)),
      ],
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    return GestureDetector(
      onTap: () {
        int minutes = int.tryParse(session['duration'].split(' ')[0]) ?? 5;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeditationPlayerPage(
              title: session['title'],
              durationMinutes: minutes,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(session['icon'], color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['title'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session['duration'],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded, color: primaryColor, size: 32),
          ],
        ),
      ),
    );
  }
}
