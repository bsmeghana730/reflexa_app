import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/bluetooth_service.dart';
import 'package:reflexa_app/features/therapy/presentation/session_summary_page.dart';

enum ExerciseState {
  initial,
  waitingForBt,
  calibrating,
  instruction,
  adjusting,  // Waiting for user to reach correct position
  holding,    // "Correct" confirmation
  countdown,  // Live 5→1 countdown
  success,    // "Good job" + "Relax"
  completed,
}

enum LegSide { left, right }

class EventDrivenExercisePage extends StatefulWidget {
  final String exerciseName;
  final int exerciseId;
  final int assignmentId;
  final List<String> instructions;
  final int reps;
  final String? targetRange;

  const EventDrivenExercisePage({
    super.key,
    required this.exerciseName,
    required this.exerciseId,
    required this.assignmentId,
    required this.instructions,
    required this.reps,
    this.targetRange,
  });

  @override
  State<EventDrivenExercisePage> createState() => _EventDrivenExercisePageState();
}

class _EventDrivenExercisePageState extends State<EventDrivenExercisePage> {
  final FlutterTts _flutterTts = FlutterTts();
  final AppBluetoothService _bluetoothService = AppBluetoothService();
  StreamSubscription<BleEvent>? _bluetoothSubscription;

  int _currentStepIndex = 0;
  int _currentRep = 0;
  ExerciseState _state = ExerciseState.initial;
  int _countdownValue = 0;

  Color _statusColor = const Color(0xFFA7D42C);
  String _feedbackText = "Initializing...";
  String? _connectingDeviceId;
  bool _isIdle = true; 
  bool _isPaused = false;

  bool _isCalibrated = false;

  // Always holds the LATEST live sensor reading — updated by BT listener continuously
  SensorMessage _latestSensor = SensorMessage.none;

