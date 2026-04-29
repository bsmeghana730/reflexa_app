import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/api_service.dart';
import 'package:reflexa_app/features/therapy/presentation/event_driven_exercise_page.dart';
import 'package:reflexa_app/core/services/bluetooth_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:reflexa_app/features/therapy/presentation/requested_exercises_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onBack;

  const ExerciseDetailScreen({super.key, required this.exercise, required this.onBack});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final bleService = AppBluetoothService();
  bool _isConnected = false;
  StreamSubscription? _bleSub;

  @override
  void initState() {
    super.initState();
    _isConnected = bleService.isConnected;
    _bleSub = bleService.connectionStream.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }

  void _requestExercise() async {
    final patientId = 2; // Hardcoded for demo/patient1
    final exerciseId = widget.exercise['id'] ?? 0;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sending request to therapist..."), duration: Duration(seconds: 1)),
    );

    try {
      if (exerciseId > 0) {
        await ApiService.requestExercise(
          patientId, 
          exerciseId, 
          localFallbackData: widget.exercise
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Request sent for ${widget.exercise['name']}!"),
              backgroundColor: const Color(0xFF00A78E),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequestedExercisesScreen(
                onBack: () => Navigator.pop(context)
              )
            )
          );
        }
      } else {
        throw Exception("Invalid exercise ID");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Request sent for ${widget.exercise['name']}! (Local mode)"),
            backgroundColor: const Color(0xFF00A78E),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestedExercisesScreen(
              onBack: () => Navigator.pop(context)
            )
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.exercise['name'] ?? 'Exercise Name';
    String imgUrl = "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&q=80&w=800";
    final n = name.toLowerCase();
    bool isAsset = false;

    if (n.contains("leg raise")) {
      isAsset = true;
      imgUrl = "assets/exercises/leg_raise.jpg";
    } else if (n.contains("knee")) {
      isAsset = true;
      imgUrl = "assets/exercises/knee_extension.jpg";
    } else if (n.contains("squat")) {
      isAsset = true;
      imgUrl = "assets/exercises/wall_squat.jpg";
    } else if (n.contains("stretch") || n.contains("hold")) {
      isAsset = true;
      imgUrl = n.contains("plank") ? "assets/exercises/plank_hold.jpg" : "assets/exercises/stretch_hold.jpg";
    } else if (n.contains("bridge")) {
      isAsset = true;
      imgUrl = "assets/exercises/bridge_lift.jpg";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildMainImage(imgUrl, isAsset),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _buildInstructionsSection(),
                    const SizedBox(height: 24),
                    _buildBenefitsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildRequestButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1B), size: 28),
          ),
          Expanded(
            child: Text(
              widget.exercise['name'] ?? 'Leg Raise',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF191C1B),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMainImage(String url, bool isAsset) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
          ],
          image: DecorationImage(
            image: isAsset ? AssetImage(url) as ImageProvider : NetworkImage(url), 
            fit: BoxFit.cover
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.access_time_filled, "2-3 min", "Time", const Color(0xFF00A78E)),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          _statItem(Icons.fitness_center, "${widget.exercise['default_reps'] ?? 10} reps", "Reps", const Color(0xFF5C9DFF)),
          Container(width: 1, height: 40, color: Colors.grey.shade100),
          _statItem(Icons.local_fire_department, "Easy", "Level", const Color(0xFFFF6D6D)),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF191C1B))),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    final name = widget.exercise['name']?.toString().toLowerCase() ?? "";
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Instructions", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF191C1B))),
          const SizedBox(height: 16),
          ..._getInstructions(name).map((i) => _bulletPoint(i)).toList(),
        ],
      ),
    );
  }

  List<String> _getInstructions(String name) {
    final n = name.toLowerCase();
    if (n.contains("leg raise")) {
      return ["Lie flat on your back", "Bend one leg, keep other straight", "Tighten thigh muscles", "Lift straight leg slowly", "Hold for 5s", "Lower slowly", "Repeat"];
    } else if (n.contains("knee extension")) {
      return ["Sit straight on a chair", "Keep one foot on ground", "Lift other leg forward", "Straighten knee", "Hold for 5s", "Lower slowly", "Repeat"];
    } else if (n.contains("wall support squat")) {
      return ["Stand with back against wall", "Keep feet apart", "Slowly slide down", "Bend knees", "Hold for 5s", "Slide back up", "Repeat"];
    }
    return ["Follow the sensor guidance.", "Maintain steady movement.", "Hold at peak position."];
  }

  Widget _buildBenefitsSection() {
    final name = widget.exercise['name']?.toString().toLowerCase() ?? "";
    List<String> benefits = ["Improves joint health", "Accelerates recovery", "Builds functional strength"];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Benefits", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF191C1B))),
          const SizedBox(height: 16),
          ...benefits.map((b) => _bulletPoint(b)).toList(),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(height: 6, width: 6, decoration: const BoxDecoration(color: Color(0xFF00A78E), shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildRequestButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF00A78E), Color(0xFF006C55), Color(0xFF88C98E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF006C55).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _requestExercise,
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: Text(
                "Request This Exercise",
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
