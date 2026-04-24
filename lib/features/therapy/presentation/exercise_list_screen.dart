import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/api_service.dart';
import 'package:reflexa_app/features/therapy/presentation/exercise_detail_screen.dart';

class ExerciseListScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ExerciseListScreen({super.key, required this.onBack});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  String selectedDifficulty = "All";
  String searchQuery = "";
  int? selectedIdx;
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _allExercises = [];
  List<dynamic> _filteredExercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
  }

  Future<void> _fetchExercises() async {
    try {
      final fetched = await ApiService.getExercises();
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
        final matchesSearch = name.contains(searchQuery.toLowerCase());
        
        bool matchesDifficulty = false;
        if (selectedDifficulty == "All") {
          matchesDifficulty = true;
        } else if (selectedDifficulty == "Easy") {
          matchesDifficulty = name.contains("leg raise") || name.contains("knee extension");
        } else if (selectedDifficulty == "Medium") {
          matchesDifficulty = name.contains("squat") || name.contains("stretch");
        } else if (selectedDifficulty == "Hard") {
          matchesDifficulty = name.contains("bridge") || name.contains("plank");
        }

        return matchesSearch && matchesDifficulty;
      }).toList();
      
      // Auto-select first item if current selection is now filtered out
      if (selectedIdx != null && selectedIdx! >= _filteredExercises.length) {
        selectedIdx = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildDifficultyFilters(),
            _buildSectionTitle(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF006C55)))
                : _buildGrid(),
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
          const SizedBox(width: 8),
          Text(
            "Exercise List",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF191C1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F9),
          borderRadius: BorderRadius.circular(20),
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
            Icon(Icons.search, color: const Color(0xFF00BFA5), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _filterPill("All", Colors.grey.shade200, Colors.black87, Icons.grid_view_rounded),
            const SizedBox(width: 8),
            _filterPill("Easy", const Color(0xFFDAF1E8), const Color(0xFF006C55), Icons.eco),
            const SizedBox(width: 8),
            _filterPill("Medium", const Color(0xFFFFE9D6), const Color(0xFFE48D45), Icons.waves),
            const SizedBox(width: 8),
            _filterPill("Hard", const Color(0xFFFFD9DB), const Color(0xFFD64D55), Icons.local_fire_department),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(String label, Color bg, Color textCol, IconData icon) {
    bool isSelected = selectedDifficulty == label;
    return GestureDetector(
      onTap: () {
        setState(() => selectedDifficulty = label);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? textCol.withOpacity(0.3) : Colors.transparent, width: 1.5),
          boxShadow: [
            if (isSelected) BoxShadow(color: bg.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? textCol : Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, 
                color: isSelected ? textCol : Colors.grey.shade500, 
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "All Exercises",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, 
              fontWeight: FontWeight.w800, 
              color: const Color(0xFF191C1B),
            ),
          ),
          Text(
            "${_filteredExercises.length} Items",
            style: GoogleFonts.manrope(
              fontSize: 13, 
              color: Colors.grey.shade500, 
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_filteredExercises.isEmpty) {
      return Center(
        child: Text("No exercises found", style: GoogleFonts.manrope(color: Colors.grey)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => ExerciseDetailScreen(
                  exercise: _filteredExercises[index], 
                  onBack: () => Navigator.pop(context),
                ),
              ),
            );
          },
          child: _exerciseGridCard(_filteredExercises[index], index),
        );
      },
    );
  }

  Widget _exerciseGridCard(Map<String, dynamic> ex, int index) {
    bool isSelected = selectedIdx == index;
    // Map backend exercise names to realistic images
    final name = ex['name'].toString().toLowerCase();
    String imgUrl = "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&q=80&w=400"; // Default
    bool isAsset = false;

    if (name.contains("leg raise")) {
      isAsset = true;
      imgUrl = "assets/exercises/leg_raise.jpg";
    } else if (name.contains("knee")) {
      isAsset = true;
      imgUrl = "assets/exercises/knee_extension.jpg";
    } else if (name.contains("squat")) {
      isAsset = true;
      imgUrl = "assets/exercises/wall_squat.jpg";
    } else if (name.contains("stretch") || name.contains("hold")) {
      isAsset = true;
      imgUrl = name.contains("plank") ? "assets/exercises/plank_hold.jpg" : "assets/exercises/stretch_hold.jpg";
    } else if (name.contains("bridge")) {
      isAsset = true;
      imgUrl = "assets/exercises/bridge_lift.jpg";
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: 50 * index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? Border.all(color: const Color(0xFF00A78E), width: 3) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.2 : 0.08), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isAsset
                ? Image.asset(imgUrl, fit: BoxFit.cover)
                : Image.network(imgUrl, fit: BoxFit.cover),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    ex['name'],
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
