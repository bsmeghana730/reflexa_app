import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/features/nutrition/presentation/meal_detail_screen.dart';

class MealPlanScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MealPlanScreen({super.key, required this.onBack});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  String selectedFilter = "All";
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> meals = [
    {
      "name": "Grilled Chicken with Veggies",
      "type": "Non-Vegetarian",
      "description": "High protein for muscle repair",
      "image": "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&p=80&w=400",
      "isVeg": false,
    },
    {
      "name": "Moong Dal Khichdi",
      "type": "Vegetarian",
      "description": "Easy to digest, high protein",
      "image": "https://images.unsplash.com/photo-1546833998-877b37c2e5c6?auto=format&fit=crop&p=80&w=400",
      "isVeg": true,
    },
    {
      "name": "Oats with Berries",
      "type": "Vegetarian",
      "description": "Slow-release energy for recovery",
      "image": "https://images.unsplash.com/photo-1501150820427-bc5bcc697056?auto=format&fit=crop&p=80&w=400",
      "isVeg": true,
    },
    {
      "name": "Quinoa Greek Salad",
      "type": "Vegetarian",
      "description": "Anti-inflammatory nutrients",
      "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&p=80&w=400",
      "isVeg": true,
    },
    {
      "name": "Pan-Seared Salmon",
      "type": "Non-Vegetarian",
      "description": "Omega-3 for joint health",
      "image": "https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&p=80&w=400",
      "isVeg": false,
    },
    {
      "name": "Vegetable Dalia",
      "type": "Vegetarian",
      "description": "High fiber, nutritious breakfast",
      "image": "https://images.unsplash.com/photo-1505253716362-afaba1d32b0f?auto=format&fit=crop&p=80&w=400",
      "isVeg": true,
    },
    {
      "name": "Smoothie Bowl",
      "type": "Vegetarian",
      "description": "High fiber and vitamin C",
      "image": "https://images.unsplash.com/photo-1590301157890-4810ed352733?auto=format&fit=crop&p=80&w=400",
      "isVeg": true,
    },
    {
      "name": "Turkey & Spinach Wrap",
      "type": "Non-Vegetarian",
      "description": "Lean protein snack",
      "image": "https://images.unsplash.com/photo-1626700051175-656a433bcfaf?auto=format&fit=crop&p=80&w=400",
      "isVeg": false,
    },
    {
      "name": "Paneer Tikka Salad",
      "type": "Vegetarian",
      "description": "Calcium and protein boost",
      "image": "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&q=80&w=400",
      "isVeg": true,
    },
    {
      "name": "Creamy Mushroom Soup",
      "type": "Vegetarian",
      "description": "Immune support, light meal",
      "image": "https://images.unsplash.com/photo-1547592166-23ac45744acd?auto=format&fit=crop&p=80&w=400",
      "isVeg": true,
    },
    {
      "name": "Steamed Fish with Ginger",
      "type": "Non-Vegetarian",
      "description": "Light protein, anti-nausea",
      "image": "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&p=80&w=400",
      "isVeg": false,
    },
    {
      "name": "Boiled Eggs with Avocado",
      "type": "Non-Vegetarian",
      "description": "Perfect post-workout snack",
      "image": "https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&p=80&w=400",
      "isVeg": false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var filteredMeals = meals.where((m) {
      bool matchType = selectedFilter == "All" || m['type'] == selectedFilter;
      bool matchSearch = m['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      return matchType && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    "Recommended for you",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1B20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${filteredMeals.length} total",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _buildMealList(filteredMeals),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF49454F)),
              ),
              Expanded(
                child: Text(
                  "Meal Plan",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Healthy meals for your recovery",
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF49454F).withOpacity(0.8),
              fontWeight: FontWeight.w500,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => searchQuery = val),
          decoration: InputDecoration(
            hintText: "Search recipes, ingredients...",
            hintStyle: GoogleFonts.manrope(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _filterPill("All", null),
          _filterPill("Vegetarian", Icons.eco),
          _filterPill("Non-Vegetarian", Icons.kebab_dining),
        ],
      ),
    );
  }

  Widget _filterPill(String label, IconData? icon) {
    bool isSelected = selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8DEF8) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon, 
                  size: 16, 
                  color: label == "Vegetarian" ? Colors.green : Colors.brown,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label == "Non-Vegetarian" ? "Non-Veg" : label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF21005D) : const Color(0xFF49454F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final meal = items[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          delay: Duration(milliseconds: 50 * index),
          child: _mealItem(meal),
        );
      },
    );
  }

  Widget _mealItem(Map<String, dynamic> meal) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MealDetailScreen(
              meal: meal,
              onBack: () => Navigator.pop(context),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF7F2FA),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                meal['image'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.restaurant, color: Colors.grey.shade400);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meal['name'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D1B20),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      meal['isVeg'] ? Icons.eco : Icons.kebab_dining,
                      size: 14,
                      color: meal['isVeg'] ? Colors.green : Colors.brown,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meal['description'],
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF7F2FA),
            ),
            child: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF49454F)),
          ),
        ],
      ),
    ),
  );
}
}
