import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reflexa_app/features/dashboard/patient_dashboard.dart';
import 'package:reflexa_app/features/dashboard/therapist_dashboard.dart';
import 'package:reflexa_app/core/services/storage_service.dart';
import 'package:animate_do/animate_do.dart';

class SignupScreen extends StatefulWidget {
  final String? initialRole;
  const SignupScreen({super.key, this.initialRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Healthcare minimal palette
  final Color primaryGreen = const Color(0xFF006C55); 
  final Color darkText = const Color(0xFF1A1A1A);
  final Color secondaryText = const Color(0xFF757575);
  final Color bgColor = const Color(0xFFF8FAF9);
  final Color fieldBg = Colors.white;
  final Color borderColor = const Color(0xFFEEEEEE);
  final Color iconColor = const Color(0xFF1A1A1A);

  late String _selectedRole;
  String _selectedCountry = 'India';
  String _selectedGender = 'Male';
  String _selectedExperience = '1-3 Years';
  String _selectedSpecialist = 'Orthopedic';
  String _selectedDisability = 'None';
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'Patient';
  }

  final List<String> _countries = ['India', 'USA', 'UK', 'Canada', 'Australia'];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _experiences = ['1-3 Years', '4-6 Years', '7-10 Years', '10+ Years'];
  final List<String> _specialists = ['Orthopedic', 'Neurological', 'Pediatric', 'Cardiovascular', 'Sports Recovery'];
  final List<String> _disabilities = ['None', 'ACL Tear', 'Post-stroke Recovery', 'Spinal Cord Injury', 'Arthritis', 'Cerebral Palsy'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final userData = {
        'uid': credential.user!.uid,
        'role': _selectedRole.toLowerCase(),
        'fullName': _fullNameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'phone': _phoneController.text.trim(),
        'country': _selectedCountry,
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'Therapist') {
        userData['experience'] = _selectedExperience;
        userData['specialist'] = _selectedSpecialist;
      } else {
        userData['disabilities'] = _selectedDisability;
      }

      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set(userData);
      await StorageService().setLoggedIn(true);
      if (!mounted) return;
      if (_selectedRole == 'Therapist') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TherapistDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientDashboard()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.plusJakartaSans(
            color: primaryGreen,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Choose your role',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 16),
              _buildRoleToggle(),
              const SizedBox(height: 32),
              _buildField(controller: _fullNameController, hint: 'Full Name', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildField(controller: _ageController, hint: 'Age', icon: Icons.cake_outlined, type: TextInputType.number),
              const SizedBox(height: 16),
              _buildField(controller: _phoneController, hint: 'Phone Number', icon: Icons.phone_outlined, type: TextInputType.phone),
              const SizedBox(height: 16),
              _buildDropdown(
                value: _selectedCountry,
                items: _countries,
                icon: Icons.public,
                label: 'Country',
                onChanged: (v) => setState(() => _selectedCountry = v!),
              ),
              const SizedBox(height: 16),
              if (_selectedRole == 'Therapist') ...[
                _buildDropdown(
                  value: _selectedExperience,
                  items: _experiences,
                  icon: Icons.work_history_outlined,
                  label: 'Experience',
                  onChanged: (v) => setState(() => _selectedExperience = v!),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedSpecialist,
                  items: _specialists,
                  icon: Icons.health_and_safety_outlined,
                  label: 'Specialist',
                  onChanged: (v) => setState(() => _selectedSpecialist = v!),
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedRole == 'Patient') ...[
                _buildDropdown(
                  value: _selectedDisability,
                  items: _disabilities,
                  icon: Icons.accessible_outlined,
                  label: 'Disabilities',
                  onChanged: (v) => setState(() => _selectedDisability = v!),
                ),
                const SizedBox(height: 16),
              ],
              _buildField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined, type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _confirmPasswordController,
                hint: 'Confirm Password',
                icon: Icons.lock_outline,
                isPassword: true,
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Create Account', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggle() {
    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'Patient'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedRole == 'Patient' ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Patient',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: _selectedRole == 'Patient' ? Colors.white : darkText,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = 'Therapist'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedRole == 'Therapist' ? primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Therapist',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: _selectedRole == 'Therapist' ? Colors.white : darkText,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: darkText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(color: secondaryText.withOpacity(0.4), fontSize: 15),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: iconColor, size: 22),
                    onPressed: onToggle,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600))))
            .toList(),
        onChanged: onChanged,
        icon: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.arrow_drop_down, color: darkText),
        ),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(color: secondaryText.withOpacity(0.5), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}
