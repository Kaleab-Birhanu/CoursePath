import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:course_path/student/course_eligibility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_drop.dart';
import 'auto_assignment.dart';
import 'student_profile.dart';
import 'notifications_screen.dart';
import 'gpa_calculator.dart';

class StudentDashboard extends StatefulWidget {
  final String name;
  final String studentID;

  const StudentDashboard({
    super.key,
    required this.name,
    required this.studentID,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0; // bottom nav index

  final List<Widget> _pages = const [_DashboardContent(), StudentProfile()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF5865F2),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ---------------- DASHBOARD CONTENT ----------------
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  void onActionTap(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CourseEligibilityScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddDropScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AutoAssignmentScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GPACalculatorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = DateTime.now().add(const Duration(days: 2));

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF4F63F6),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome,',
                      style: TextStyle(color: Colors.white70, fontSize: 40),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // DYNAMIC STUDENT NAME
                      (context
                                  .findAncestorWidgetOfExactType<
                                    StudentDashboard
                                  >())
                              ?.name ??
                          'Student',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // DYNAMIC STUDENT ID
                      'ID: ${(context.findAncestorWidgetOfExactType<StudentDashboard>())?.studentID ?? 'Unknown'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Deadline info icon
                    IconButton(
                      onPressed: () {
                        final now = DateTime.now();
                        final daysLeft = deadline.difference(now).inDays;
                        final bool isNearDeadline = daysLeft <= 3;
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: isNearDeadline
                                  ? Colors.red[50]
                                  : Colors.white,
                              title: Text(
                                isNearDeadline
                                    ? "⚠️ Add/Drop period deadline is near!"
                                    : "Add/Drop period deadline",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isNearDeadline
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                              content: Text(
                                "Deadline: ${DateFormat('MMM d, yyyy').format(deadline)}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      tooltip:
                          'Add/Drop deadline: ${DateFormat('MMM d, yyyy').format(deadline)}',
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    // Notification icon with badge
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('requests')
                          .doc('add')
                          .collection('items')
                          .where(
                            'studentId',
                            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                          )
                          .snapshots(),
                      builder: (context, addSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('requests')
                              .doc('drop')
                              .collection('items')
                              .where(
                                'studentId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser?.uid,
                              )
                              .snapshots(),
                          builder: (context, dropSnapshot) {
                            int notificationCount = 0;

                            // Count unread approved and denied add requests
                            if (addSnapshot.hasData) {
                              notificationCount += addSnapshot.data!.docs.where(
                                (doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return (data['status'] == 'approved' ||
                                          data['status'] == 'denied') &&
                                      data['read'] != true;
                                },
                              ).length;
                            }

                            // Count unread approved drop requests
                            if (dropSnapshot.hasData) {
                              notificationCount += dropSnapshot.data!.docs
                                  .where((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    return data['approved'] == true &&
                                        data['read'] != true;
                                  })
                                  .length;
                            }

                            return Stack(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.notifications_none,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                if (notificationCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        notificationCount > 9
                                            ? '9+'
                                            : '$notificationCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                quickActionCard(Icons.book, 'Course Eligibility', 0),
                const SizedBox(height: 12),
                quickActionCard(Icons.add, 'Add / Drop', 1),
                const SizedBox(height: 12),
                quickActionCard(Icons.grid_view, 'Auto Assignment', 2),
                const SizedBox(height: 12),
                quickActionCard(Icons.calculate, 'GPA Calculator', 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget quickActionCard(IconData icon, String title, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onActionTap(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8EBFF),
              child: Icon(icon, color: const Color(0xFF5865F2)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
