import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/api_service.dart';
import 'package:reflexa_app/core/services/bluetooth_service.dart';
import 'package:reflexa_app/features/therapy/presentation/event_driven_exercise_page.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class TodaysSessionScreen extends StatefulWidget {
  final int userId;
  final VoidCallback onBack;

  const TodaysSessionScreen({super.key, required this.userId, required this.onBack});

  @override
  State<TodaysSessionScreen> createState() => _TodaysSessionScreenState();
}

class _TodaysSessionScreenState extends State<TodaysSessionScreen> {
  final bleService = AppBluetoothService();
  bool _isConnected = false;
  StreamSubscription? _bleSub;
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isConnected = bleService.isConnected;
    _bleSub = bleService.connectionStream.listen((connected) {
      if (mounted) setState(() => _isConnected = connected);
    });
    _fetchAssignments();
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchAssignments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    print("Fetching assignments for user: ${widget.userId}");
    
    try {
      final data = await ApiService.getPatientAssignments(widget.userId)
          .timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _assignments = (data as List).map((a) => Map<String, dynamic>.from(a)).where((a) => a['status'] == 'ASSIGNED').toList();
          _isLoading = false;
        });
        print("Loaded ${_assignments.length} assignments.");
      }
    } catch (e) {
      print("Error fetching assignments: $e");
      if (mounted) {
        setState(() {
          // Fallback to local if server fails
          _assignments = List<Map<String, dynamic>>.from(ApiService.localAssignments)
              .where((a) => a['status'] == 'ASSIGNED')
              .toList();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud sync slow. Showing local tasks.")),
        );
      }
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
                    return const Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Searching for pods...")
                      ],
                    ));
                  }
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, idx) {
                      final r = results[idx];
                      final name = r.device.advName.isNotEmpty ? r.device.advName : r.device.platformName;
                      if (!name.toLowerCase().contains("reflexa") && !name.toLowerCase().contains("pod")) return const SizedBox.shrink();
                      
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFEFFBF5), child: Icon(Icons.bluetooth, color: Color(0xFF006C55))),
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

  void _startExercise(Map<String, dynamic> assignment) {
    if (!_isConnected) {
      _showPairingSheet(onSuccess: () => _startExercise(assignment));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDrivenExercisePage(
          exerciseName: assignment['exercise_name'] ?? 'Exercise',
          exerciseId: assignment['exercise'] ?? 0,
          assignmentId: assignment['id'] ?? 0,
          instructions: const ["Wait for sensor data...", "Hold position as guided", "Maintain range"],
          reps: assignment['reps'] ?? 10,
          targetRange: assignment['target_range'] ?? "20-40",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildBetterHeader(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAssignments,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressCard(),
                          const SizedBox(height: 32),
                          Text(
                            "Assigned by Therapist",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF191C1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_assignments.isEmpty)
                            _buildEmptyState()
                          else
                            ..._assignments.asMap().entries.map((entry) {
                              return _assignmentCard(entry.value, entry.key);
                            }).toList(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No exercises assigned yet", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text("Sent a request from the portal", style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildBetterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF191C1B), size: 20),
          ),
          Expanded(
            child: Text(
              "Today's Session",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF191C1B),
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () => _showPairingSheet(),
                icon: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, 
                           color: _isConnected ? const Color(0xFF00A78E) : Colors.grey),
              ),
              if (!_isConnected)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006C55), Color(0xFF00A78E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF006C55).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your Recovery", style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text("Let's hit your goals!", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          _isConnected 
            ? const Icon(Icons.check_circle, color: Colors.white, size: 32)
            : IconButton(onPressed: () => _showPairingSheet(), icon: const Icon(Icons.bluetooth, color: Colors.white, size: 32))
        ],
      ),
    );
  }

  Widget _assignmentCard(Map<String, dynamic> assignment, int index) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: 80 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFF1F6F5), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.fitness_center, color: Color(0xFF006C55), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment['exercise_name'] ?? 'Exercise',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${assignment['reps']} reps • ${assignment['difficulty'] ?? 'Standard'}",
                      style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF888888), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _startExercise(assignment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006C55),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text("Start", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
