import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/core/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientProgressScreen extends StatefulWidget {
  const PatientProgressScreen({super.key});

  @override
  State<PatientProgressScreen> createState() => _PatientProgressScreenState();
}

class _PatientProgressScreenState extends State<PatientProgressScreen> {
  bool _isLoading = true;
  List<dynamic> _results = [];
  String _timeFilter = "Week"; // Week or Month
  
  // Aggregated Stats
  double _totalHours = 0;
  int _sessionCount = 0;
  int _consistencyPercent = 0;
  List<double> _weeklyData = [0, 0, 0, 0, 0, 0, 0];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  double _avgScore = 0;
  List<dynamic> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Fetch results for mock patient 2
      final results = await ApiService.getPatientResults(2); 
      
      if (mounted) {
        setState(() {
          _results = results;
          _processResults();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_results.isEmpty) _results = []; 
        });
      }
    }
  }

  void _processResults() {
    if (_results.isEmpty) return;

    // Sort by date newest first
    _results.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    _recentSessions = _results.take(5).toList();

    // 1. Total Time & Avg Score
    int totalSec = 0;
    double totalScore = 0;
    for (var r in _results) {
      totalSec += (r['time_taken'] as num).toInt();
      totalScore += (r['score'] as num).toDouble();
    }
    _totalHours = totalSec / 3600;
    _avgScore = _results.isEmpty ? 0 : totalScore / _results.length;

    // 2. Session Count
    _sessionCount = _results.length;

    // 3. Weekly Data
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    monday = DateTime(monday.year, monday.month, monday.day);

    List<double> dailyMinutes = [0, 0, 0, 0, 0, 0, 0];
    Set<String> activeDays = {};

    for (var r in _results) {
      DateTime date = DateTime.parse(r['date']);
      activeDays.add(DateFormat('yyyy-MM-dd').format(date));

      if (date.isAfter(monday.subtract(const Duration(seconds: 1)))) {
        int dayIdx = date.weekday - 1; 
        if (dayIdx >= 0 && dayIdx < 7) {
          dailyMinutes[dayIdx] += (r['time_taken'] as num) / 60;
        }
      }
    }
    _weeklyData = dailyMinutes;

    int daysActive = activeDays.length;
    _consistencyPercent = ((daysActive / 30) * 100).clamp(10, 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF006C55)),
                  ),
                )
              else ...[
                _buildOverviewSection(),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 32),
                _buildAchievementsSection(),
                const SizedBox(height: 32),
                _buildRecentActivity(),
                const SizedBox(height: 24),
                _buildImprovementBanner(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Activity", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        if (_recentSessions.isEmpty)
          Text("No recent activity", style: GoogleFonts.manrope(color: Colors.grey))
        else
          ..._recentSessions.map((s) => _activityItem(s)).toList(),
      ],
    );
  }

  Widget _activityItem(dynamic s) {
    DateTime date = DateTime.parse(s['date']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3EDF7), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fitness_center, color: Color(0xFF21005D), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Session #${s['id']}",
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(date),
                  style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${s['score']} pts",
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF006C55)),
              ),
              Text(
                "${s['accuracy']}% accuracy",
                style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Progress",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Track your recovery journey",
          style: GoogleFonts.manrope(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Overview", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                _buildToggle(),
              ],
            ),
            const SizedBox(height: 24),
            _buildChart(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _indicator(const Color(0xFFD0BCFF), "Exercises done"),
                const SizedBox(width: 20),
                _indicator(const Color(0xFFF3EDF7), "Daily Goal"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDF7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ["Week", "Month"].map((t) {
          bool active = _timeFilter == t;
          return GestureDetector(
            onTap: () => setState(() => _timeFilter = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : null,
              ),
              child: Text(
                t,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? const Color(0xFF21005D) : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    double maxVal = 120; // 2 hours in minutes
    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          double val = _weeklyData[index];
          double pct = (val / maxVal).clamp(0.1, 1.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 14,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EDF7),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutBack,
                    width: 14,
                    height: 140 * pct,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0BCFF),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _days[index],
                style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _indicator(Color col, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard("Total Time", "${_totalHours.toStringAsFixed(1)} hours", Icons.access_time_filled, const Color(0xFFF3EDF7)),
        const SizedBox(width: 16),
        _statCard("Sessions", "$_sessionCount", Icons.calendar_today_rounded, const Color(0xFFE0F2F1)),
        const SizedBox(width: 16),
        _statCard("Consistency", "$_consistencyPercent%", Icons.check_circle_rounded, const Color(0xFFE8F5E9)),
      ],
    );
  }

  Widget _statCard(String label, String val, IconData icon, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: const Color(0xFF21005D).withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.manrope(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1D1B20))),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Achievements", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _achievementBadge("3-Day Streak", "🔥", const Color(0xFFFFF4F0)),
              _achievementBadge("First Session", "⭐", const Color(0xFFEFFBF5)),
              _achievementBadge("Consistency Star", "🏆", const Color(0xFFF3EDF7)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _achievementBadge(String title, String emoji, Color bg) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1D1B20)),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8DEF8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.north_east, color: Color(0xFF21005D), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're improving!",
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF21005D)),
                ),
                Text(
                  "+20% consistency from last week",
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF21005D).withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
