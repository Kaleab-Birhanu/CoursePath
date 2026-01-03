import 'package:flutter/material.dart';
import 'student_dashbord.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? selectedRole;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Widget roleCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5865F2) : Colors.white,
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
                color: selected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80),

            const Text(
              'CP',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5865F2),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              "Welcome to Course Path",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2A2A),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Select your role to continue:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
                color: Color(0xFF7E7B7B),
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
            ),

            const SizedBox(height: 12),

            roleCard(
              title: 'Admin',
              icon: Icons.admin_panel_settings,
              selected: selectedRole == 'admin',
              onTap: () {
                setState(() {
                  selectedRole = 'admin';
                });
              },
            ),
            const SizedBox(height: 24),

            inputField(
              hint: 'Email',
              icon: Icons.email,
              controller: emailController,
            ),

            const SizedBox(height: 16),

            inputField(
              hint: 'Password',
              icon: Icons.lock,
              isPassword: true,
              controller: passwordController,
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5865F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (selectedRole == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a role')),
                    );
                    return;
                  }
                  String email = emailController.text;
                  String password = passwordController.text;

                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                   if (selectedRole == 'Student') {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StudentDashbord()),
    );
  } else if (selectedRole == 'Admin') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin login not implemented yet')),
    );
  }
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(builder: (context) => student_dashbord()),
                //   );
                },
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
