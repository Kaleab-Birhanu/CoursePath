import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourseEligibilityScreen extends StatefulWidget {
  const CourseEligibilityScreen({super.key});

  @override
  State<CourseEligibilityScreen> createState() =>
      _CourseEligibilityScreenState();
}

class _CourseEligibilityScreenState extends State<CourseEligibilityScreen> {
  bool showEligible = true;
  bool isLoading = true;

  List<Map<String, dynamic>> courses = [];

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['courses'] != null) {
      final List<dynamic> courseList = doc.data()!['courses'];

      courses = courseList.map((c) {
        return {
          'code': (c['code'] ?? 'Unknown').toString(),
          'name': (c['name'] ?? 'Unknown Course').toString(),
          'credits': c['credits'] ?? 0,
          'eligible': c['eligible'] ?? false,
        };
      }).toList();
    } else {
      courses = [];
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = courses
        .where((c) => c['eligible'] == showEligible)
        .toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Eligibility'),
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => showEligible = true);
                        },
                        child: _buildStatusIndicator(
                          'Can Take',
                          Colors.green,
                          active: showEligible,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => showEligible = false);
                        },
                        child: _buildStatusIndicator(
                          'Cannot Take',
                          Colors.red,
                          active: !showEligible,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredCourses.isEmpty
                        ? const Center(
                            child: Text(
                              'No courses available',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCourses.length,
                            itemBuilder: (context, index) {
                              final course = filteredCourses[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    course['code'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(course['name']),
                                      Text(
                                        '${course['credits']} Credits',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    course['eligible']
                                        ? Icons.check_circle_outline
                                        : Icons.close,
                                    color: course['eligible']
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusIndicator(
    String label,
    Color color, {
    required bool active,
  }) {
    final count = courses
        .where((c) => color == Colors.green ? c['eligible'] : !c['eligible'])
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          color: active ? color : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
