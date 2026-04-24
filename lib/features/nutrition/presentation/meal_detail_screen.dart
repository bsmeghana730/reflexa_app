import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class MealDetailScreen extends StatelessWidget {
  final Map<String, dynamic> meal;
  final VoidCallback onBack;

  const MealDetailScreen({
    super.key, 
    required this.meal, 
    required this.onBack
  });

  @override
  Widget build(BuildContext context) {
    // Generate dummy data if real data isn't provided (for demonstration)
    final nutrition = meal['nutrition'] ?? {
      "calories": "350",
      "protein": "25g",
      "carbs": "40g",
      "fats": "10g",
    };
    final benefits = meal['benefits'] ?? [
      "Improves muscle recovery",
      "Provides essential nutrients",
      "Boosts energy levels",
    ];
    final ingredients = meal['ingredients'] ?? [
      "Protein source",
      "Fresh vegetables",
      "Healthy grains",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroImage(),
                      const SizedBox(height: 24),
                      _buildTitleSection(),
                      const SizedBox(height: 24),
                      _buildNutritionInfo(nutrition),
                      const SizedBox(height: 32),
                      _buildListSection("Benefits", benefits, const Color(0xFFD0BCFF)),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 12),
                      _buildListSection("Ingredients", ingredients, const Color(0xFFB4E4DD)),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF49454F)),
          ),
          Expanded(
            child: Text(
              "Meal Details",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1B20),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          image: DecorationImage(
            image: NetworkImage(meal['image']),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return FadeInLeft(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal['name'],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "High protein meal for recovery",
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo(Map<String, dynamic> nut) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nutrition Info",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF49454F),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _nutCard("Calories", nut['calories'], "kcal", const Color(0xFFF3EDF7)),
                _nutCard("Protein", nut['protein'], "25g", const Color(0xFFE8DEF8)),
                _nutCard("Carbs", nut['carbs'], "40g", const Color(0xFFFFEBF0)),
                _nutCard("Fats", nut['fats'], "8g", const Color(0xFFF2F2F2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutCard(String label, String val, String sub, Color col) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: col,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1D1B20))),
            Text(sub, style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, Color dotColor) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor.withOpacity(0.5))),
                const SizedBox(width: 12),
                Text(
                  item,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: const Color(0xFF49454F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
