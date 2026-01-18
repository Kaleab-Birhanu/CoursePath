import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:course_path/admin/admin_dashboard.dart';
import 'package:course_path/student/student_dashbord.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? selectedRole;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // ---------------- ROLE CARD ----------------
  Widget roleCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF5865F2)
              : (isDark ? const Color(0xFF2D2D2D) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF5865F2), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF5865F2),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- INPUT FIELD ----------------
  Widget inputField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5865F2), width: 2),
        ),
      ),
    );
  }

  // ---------------- LOGIN ----------------
  Future<void> login() async {
    if (selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => isLoading = true);

    try {
      // ---------------- FIREBASE AUTH ----------------
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user != null && selectedRole == 'Student') {
        final docRef = FirebaseFirestore.instance
            .collection('students')
            .doc(user.uid);
        final doc = await docRef.get();

        String name = '';
        String studentID = '';

        if (!doc.exists) {
          // Pre-fill sample students
          if (user.email == 'alex@student.edu') {
            name = 'Alex Thompson';
            studentID = 'ETS1234/15';
          } else if (user.email == 'maya@student.edu') {
            name = 'Maya Johnson';
            studentID = 'ETS1235/16';
          } else if (user.email == 'david@student.edu') {
            name = 'David Smith';
            studentID = 'ETS1236/17';
          } else {
            name = 'Unknown Student';
            studentID = 'Unknown ID';
          }

          await docRef.set({
            'name': name,
            'studentID': studentID,
            'email': user.email,
          });
        } else {
          final data = doc.data()!;
          name = data['name'] ?? 'Unknown Student';
          studentID = data['studentID'] ?? 'Unknown ID';
        }

        // Navigate to student dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StudentDashboard(name: name, studentID: studentID),
            ),
          );
        }
      } else if (user != null && selectedRole!.toLowerCase() == 'admin') {
        // ---------------- ADMIN ----------------
        final docRef = FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid);
        final doc = await docRef.get();

        String adminName = '';
        String adminEmail = user.email ?? '';

        if (!doc.exists) {
          // Pre-fill sample admins
          if (adminEmail == 'john@admin.edu') {
            adminName = 'Prof. John Carter';
          } else if (adminEmail == 'linda@admin.edu') {
            adminName = 'Dr.Linda Matthews';
          } else if (adminEmail == 'mike@admin.edu') {
            adminName = 'Mike Johnson';
          } else {
            adminName = 'Unknown Admin';
          }

          await docRef.set({'name': adminName, 'email': adminEmail});
        } else {
          final data = doc.data()!;
          adminName = data['name'] ?? 'Unknown Admin';
        }

        // Navigate to admin dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AdminDashboard(name: adminName, email: adminEmail),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';

      // Handle specific Firebase Auth error codes
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        errorMessage = 'Incorrect email or password';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many failed attempts. Please try again later';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Text(
                'CP',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5865F2),
                ),
              ),
              Text(
                "Welcome to Course Path",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2B2A2A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select your role to continue:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: isDark ? Colors.white70 : const Color(0xFF7E7B7B),
                ),
              ),
              const SizedBox(height: 24),
              roleCard(
                title: 'Student',
                icon: Icons.school,
                selected: selectedRole == 'Student',
                onTap: () {
                  setState(() {
                    selectedRole = 'Student';
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              roleCard(
                title: 'Admin',
                icon: Icons.admin_panel_settings,
                selected: selectedRole?.toLowerCase() == 'admin',
                onTap: () {
                  setState(() {
                    selectedRole = 'admin';
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              inputField(
                hint: 'Institutional Email',
                icon: Icons.email,
                controller: emailController,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              inputField(
                hint: 'Password',
                icon: Icons.lock,
                isPassword: true,
                controller: passwordController,
                isDark: isDark,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5865F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: login,
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
