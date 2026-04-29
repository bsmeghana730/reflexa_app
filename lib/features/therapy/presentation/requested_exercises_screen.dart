import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/api_service.dart';

class RequestedExercisesScreen extends StatefulWidget {
  final VoidCallback onBack;
  const RequestedExercisesScreen({super.key, required this.onBack});

  @override
  State<RequestedExercisesScreen> createState() => _RequestedExercisesScreenState();
}

class _RequestedExercisesScreenState extends State<RequestedExercisesScreen> {
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _allExercises = [];
  List<dynamic> _filteredExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequestedExercises();
  }

  Future<void> _fetchRequestedExercises() async {
    try {
      final fetched = await ApiService.getRequestedExercises();
      setState(() {
        _allExercises = fetched;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading exercises: $e")),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        final name = ex['name'].toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _cancelRequest(int index) {
    final ex = _filteredExercises[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Cancel Request", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text("Are you sure you want to cancel the request for ${ex['name']}?", style: GoogleFonts.manrope(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("No", style: GoogleFonts.manrope(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.cancelExerciseRequest(2, ex['id']);
              
              if (mounted) {
                setState(() {
                  _allExercises.removeWhere((e) => e['id'] == ex['id']);
                  _applyFilters();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request cancelled successfully"), backgroundColor: Color(0xFF00A78E))
                );
              }
            },
            child: Text("Yes, Cancel", style: GoogleFonts.manrope(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9), // Matches app generic bg
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006C55)))
                : _buildList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        currentIndex: 2, // Exercises tab
        onTap: (idx) {
          if (idx == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        selectedItemColor: const Color(0xFF006C55),
        unselectedItemColor: Colors.grey.shade400,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded, color: Color(0xFF00A78E)), activeIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF00A78E)), label: 'Exercises'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
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
              "Requested Exercises",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF191C1B),
              ),
            ),
          ),
          const SizedBox(width: 48), // To balance the back button
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
    if (_filteredExercises.isEmpty) {
      return Center(
        child: Text("No requested exercises", style: GoogleFonts.manrope(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        return _buildListItem(_filteredExercises[index], index);
      },
    );
  }

  Widget _buildListItem(Map<String, dynamic> ex, int index) {
    final name = ex['name'].toString();
    final lowerName = name.toLowerCase();
    String imgUrl = "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&q=80&w=400";
    bool isAsset = false;

    if (lowerName.contains("leg raise")) {
      isAsset = true;
      imgUrl = "assets/exercises/leg_raise.jpg";
    } else if (lowerName.contains("knee")) {
      isAsset = true;
      imgUrl = "assets/exercises/knee_extension.jpg";
    } else if (lowerName.contains("squat")) {
      isAsset = true;
      imgUrl = "assets/exercises/wall_squat.jpg";
    } else if (lowerName.contains("stretch") || lowerName.contains("hold")) {
      isAsset = true;
      imgUrl = lowerName.contains("plank") ? "assets/exercises/plank_hold.jpg" : "assets/exercises/stretch_hold.jpg";
    } else if (lowerName.contains("bridge")) {
      isAsset = true;
      imgUrl = "assets/exercises/bridge_lift.jpg";
    }

    final category = ex['goal'] ?? (lowerName.contains("plank") ? "Core" : "Lower limb Exercise");

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
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            // Requested Pill + Cancel Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E6), // Light orange
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Requested",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE48D45), // Orange text
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => _cancelRequest(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                  tooltip: 'Cancel Request',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
