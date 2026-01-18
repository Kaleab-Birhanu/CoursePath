import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_request.dart';
import 'drop_request.dart';
import 'admin_profile.dart';
import 'admin_notifications.dart';

class AdminDashboard extends StatefulWidget {
  final String name;
  final String email;

  const AdminDashboard({super.key, required this.name, required this.email});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Pass the admin info to the profile page
    _pages = [
      HomeScreenPlaceholder(name: widget.name),
      AdminProfile(name: widget.name, email: widget.email),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF4F63F6),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// ---------------- Helper Widgets ----------------
class HomeScreenPlaceholder extends StatelessWidget {
  final String name;
  const HomeScreenPlaceholder({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final deadline = DateTime.now().add(const Duration(days: 2));
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top purple header
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
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome,",
                        style: TextStyle(color: Colors.white70, fontSize: 40),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Deadline info icon
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              final now = DateTime.now();
                              final daysLeft = deadline.difference(now).inDays;
                              final bool isNearDeadline = daysLeft <= 3;
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
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
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
                      // Notification icon with badge for pending requests
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('requests')
                            .doc('add')
                            .collection('items')
                            .snapshots(),
                        builder: (context, addSnapshot) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('requests')
                                .doc('drop')
                                .collection('items')
                                .snapshots(),
                            builder: (context, dropSnapshot) {
                              int pendingCount = 0;

                              // Count pending add requests (no status field)
                              if (addSnapshot.hasData) {
                                pendingCount += addSnapshot.data!.docs.where((
                                  doc,
                                ) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return data['status'] == null;
                                }).length;
                              }

                              // Count pending drop requests (no status field)
                              if (dropSnapshot.hasData) {
                                pendingCount += dropSnapshot.data!.docs.where((
                                  doc,
                                ) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return data['status'] == null;
                                }).length;
                              }

                              return Stack(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const AdminNotificationsScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  if (pendingCount > 0)
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
                                          pendingCount > 9
                                              ? '9+'
                                              : '$pendingCount',
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

            const SizedBox(height: 24),

            // Quick Actions title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.add,
                    iconBg: const Color(0xFFE8ECFF),
                    title: "Add Requests",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _ActionTile(
                    icon: Icons.remove,
                    iconBg: const Color(0xFFE8ECFF),
                    title: "Drop Requests",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DropRequestsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconBg,
              child: Icon(icon, color: const Color(0xFF4F63F6)),
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
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
