import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:reflexa_app/core/services/api_service.dart';
import 'package:reflexa_app/core/services/bluetooth_service.dart';
import 'package:reflexa_app/features/therapy/presentation/event_driven_exercise_page.dart';

class ExerciseGuideScreen extends StatefulWidget {
  final int exerciseId;
  final String exerciseName;
  final int reps;
  final int assignmentId;

  const ExerciseGuideScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.reps,
    required this.assignmentId,
  });

  @override
  State<ExerciseGuideScreen> createState() => _ExerciseGuideScreenState();
}

class _ExerciseGuideScreenState extends State<ExerciseGuideScreen> {
  int _currentStage = 0; 
  bool _isConnected = false;
  final AppBluetoothService _bluetoothService = AppBluetoothService();
  StreamSubscription? _bleSub;

  final Map<String, dynamic> _exerciseData = {
    'Toe Tap (Circular)': {
      'devices': 6,
      'goal': 'Coordination',
      'reps': '10–15',
      'placement': 'Place 6 devices on the floor. Arrange them in a circular shape. Maintain equal spacing between all devices. Patient stands at the center.',
      'images': ['https://m.media-amazon.com/images/I/61HCl%2BZnSwL._AC_UF1000%2C1000_QL80_.jpg'],
      'instructions': ['Stand at the center', 'Wait for activation', 'Follow the sequence'],
    },
    'Straight Leg Raise (Right)': {
      'devices': 1,
      'goal': 'Leg Strength',
      'reps': '10',
      'placement': 'Place the sensor on the floor under your right knee.',
      'images': ['https://www.physio-pedia.com/images/thumb/8/8b/SLR.jpg/300px-SLR.jpg'],
      'instructions': ['Lift right leg up', 'Hold for 5s', 'Lower leg'],
    },
    'Right Leg Raise': {
      'devices': 1,
      'goal': 'Leg Strength',
      'reps': '10',
      'placement': 'Place sensor under right knee.',
      'images': ['https://www.physio-pedia.com/images/thumb/8/8b/SLR.jpg/300px-SLR.jpg'],
      'instructions': ['Lift right leg', 'Hold', 'Lower'],
    },
  };

  @override
  void initState() {
    super.initState();
    _isConnected = _bluetoothService.isConnected;
    _bleSub = _bluetoothService.connectionStream.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }

  void _nextStage() {
    setState(() {
      _currentStage++;
    });
  }

  void _showBluetoothPopup() {
    _bluetoothService.startManualScan();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Connect Reflexa Pod"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<fbp.ScanResult>>(
            stream: _bluetoothService.scanResults,
            builder: (context, snapshot) {
              final results = snapshot.data ?? [];
              if (results.isEmpty) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, idx) {
                  final r = results[idx];
                  final name = r.device.advName.isNotEmpty ? r.device.advName : r.device.platformName;
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(r.device.remoteId.str),
                    onTap: () async {
                      Navigator.pop(context);
                      await _bluetoothService.connectToMacAddress(r.device.remoteId.str);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL"))],
      ),
    ).whenComplete(() => _bluetoothService.stopManualScan());
  }

  @override
  Widget build(BuildContext context) {
    final data = _exerciseData[widget.exerciseName] ?? _exerciseData['Toe Tap (Circular)'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: const Color(0xFFA7D42C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 32),
            Expanded(child: _buildStageContent(data)),
            const SizedBox(height: 24),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index <= _currentStage ? const Color(0xFFA7D42C) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStageContent(Map<String, dynamic> data) {
    if (_currentStage == 0) {
      return Column(
        children: [
          const Icon(Icons.devices, size: 80, color: Color(0xFFA7D42C)),
          const SizedBox(height: 24),
          const Text("DEVICE REQUIREMENT", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text("${data['devices']} Devices required", style: const TextStyle(fontSize: 18)),
        ],
      );
    } else if (_currentStage == 1) {
      return Column(
        children: [
          const Text("PLACEMENT", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Image.network(data['images'][0], height: 200, fit: BoxFit.cover),
          const SizedBox(height: 16),
          Text(data['placement'], style: const TextStyle(fontSize: 18)),
        ],
      );
    } else {
      return Column(
        children: [
          const Text("INSTRUCTIONS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ... (data['instructions'] as List).map((i) => ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(i))),
        ],
      );
    }
  }

  Widget _buildBottomControls() {
    bool isLastStage = _currentStage == 2;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          if (!_isConnected) {
            _showBluetoothPopup();
          } else if (_currentStage < 2) {
            _nextStage();
          } else {
            // Configure Hardware via BLE
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuring device...')));
            await _bluetoothService.configureExercise(widget.exerciseName, "medium", widget.reps);

            final data = _exerciseData[widget.exerciseName] ?? _exerciseData['Toe Tap (Circular)'];
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => EventDrivenExercisePage(
                  exerciseName: widget.exerciseName,
                  instructions: List<String>.from(data['instructions']),
                  reps: widget.reps,
                  exerciseId: widget.exerciseId,
                  assignmentId: widget.assignmentId,
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isLastStage ? const Color(0xFF2C4A3B) : const Color(0xFFA7D42C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          !_isConnected ? "CONNECT BLUETOOTH" : (isLastStage ? "START EXERCISE" : "NEXT STEP"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
