import 'package:flutter/material.dart';
import 'package:reflexa_app/core/services/api_service.dart';

class SessionSummaryPage extends StatefulWidget {
  final String exerciseName;
  final int exerciseId;
  final int assignmentId;
  final double accuracy;
  final int timeTaken;
  final int score;

  const SessionSummaryPage({
    super.key,
    required this.exerciseName,
    required this.exerciseId,
    required this.assignmentId,
    required this.accuracy,
    required this.timeTaken,
    required this.score,
  });

  @override
  State<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends State<SessionSummaryPage> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    setState(() => _isSaving = true);
    try {
      // 1. Save results
      await ApiService.saveSessionResult(
        patientId: 2, // patient1
        exerciseId: widget.exerciseId,
        accuracy: widget.accuracy,
        timeTaken: widget.timeTaken,
        score: widget.score,
      );

      // 2. Mark assignment as completed in backend
      if (widget.assignmentId != 0) {
        await ApiService.completeAssignment(widget.assignmentId);
      }
    } catch (e) {
      debugPrint("Error saving result: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFA),
      appBar: AppBar(
        title: const Text("Session Summary"),
        backgroundColor: const Color(0xFFA7D42C),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.stars, size: 80, color: Color(0xFFF1A66A)),
            const SizedBox(height: 24),
            const Text(
              "Congratulations!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C4A10)),
            ),
            const SizedBox(height: 8),
            Text(
              "You've completed the ${widget.exerciseName} session.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            _buildStatCard(Icons.percent, "Accuracy", "${widget.accuracy.toStringAsFixed(1)}%"),
            const SizedBox(height: 16),
            _buildStatCard(Icons.timer, "Time Taken", _formatDuration(widget.timeTaken)),
            const SizedBox(height: 16),
            _buildStatCard(Icons.emoji_events, "Performance", _getPerformanceLabel(widget.accuracy)),
            const Spacer(),
            if (_isSaving)
              const CircularProgressIndicator(color: Color(0xFFA7D42C))
            else
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C4A10),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("BACK TO DASHBOARD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFA7D42C).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFFA7D42C)),
          ),
          const SizedBox(width: 20),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF2C4A10))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C4A10))),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  String _getPerformanceLabel(double accuracy) {
    if (accuracy >= 90) return "Excellent";
    if (accuracy >= 75) return "Great";
    if (accuracy >= 60) return "Good";
    return "Keep Practicing";
  }
}
