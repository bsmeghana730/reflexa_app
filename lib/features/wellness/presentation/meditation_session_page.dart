import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/api_service.dart';

class MeditationPlayerPage extends StatefulWidget {
  final String title;
  final int durationMinutes;

  const MeditationPlayerPage({
    super.key,
    required this.title,
    required this.durationMinutes,
  });

  @override
  State<MeditationPlayerPage> createState() => _MeditationPlayerPageState();
}

class ScriptLine {
  final String text;
  final int pauseSeconds;
  ScriptLine(this.text, this.pauseSeconds);
}

class _MeditationPlayerPageState extends State<MeditationPlayerPage> with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFF2F7D6D);
  final Color bgColor = const Color(0xFFF9FAFB);
  final Color secondaryText = const Color(0xFF6B7280);

  late int _remainingSeconds;
  Timer? _sessionTimer;
  bool _isPaused = false;
  bool _isCompleted = false;

  // Breathing Animation
  late AnimationController _breathController;
  late Animation<double> _breathScale;
  String _breathText = "Get Ready";

  // Audio & TTS
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _bgAudioPlayer = AudioPlayer();
  Timer? _ttsTimer;

  List<ScriptLine> _script = [];
  int _scriptIndex = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;
    
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathScale = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );

    _setupSessionContent();
    _initAudio();
    
    // Start audio before voice narration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isPaused) _startSession();
    });
  }

  void _setupSessionContent() {
    final title = widget.title.toLowerCase();

    if (title.contains('ocean') || title.contains('water')) {
      _script = [
        ScriptLine("Sit comfortably and gently close your eyes.", 6),
        ScriptLine("Allow yourself to listen to the ocean waves...", 8),
        ScriptLine("Take a slow breath in...", 8),
        ScriptLine("And slowly breathe out...", 6),
        ScriptLine("Let your body flow like the water...", 10),
      ];
    } else if (title.contains('sleep') || title.contains('night')) {
      _script = [
        ScriptLine("Lie down gently. Let your body sink into the bed.", 8),
        ScriptLine("Slowly take a deep breath in...", 10),
        ScriptLine("Hold it gently...", 6),
        ScriptLine("And release...", 8),
        ScriptLine("Let go of the day. You are safe. You are tired.", 12),
      ];
    } else if (title.contains('forest') || title.contains('healing')) {
      _script = [
        ScriptLine("Imagine yourself surrounded by tall, quiet trees.", 8),
        ScriptLine("Gently close your eyes. Breathe in the crisp forest air.", 10),
        ScriptLine("Slowly exhale, releasing tension into the earth.", 10),
        ScriptLine("Allow yourself to heal with every breath.", 10),
      ];
    } else {
      _script = [
        ScriptLine("Sit comfortably, and gently close your eyes.", 6),
        ScriptLine("Take a slow, deep breath in...", 8),
        ScriptLine("Hold it for a moment...", 6),
        ScriptLine("And slowly breathe out...", 8),
        ScriptLine("Allow yourself to be present right here, right now.", 10),
      ];
    }
  }

  String _getAudioAssetPath() {
    final title = widget.title.toLowerCase();
    if (title.contains('ocean') || title.contains('water')) {
      return 'assets/audio/ocean.ogg';
    } else if (title.contains('sleep') || title.contains('night')) {
      return 'assets/audio/sleep.ogg';
    } else if (title.contains('forest') || title.contains('healing')) {
      return 'assets/audio/forest.ogg';
    }
    // Default ambient tone
    return 'assets/audio/ambient.ogg';
  }

  Future<void> _initAudio() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.3); // Slow rate
    await _tts.setPitch(0.9); // Soft, calm tone
    await _tts.setVolume(1.0);
    
    // Ensure iOS audio allows mixing background music with TTS voice
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
    );

    try {
      await _bgAudioPlayer.setLoopMode(LoopMode.all);
      await _bgAudioPlayer.setVolume(0.5); // Increased volume so it's clearly audible
      await _bgAudioPlayer.setAsset(_getAudioAssetPath());
      await _bgAudioPlayer.play();
    } catch (e) {
      debugPrint("Could not load background audio: $e");
    }
  }

  void _startSession() {
    _startBreathingCycle();
    _startTimer();
    _playNextScriptLine();
  }

  void _startBreathingCycle() {
    if (_isPaused || _isCompleted) return;

    setState(() => _breathText = "Inhale");
    _breathController.forward().then((_) {
      if (_isPaused || _isCompleted) return;
      
      setState(() => _breathText = "Hold");
      Future.delayed(const Duration(seconds: 3), () {
        if (_isPaused || _isCompleted) return;
        
        setState(() => _breathText = "Exhale");
        _breathController.reverse().then((_) {
          if (_isPaused || _isCompleted) return;
          Future.delayed(const Duration(seconds: 1), _startBreathingCycle);
        });
      });
    });
  }

  void _startTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _completeSession();
        }
      });
    });
  }

  void _playNextScriptLine() {
    if (_isPaused || _isCompleted) return;

    if (_scriptIndex < _script.length) {
      final line = _script[_scriptIndex];
      _tts.speak(line.text);
      _scriptIndex++;
      
      // Introduce timed pauses based on the specific line
      _ttsTimer = Timer(Duration(seconds: line.pauseSeconds), _playNextScriptLine);
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _breathController.stop();
        _bgAudioPlayer.pause();
        _tts.stop();
        _ttsTimer?.cancel();
      } else {
        _bgAudioPlayer.play();
        _startBreathingCycle();
        _playNextScriptLine();
      }
    });
  }

  void _completeSession() {
    _sessionTimer?.cancel();
    _ttsTimer?.cancel();
    _breathController.stop();
    _bgAudioPlayer.stop();
    _tts.speak("Session complete. Take a moment before you open your eyes.");
    
    setState(() {
      _isCompleted = true;
    });
  }

  Future<void> _saveMood(String mood) async {
    // In a real app, send to ApiService here
    try {
      // Mocking save: ApiService.saveMeditationSession(widget.title, widget.durationMinutes, mood);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Session saved. Mood: $mood", style: GoogleFonts.manrope())),
      );
    } catch (_) {}
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _ttsTimer?.cancel();
    _breathController.dispose();
    _bgAudioPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int m = totalSeconds ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return _buildCompletionScreen();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1D1B20)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(_remainingSeconds),
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: secondaryText,
              ),
            ),
            const Spacer(),
            // Breathing Circle
            Center(
              child: AnimatedBuilder(
                animation: _breathScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathScale.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          _breathText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: _isPaused ? "Resume" : "Pause",
                  onTap: _togglePause,
                  isPrimary: true,
                ),
                const SizedBox(width: 32),
                _buildControlButton(
                  icon: Icons.stop_rounded,
                  label: "End",
                  onTap: () {
                    _bgAudioPlayer.stop();
                    Navigator.pop(context);
                  },
                  isPrimary: false,
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onTap, required bool isPrimary}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(isPrimary ? 24 : 16),
            decoration: BoxDecoration(
              color: isPrimary ? primaryColor : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isPrimary ? primaryColor : Colors.black).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : primaryColor,
              size: isPrimary ? 32 : 24,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeInUp(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: primaryColor, size: 80),
                const SizedBox(height: 24),
                Text(
                  "Session Completed",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "You completed ${widget.durationMinutes} minutes of mindful meditation.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  "How do you feel now?",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 24),
                _buildMoodGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodGrid() {
    final moods = [
      {'label': 'Relaxed', 'icon': Icons.spa_rounded, 'color': const Color(0xFF006C55)},
      {'label': 'Better', 'icon': Icons.thumb_up_rounded, 'color': const Color(0xFF0061A4)},
      {'label': 'Same', 'icon': Icons.horizontal_rule_rounded, 'color': const Color(0xFF6B7280)},
      {'label': 'Stressed', 'icon': Icons.thunderstorm_rounded, 'color': const Color(0xFFBA1A1A)},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: moods.map((mood) {
        return GestureDetector(
          onTap: () => _saveMood(mood['label'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(mood['icon'] as IconData, color: mood['color'] as Color, size: 20),
                const SizedBox(width: 8),
                Text(
                  mood['label'] as String,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
