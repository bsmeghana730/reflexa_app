import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class MeditationSessionPage extends StatefulWidget {
  final String title;
  final String audioUrl;

  const MeditationSessionPage({super.key, required this.title, required this.audioUrl});

  @override
  State<MeditationSessionPage> createState() => _MeditationSessionPageState();
}

class _MeditationSessionPageState extends State<MeditationSessionPage> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breatheAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  int _seconds = 4;
  bool _isExhaling = false;
  bool _isPaused = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _startSession();
  }

  void _startSession() {
    _audioPlayer.play(UrlSource(widget.audioUrl));
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    
    _breathingController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        _seconds--;
        if (_seconds < 0) {
          _isExhaling = !_isExhaling;
          _seconds = 4;
          if (_isExhaling) {
            _breathingController.reverse();
          } else {
            _breathingController.forward();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _breathingController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _audioPlayer.pause();
        _breathingController.stop();
      } else {
        _audioPlayer.resume();
        if (_isExhaling) {
          _breathingController.reverse();
        } else {
          _breathingController.forward();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF031027), // Deep space blue
          image: DecorationImage(
            image: NetworkImage("https://images.unsplash.com/photo-1475275083424-b4ff81625b60?auto=format&fit=crop&q=80&w=1200"),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildPhaseInfo(),
                const Spacer(),
                _buildBreathingCircle(),
                const Spacer(),
                _buildProgress(),
                _buildControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Text("The Sanctuary", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.mic, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPhaseInfo() {
    return Column(
      children: [
        Text(
          "PHASE 01",
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 2, color: const Color(0xFF98FFD9).withOpacity(0.8)),
        ),
        const SizedBox(height: 12),
        Text(
          _isExhaling ? "Breathe Out..." : "Breathe In...",
          style: GoogleFonts.plusJakartaSans(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _isExhaling 
              ? "Let go of all tension. Release your breath slowly and completely." 
              : "Let the air fill your chest. Focus on the gentle expansion of the circle.",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBreathingCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse animations
        _pulseCircle(320, 0.4, 8),
        _pulseCircle(280, 0.6, 6),
        
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Transform.scale(
              scale: _breatheAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF98FFD9), Color(0xFF006C55)],
                    center: Alignment(-0.3, -0.3),
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x66006C55), blurRadius: 40),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _seconds.toString().padLeft(2, '0'),
                        style: GoogleFonts.plusJakartaSans(fontSize: 64, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text("SECONDS", style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.7), letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Heart Rate Small Card
        Positioned(
          bottom: 20,
          right: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFF6750A4)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("HEART RATE", style: GoogleFonts.manrope(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey)),
                    Text("68 BPM", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pulseCircle(double size, double opacity, int seconds) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF98FFD9).withOpacity(opacity * 0.5)),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Progress", style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            Text("8 of 15 min", style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 0.53,
            minHeight: 8,
            backgroundColor: Color(0x33FFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF98FFD9)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlBtn(Icons.rotate_right, false, () {}),
        const SizedBox(width: 32),
        _controlBtn(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, true, _togglePause),
        const SizedBox(width: 32),
        _controlBtn(Icons.skip_next_rounded, false, () {}),
      ],
    );
  }

  Widget _controlBtn(IconData icon, bool primary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: primary ? 80 : 56,
        height: primary ? 80 : 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? const Color(0xFF006C55) : Colors.white.withOpacity(0.2),
        ),
        child: Icon(icon, color: Colors.white, size: primary ? 32 : 24),
      ),
    );
  }
}
