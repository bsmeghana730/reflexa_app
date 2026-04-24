import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:reflexa_app/features/wellness/presentation/meditation_session_page.dart';

class MeditationScreen extends StatelessWidget {
  final VoidCallback onBack;

  const MeditationScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sessions = [
      {
        'title': 'Zen Garden', 
        'duration': '15 min', 
        'icon': Icons.spa_rounded, 
        'color': const Color(0xFF6750A4), 
        'bg': const Color(0xFFF3F0FF),
        'audio': 'https://www.soundescape.com/samples/zen-meditation-ambient.mp3',
      },
      {
        'title': 'Ocean Breath', 
        'duration': '10 min', 
        'icon': Icons.waves_rounded, 
        'color': const Color(0xFF0061A4), 
        'bg': const Color(0xFFE1F0FF),
        'audio': 'https://www.soundescape.com/samples/ocean-waves-calm.mp3',
      },
      {
        'title': 'Forest Healer', 
        'duration': '12 min', 
        'icon': Icons.park_rounded, 
        'color': const Color(0xFF006C55), 
        'bg': const Color(0xFFE6F3F0),
        'audio': 'https://www.soundescape.com/samples/forest-birds-ambient.mp3',
      },
      {
        'title': 'Deep Sleep', 
        'duration': '30 min', 
        'icon': Icons.dark_mode_rounded, 
        'color': const Color(0xFF4355B9), 
        'bg': const Color(0xFFF0F2FF),
        'audio': 'https://www.soundescape.com/samples/deep-sleep-delta.mp3',
      },
      {
        'title': 'Starlight Focus', 
        'duration': '8 min', 
        'icon': Icons.auto_awesome_rounded, 
        'color': const Color(0xFF7D5900), 
        'bg': const Color(0xFFFFF1D5),
        'audio': 'https://www.soundescape.com/samples/starlight-ambient.mp3',
      },
      {
        'title': 'Mountain Peace', 
        'duration': '20 min', 
        'icon': Icons.terrain_rounded, 
        'color': const Color(0xFF49454F), 
        'bg': const Color(0xFFF5F5F5),
        'audio': 'https://www.soundescape.com/samples/mountain-wind-peace.mp3',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1D1B20), size: 20),
        ),
        title: Text(
          "The Sanctuary", 
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800, 
            fontSize: 18, 
            color: const Color(0xFF1D1B20)
          )
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border, color: Color(0xFF1D1B20))),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                FadeInDown(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Meditation",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32, 
                          fontWeight: FontWeight.w800, 
                          color: const Color(0xFF1D1B20)
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Reconnect with your inner self",
                        style: GoogleFonts.manrope(
                          fontSize: 15, 
                          color: Colors.grey.shade600, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildGrid(context, sessions),
                const SizedBox(height: 32),
                _quoteCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Map<String, dynamic>> sessions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final s = sessions[index];
        return FadeInUp(
          delay: Duration(milliseconds: 50 * index),
          child: _meditationCard(context, s),
        );
      },
    );
  }

  Widget _meditationCard(BuildContext context, Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeditationSessionPage(
              title: s['title'],
              audioUrl: s['audio'],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFF5F5F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: s['bg'],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(s['icon'], color: s['color'], size: 24),
            ),
            const Spacer(),
            Text(
              s['title'], 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15, 
                fontWeight: FontWeight.w800, 
                color: const Color(0xFF1D1B20)
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s['duration'], 
                  style: GoogleFonts.manrope(
                    fontSize: 12, 
                    color: Colors.grey.shade500, 
                    fontWeight: FontWeight.w600
                  )
                ),
                Icon(Icons.play_circle_fill, color: s['color'].withOpacity(0.7), size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded, color: const Color(0xFF6750A4).withOpacity(0.5), size: 40),
          const SizedBox(height: 8),
          Text(
            "\"Quiet the mind, and the soul will speak.\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, 
              fontWeight: FontWeight.w700, 
              color: const Color(0xFF21005D),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "MA JAYA SATI BHAGAVATI",
            style: GoogleFonts.manrope(
              fontSize: 10, 
              fontWeight: FontWeight.w800, 
              letterSpacing: 1.2, 
              color: const Color(0xFF21005D).withOpacity(0.6)
            ),
          ),
        ],
      ),
    );
  }
}
