import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:course_path/auth/login.dart';
import '../services/theme_service.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  String name = '';
  String studentID = '';
  String department = '';
  String year = '';
  String cgpa = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? 'Unknown';
          studentID = data['studentID'] ?? 'Unknown ID';
          department = data['department'] ?? 'Unknown Dept.';
          year = data['year'] ?? 'Unknown';
          cgpa = data['cgpa'] ?? '0.0';
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF6F7FB),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ---------- TOP PURPLE HEADER ----------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 60,
                      bottom: 40,
                      left: 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F63F6),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person_outline,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              department.isNotEmpty
                                  ? department
                                  : "Software Eng. Dept.",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ---------- INFO CAPSULES ----------
                  InfoCapsule(label: "ID:", value: studentID, isDark: isDark),
                  InfoCapsule(
                    label: "Year:",
                    value: year.isNotEmpty ? year : "4th",
                    isDark: isDark,
                  ),
                  InfoCapsule(
                    label: "CGPA:",
                    value: cgpa.isNotEmpty ? cgpa : "2.94",
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // ---------- DARK MODE TOGGLE ----------
                  _buildDarkModeToggle(),

                  const Spacer(),

                  // ---------- LOG OUT BUTTON ----------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const Login()),
                            );
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          "Log Out",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              Icon(
                themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: const Color(0xFF4F63F6),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF616161),
                  ),
                ),
              ),
              Switch(
                value: themeService.isDarkMode,
                onChanged: (_) => themeService.toggleTheme(),
                activeColor: const Color(0xFF4F63F6),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------- INFO CAPSULE WIDGET ----------
class InfoCapsule extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const InfoCapsule({
    super.key,
    required this.label,
    required this.value,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF616161),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : const Color(0xFF757575),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
