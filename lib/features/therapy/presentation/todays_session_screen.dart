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
  List<Map<String, dynamic>> _allAssignments = [];
  List<Map<String, dynamic>> _filteredAssignments = [];
  bool _isLoading = true;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
    
    try {
      final data = await ApiService.getPatientAssignments(widget.userId)
          .timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _allAssignments = (data as List)
              .map((a) => Map<String, dynamic>.from(a))
              .where((a) => a['status'] == 'ASSIGNED' || a['status'] == 'COMPLETED')
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allAssignments = List<Map<String, dynamic>>.from(ApiService.localAssignments)
              .where((a) => a['status'] == 'ASSIGNED' || a['status'] == 'COMPLETED')
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAssignments = _allAssignments.where((a) {
        final name = (a['exercise_name'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    });
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
    ).then((_) {
      // Re-fetch in case it was completed
      _fetchAssignments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006C55)))
                : RefreshIndicator(
                    onRefresh: _fetchAssignments,
                    color: const Color(0xFF006C55),
                    child: _buildList(),
                  ),
            ),
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
              "Today's Session",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF191C1B),
              ),
            ),
          ),
          // Bluetooth status instead of empty space
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade400, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  searchQuery = val;
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  hintStyle: GoogleFonts.manrope(color: Colors.grey.shade400, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: GoogleFonts.manrope(fontSize: 15, color: const Color(0xFF191C1B)),
              ),
            ),
            Icon(Icons.search, color: const Color(0xFF00A78E), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_filteredAssignments.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: _buildEmptyState(),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _filteredAssignments.length,
      itemBuilder: (context, index) {
        return _assignmentCard(_filteredAssignments[index], index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No exercises for today!", 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, 
              fontWeight: FontWeight.w800, 
              color: Colors.grey.shade600
            )
          ),
          const SizedBox(height: 8),
          Text(
            "You have completed everything.", 
            style: GoogleFonts.manrope(
              fontSize: 14, 
              color: Colors.grey.shade500
            )
          ),
        ],
      ),
    );
  }

  Widget _assignmentCard(Map<String, dynamic> assignment, int index) {
    final lowerName = (assignment['exercise_name'] ?? '').toString().toLowerCase();
    String imgUrl = "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&q=80&w=400";
    bool isAsset = false;

    if (lowerName.contains("leg raise")) {
      isAsset = true;
      imgUrl = "assets/exercises/leg_raise.jpg";
    } else if (lowerName.contains("knee")) {
      isAsset = true;
      imgUrl = "assets/exercises/knee_extension.jpg";
    } else if (lowerName.contains("squat") && lowerName.contains("wall")) {
      isAsset = true;
      imgUrl = "assets/exercises/wall_squat.jpg";
    } else if (lowerName.contains("squat")) {
      isAsset = true;
      imgUrl = "assets/exercises/wall_squat.jpg"; // Mock for mini squat
    } else if (lowerName.contains("stretch") || lowerName.contains("hold")) {
      isAsset = true;
      imgUrl = lowerName.contains("plank") ? "assets/exercises/plank_hold.jpg" : "assets/exercises/stretch_hold.jpg";
    } else if (lowerName.contains("bridge")) {
      isAsset = true;
      imgUrl = "assets/exercises/bridge_lift.jpg";
    }

    final category = lowerName.contains("plank") || lowerName.contains("bridge") ? "Core" : "Lower limb Exercise";
    final isCompleted = assignment['status'] == 'COMPLETED';

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: 50 * index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 64,
                height: 64,
                color: Colors.grey.shade200,
                child: isAsset
                    ? Image.asset(imgUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fitness_center))
                    : Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.fitness_center)),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment['exercise_name'] ?? 'Exercise',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? "Completed" : "$category • ${assignment['reps']} reps",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? const Color(0xFF00A78E) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            // Start Button or Checkmark
            isCompleted
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFFBF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Color(0xFF00C09E), size: 28),
                  )
                : InkWell(
                    onTap: () => _startExercise(assignment),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF88DAB2), Color(0xFFA5DFBB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "Start Session",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
