import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:reflexa_app/core/services/api_service.dart';

class SessionData {
  final String exerciseName;
  final DateTime date;
  final int durationMinutes;
  final double completionPercentage;
  final String status;

  SessionData({
    required this.exerciseName,
    required this.date,
    required this.durationMinutes,
    required this.completionPercentage,
    required this.status,
  });
}

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Completed', 'Partial', 'Missed'];

  List<SessionData> _allSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      // Execute in parallel with a shorter total timeout
      final resultsFuture = ApiService.getPatientResults(2);
      final exercisesFuture = ApiService.getExercises();

      final responses = await Future.wait([resultsFuture, exercisesFuture])
          .timeout(const Duration(seconds: 2));
      
      final results = responses[0] as List<dynamic>;
      final exercises = responses[1] as List<dynamic>;

      final Map<int, String> exerciseNames = {
        for (var ex in exercises) ex['id']: ex['name']
      };

      final List<SessionData> loadedSessions = [];
      for (var result in results) {
        final exerciseId = result['exercise'] ?? 0;
        final exerciseName = exerciseNames[exerciseId] ?? 'Unknown Exercise';
        final dateStr = result['date'];
        DateTime date = DateTime.now();
        if (dateStr != null) {
          date = DateTime.tryParse(dateStr) ?? DateTime.now();
        }
        
        final timeTaken = result['time_taken'] ?? 60;
        final durationMinutes = (timeTaken / 60).round();
        
        final accuracy = (result['accuracy'] ?? 0.0).toDouble();
        final completionPercentage = accuracy / 100.0;
        
        String status;
        if (completionPercentage >= 0.9) {
          status = "Completed";
        } else if (completionPercentage >= 0.5) {
          status = "Partial";
        } else {
          status = "Missed";
        }

        loadedSessions.add(SessionData(
          exerciseName: exerciseName,
          date: date,
          durationMinutes: durationMinutes > 0 ? durationMinutes : 1,
          completionPercentage: completionPercentage.clamp(0.0, 1.0),
          status: status,
        ));
      }

      loadedSessions.sort((a, b) => b.date.compareTo(a.date));

      if (mounted) {
        setState(() {
          _allSessions = loadedSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<SessionData> get _filteredSessions {
    if (_selectedFilter == 'All') return _allSessions;
    return _allSessions.where((s) => s.status == _selectedFilter).toList();
  }

  Map<String, List<SessionData>> get _groupedSessions {
    final Map<String, List<SessionData>> grouped = {};
    for (var session in _filteredSessions) {
      final now = DateTime.now();
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(session.date.year, session.date.month, session.date.day))
          .inDays;

      String dateLabel;
      if (difference == 0) {
        dateLabel = "Today";
      } else if (difference == 1) {
        dateLabel = "Yesterday";
      } else {
        dateLabel = DateFormat('MMMM d, yyyy').format(session.date);
      }

      if (!grouped.containsKey(dateLabel)) {
        grouped[dateLabel] = [];
      }
      grouped[dateLabel]!.add(session);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedSessions;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFF),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInDown(child: _buildHeaderTitle()),
                    const SizedBox(height: 24),
                    if (!_isLoading) ...[
                      FadeInDown(delay: const Duration(milliseconds: 100), child: _buildWeeklySummary()),
                      const SizedBox(height: 32),
                      FadeInUp(delay: const Duration(milliseconds: 200), child: _buildFilters()),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF006C55)),
                ),
              )
            else if (grouped.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    "No sessions found.",
                    style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final keys = grouped.keys.toList();
                    final dateLabel = keys[index];
                    final sessions = grouped[dateLabel]!;

                    return FadeInUp(
                      delay: Duration(milliseconds: 300 + (index * 100)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1D1B20),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...sessions.map((s) => _buildSessionCard(s)),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: grouped.keys.length,
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D1B20), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Text(
        "History",
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: const Color(0xFF1D1B20),
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Session History",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Review your past exercises and progress",
          style: GoogleFonts.manrope(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklySummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF006C55),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006C55).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Weekly Summary",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem("Total", "${_allSessions.length} Sessions"),
              _buildSummaryItem(
                "Average", 
                "${_allSessions.isEmpty ? 0 : (_allSessions.map((s) => s.completionPercentage).reduce((a, b) => a + b) / _allSessions.length * 100).toInt()}% Complete"
              ),
              _buildSummaryItem(
                "Best Day", 
                _allSessions.isEmpty ? "-" : _getBestDay()
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getBestDay() {
    if (_allSessions.isEmpty) return "-";
    
    // Simple logic: return day with highest single session completion
    var best = _allSessions.reduce((curr, next) => curr.completionPercentage > next.completionPercentage ? curr : next);
    
    final now = DateTime.now();
    final difference = DateTime(now.year, now.month, now.day)
        .difference(DateTime(best.date.year, best.date.month, best.date.day))
        .inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return DateFormat('EEE').format(best.date); // e.g., "Mon"
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: GoogleFonts.manrope(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF006C55),
              elevation: isSelected ? 4 : 0,
              shadowColor: const Color(0xFF006C55).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionCard(SessionData session) {
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (session.status) {
      case "Completed":
        statusColor = const Color(0xFF006C55);
        statusBgColor = const Color(0xFFE6F3F0);
        statusIcon = Icons.check_circle_rounded;
        break;
      case "Partial":
        statusColor = const Color(0xFFD98A2C);
        statusBgColor = const Color(0xFFFFF4E5);
        statusIcon = Icons.timelapse_rounded;
        break;
      case "Missed":
      default:
        statusColor = const Color(0xFFBA1A1A);
        statusBgColor = const Color(0xFFFFEDEA);
        statusIcon = Icons.cancel_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF5F5F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  session.exerciseName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D1B20),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      session.status,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                DateFormat('h:mm a').format(session.date),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                "${session.durationMinutes} min",
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: session.completionPercentage,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0F0F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      session.completionPercentage >= 0.9
                          ? const Color(0xFF006C55)
                          : const Color(0xFFD98A2C),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${(session.completionPercentage * 100).toInt()}%",
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