  // Analytics
  int _correctMoves = 0;
  int _totalMoves = 0;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initTts();
    _initBluetoothListener();
    _bluetoothService.ensureDiscovery(); 
    _reconfigureAndStart();
  }

  Future<void> _reconfigureAndStart() async {
    if (_bluetoothService.isConnected) {
      await _bluetoothService.configureExercise("stop", "medium", 0);
    }
  }

  void _manualStart() {
    setState(() {
      _isIdle = false;
      _isPaused = false;
    });
    
    if (!_isCalibrated || _state == ExerciseState.completed) {
      _startExercise();
    } else {
      _runStep();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _bluetoothSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  void _initBluetoothListener() {
    _bluetoothSubscription = _bluetoothService.messageStream.listen((event) {
      if (_isPaused) return;
      
      if (event.type == SensorMessage.repDetected) {
        return;
      }

      if (event.type == SensorMessage.sessionComplete) {
        _finishExercise();
        return;
      }

      setState(() {
        _latestSensor = event.type;
      });
    });

    _bluetoothService.connectionStream.listen((isConnected) {
      if (!isConnected) {
        setState(() => _latestSensor = SensorMessage.none);
      }
      if (isConnected && _state == ExerciseState.waitingForBt) {
        setState(() => _state = ExerciseState.calibrating);
        _runCalibration();
      }
    });
  }

  void _startExercise() {
    setState(() {
      _currentStepIndex = 0;
      _currentRep = 0;
      _state = ExerciseState.initial;
      _isCalibrated = true;
      _isIdle = false;
    });
    
    _runStep();
  }

  Future<void> _runCalibration() async {
    await _speak("Connect your sensor.");
    while (_latestSensor == SensorMessage.none && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) {
      setState(() => _state = ExerciseState.calibrating);
      await _speak("Preparing session.");
      
      bool isReady = false;
      while (!isReady && mounted) {
        if (_latestSensor == SensorMessage.green || _latestSensor == SensorMessage.yellow) {
          isReady = true;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (mounted) {
        setState(() {
          _state = ExerciseState.initial;
          _isCalibrated = true;
        });
        _runStep();
      }
    }
  }

  Future<void> _runStep() async {
    if (!mounted || _isIdle || _isPaused) return;

    if (_currentRep >= widget.reps) {
      _finishExercise();
      return;
    }

    final instruction = widget.instructions[_currentStepIndex % widget.instructions.length];
    final lowerText = instruction.toLowerCase();
    
    bool isAction = lowerText.contains("lift") || lowerText.contains("raise") || lowerText.contains("hold") || lowerText.contains("down") || lowerText.contains("bend");

    if (mounted) {
      setState(() {
        _state = isAction ? ExerciseState.adjusting : ExerciseState.instruction;
        _feedbackText = instruction;
      });
    }

    if (isAction) {
      if (_bluetoothService.isConnected) {
        await _bluetoothService.configureExercise(widget.exerciseName, "medium", widget.reps);
      }
    } else {
      if (_bluetoothService.isConnected) {
        await _bluetoothService.configureExercise("stop", "medium", 0);
      }
    }

    await _speak(instruction);

    await _wait(3);

    if (isAction) {
      await _adjustmentPhase();
      
      if (!mounted || _isIdle || _isPaused) return;

      if (lowerText.contains("hold")) {
        _totalMoves++;
        _correctMoves++;
        
        int holdTime = 5;
        RegExp exp = RegExp(r"(\d+)\s*(sec|second|seconds)");
        Match? match = exp.firstMatch(lowerText);
        if (match != null) holdTime = int.parse(match.group(1)!);

        setState(() {
          _state = ExerciseState.countdown;
          _countdownValue = holdTime;
        });

        await _countdownPhase(); 
      } else {
         _totalMoves++;
         _correctMoves++;
         await _wait(1);
      }
    }

    if (!mounted || _isIdle || _isPaused) return;

    _currentStepIndex++;
    
    if (_currentStepIndex != 0 && _currentStepIndex % widget.instructions.length == 0) {
      _currentRep++;
      if (mounted) {
         setState(() {
           _isIdle = true; 
           _feedbackText = "Repetition ${_currentRep}/${widget.reps} Complete.";
           _state = ExerciseState.initial;
         });
      }
      await _speak("Repetition ${_currentRep} complete. Click start to begin next repetition.");
      return; 
    }
    
    _runStep();
  }

  Future<void> _adjustmentPhase() async {
    while (mounted) {
      if (_isPaused || !_bluetoothService.isConnected) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      final sensor = _latestSensor;

      if (sensor == SensorMessage.green || sensor == SensorMessage.moveCorrect) {
        await _speak("Correct");
        return;
      } else if (sensor == SensorMessage.yellow) {
        await _speak("Almost there");
      } else if (sensor == SensorMessage.red) {
        await _speak("Adjust position");
      }

      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  Future<bool> _countdownPhase() async {
    String? lastHoldFeedback;
    final int initialCount = _countdownValue;

    while (_countdownValue > 0 && mounted) {
      if (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      final sensor = _latestSensor;
      String currentFeedbackStatus = "";
      
      // 1. Determine Posture Integrity
      if (sensor == SensorMessage.red || sensor == SensorMessage.moveWrong) {
        currentFeedbackStatus = "Adjust position";
      } else if (sensor == SensorMessage.yellow) {
        currentFeedbackStatus = "Almost there";
      } else if (sensor == SensorMessage.green || sensor == SensorMessage.moveCorrect) {
        currentFeedbackStatus = "Correct";
      }

      // 2. Control Logic: If WRONG or ALMOST CORRECT (Yellow), reset timer and prompt user
      // User request: RESET if Wrong (Red) OR Almost Correct (Yellow)
      if (currentFeedbackStatus == "Adjust position" || currentFeedbackStatus == "Almost there") {
        setState(() {
          _statusColor = (currentFeedbackStatus == "Adjust position") ? Colors.red : Colors.orange;
          _feedbackText = "Hold Reset: Maintain Perfect Position";
        });
        
        if (lastHoldFeedback != currentFeedbackStatus) {
          lastHoldFeedback = currentFeedbackStatus;
          String msg = (currentFeedbackStatus == "Adjust position") 
              ? "Posture lost. Resetting hold." 
              : "Almost correct is not enough. Resetting hold for perfect position.";
          await _speak(msg);
        }
        
        // RESET the countdown value to the original target
        _countdownValue = initialCount; 
        
        // Loop until it's perfectly Green (Correct)
        await Future.delayed(const Duration(milliseconds: 500));
        continue; 
      }

      // 3. Counting Phase: If Correct or Almost there, decrement timer
      setState(() {
        _feedbackText = "Keep Holding: $_countdownValue";
        if (currentFeedbackStatus == "Almost there") {
          _statusColor = Colors.orange;
        } else {
          _statusColor = const Color(0xFFA7D42C);
        }
      });

      // Voice Feedback for state change OR just the number
      if (currentFeedbackStatus != lastHoldFeedback) {
        lastHoldFeedback = currentFeedbackStatus;
        await _speak("$currentFeedbackStatus. $_countdownValue");
      } else {
        await _speak("$_countdownValue");
      }

      await _wait(1);
      if (mounted) {
        setState(() {
          _countdownValue--;
        });
      }
    }
    return true; 
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _wait(int seconds) async {
    int elapsed = 0;
    while (elapsed < seconds * 1000) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isPaused) elapsed += 100;
    }
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) _flutterTts.stop();
  }

  void _finishExercise() {
    if (!mounted) return;
    setState(() => _state = ExerciseState.completed);
    _speak("Well done. Session complete.");

    final duration = DateTime.now().difference(_startTime).inSeconds;
    final accuracy = _totalMoves > 0 ? (_correctMoves / _totalMoves * 100) : 100.0;

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionSummaryPage(
              exerciseName: widget.exerciseName,
              exerciseId: widget.exerciseId,
              assignmentId: widget.assignmentId,
              accuracy: accuracy,
              timeTaken: duration,
              score: _correctMoves * 10,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF0F2FF), Color(0xFFF9F0FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _visualBox(),
                      const SizedBox(height: 20),
                      _mainInstruction(),
                      const SizedBox(height: 40),
                      if (_isIdle) _startButton() else _activityVisual(),
                    ],
                  ),
                ),
              ),
              _bottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
          Column(
            children: [
              Text(widget.exerciseName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
              Text("Rep ${_currentRep}/${widget.reps}", style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _startButton() {
    return FadeInUp(
      child: Column(
        children: [
          GestureDetector(
            onTap: _manualStart,
            child: Container(
              width: 120, height: 120,
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF5C9DFF), Color(0xFF88C98E)]), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text("Click Start to Begin", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _activityVisual() {
    bool isCounting = _state == ExerciseState.countdown;
    return Column(
      children: [
        if (isCounting) 
          _timerCircle()
        else
          Pulse(
            infinite: true,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: _statusColor.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.accessibility_new, size: 50, color: _statusColor),
            ),
          ),
        const SizedBox(height: 24),
        Text(_feedbackText, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: _statusColor)),
      ],
    );
  }

  Widget _timerCircle() {
    return Column(
      children: [
        SizedBox(
          width: 120, height: 120,
          child: CircularProgressIndicator(value: _countdownValue / 5.0, strokeWidth: 8, valueColor: AlwaysStoppedAnimation<Color>(_statusColor), backgroundColor: Colors.grey.shade200),
        ),
        const SizedBox(height: 10),
        Text("$_countdownValue", style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _visualBox() {
    final name = widget.exerciseName.toLowerCase();
    String imgUrl = "assets/exercises/leg_raise.jpg";
    if (name.contains("knee")) imgUrl = "assets/exercises/knee_extension.jpg";
    if (name.contains("squat")) imgUrl = "assets/exercises/wall_squat.jpg";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset(imgUrl, height: 260, width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }

  Widget _mainInstruction() {
    final instruction = widget.instructions[_currentStepIndex % widget.instructions.length];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(instruction, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800)),
    );
  }

  Widget _bottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: _togglePause, icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.blue, size: 40)),
          const SizedBox(width: 20),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50), child: const Text("Stop", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
