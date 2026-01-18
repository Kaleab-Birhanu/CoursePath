import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:course_path/auth/login.dart';
import '../services/theme_service.dart';

class AdminProfile extends StatelessWidget {
  final String name;
  final String email;

  const AdminProfile({super.key, required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Curved Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40, left: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF4D64FF), // Vibrant blue
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    Icons.person_outline,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Department Admin',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Info Capsules
          InfoCapsule(label: 'Email:', value: email, isDark: isDark),
          InfoCapsule(
            label: 'Department:',
            value: 'Software Engineering',
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // Dark Mode Toggle
          _buildDarkModeToggle(context),

          const Spacer(),

          // Log Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to Login and remove all previous routes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828), // Deep red
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkModeToggle(BuildContext context) {
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
                color: const Color(0xFF4D64FF),
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
                activeColor: const Color(0xFF4D64FF),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
        borderRadius: BorderRadius.circular(50), // Rounded capsule shape
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
