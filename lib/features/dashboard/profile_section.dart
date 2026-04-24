import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reflexa_app/features/auth/presentation/login_screen.dart';
import 'package:reflexa_app/core/services/storage_service.dart';
import 'package:animate_do/animate_do.dart';

class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  static const Color primaryColor = Color(0xFF006C55);
  static const Color bgColor = Color(0xFFF8FAF9);
  static const Color borderColor = Color(0xFFE8E8E8);
  static const Color textMain = Color(0xFF1A1A1A);
  static const Color textSub = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: primaryColor));

          final data = snapshot.data?.data();
          if (data == null) return const Center(child: Text('User data not found'));

          final isTherapist = data['role']?.toString().toLowerCase() == 'therapist';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(data, isTherapist)),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle('Personal Details', onEdit: () {}),
                    _buildInfoCard([
                      _infoRow(Icons.person_outline, 'Name', data['fullName'] ?? 'N/A'),
                      _infoRow(Icons.cake_outlined, 'Age', '${data['age'] ?? 'N/A'} Years'),
                      _infoRow(Icons.phone_outlined, 'Phone', data['phone'] ?? 'N/A'),
                      _infoRow(Icons.public_outlined, 'Country', data['country'] ?? 'N/A'),
                      _infoRow(Icons.email_outlined, 'Email', data['email'] ?? user.email ?? 'N/A'),
                    ]),
                    const SizedBox(height: 24),
                    
                    if (isTherapist) ...[
                      _buildSectionTitle('Professional Details'),
                      _buildInfoCard([
                        _infoRow(Icons.work_history_outlined, 'Experience', data['experience'] ?? 'N/A'),
                        _infoRow(Icons.health_and_safety_outlined, 'Specialization', data['specialist'] ?? 'N/A'),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Work Summary'),
                      _buildSummaryRow([
                        _summaryItem('12', 'Patients'),
                        _summaryItem('8', 'Active Cases'),
                      ]),
                    ] else ...[
                      _buildSectionTitle('Health Details'),
                      _buildInfoCard([
                        _infoRow(Icons.accessible_outlined, 'Condition', data['disabilities'] ?? 'N/A'),
                      ]),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Progress Summary'),
                      _buildSummaryRow([
                        _summaryItem('24', 'Sessions'),
                        _summaryItem('85%', 'Goals Done'),
                      ]),
                    ],
                    
                    const SizedBox(height: 32),
                    _buildSectionTitle('Settings'),
                    _buildSettingsCard([
                      _settingsRow(Icons.notifications_none, 'Notifications', trailing: Switch(value: true, onChanged: (v) {}, activeColor: primaryColor)),
                      _settingsRow(Icons.lock_outline, 'Change Password', onTap: () {}),
                      _settingsRow(Icons.logout, 'Logout', isDanger: true, onTap: () => _handleLogout(context)),
                    ]),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, bool isTherapist) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withOpacity(0.1), width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: bgColor,
                child: Icon(Icons.person, size: 50, color: primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data['fullName'] ?? 'N/A',
            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: textMain),
          ),
          const SizedBox(height: 4),
          Text(
            isTherapist ? 'Physiotherapist' : 'Patient',
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.5),
          ),
          if (isTherapist && data['specialist'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                data['specialist'],
                style: GoogleFonts.manrope(fontSize: 12, color: textSub, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: textMain),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Text('Edit', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: primaryColor)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textSub.withOpacity(0.6)),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.manrope(fontSize: 14, color: textSub, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: GoogleFonts.manrope(fontSize: 14, color: textMain, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<Widget> items) {
    return Row(
      children: items.map((item) => Expanded(child: item)).toList(),
    );
  }

  Widget _summaryItem(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: primaryColor)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.manrope(fontSize: 12, color: textSub, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(IconData icon, String label, {Widget? trailing, VoidCallback? onTap, bool isDanger = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: isDanger ? Colors.redAccent : textMain),
      title: Text(
        label,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: isDanger ? Colors.redAccent : textMain),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, size: 20, color: textSub.withOpacity(0.4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await StorageService().clear();
              if (!mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
