import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen opens
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Mark add requests as read
      final addDocs = await FirebaseFirestore.instance
          .collection('requests')
          .doc('add')
          .collection('items')
          .where('studentId', isEqualTo: user.uid)
          .get();

      for (var doc in addDocs.docs) {
        final data = doc.data();
        if ((data['status'] == 'approved' || data['status'] == 'denied') &&
            data['read'] != true) {
          await doc.reference.update({'read': true});
        }
      }

      // Mark drop requests as read
      final dropDocs = await FirebaseFirestore.instance
          .collection('requests')
          .doc('drop')
          .collection('items')
          .where('studentId', isEqualTo: user.uid)
          .get();

      for (var doc in dropDocs.docs) {
        final data = doc.data();
        if (data['approved'] == true && data['read'] != true) {
          await doc.reference.update({'read': true});
        }
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF4F63F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .doc('add')
                  .collection('items')
                  .where('studentId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, addSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('requests')
                      .doc('drop')
                      .collection('items')
                      .where('studentId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, dropSnapshot) {
                    if (addSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        dropSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allNotifications = <Map<String, dynamic>>[];

                    // Add approved and denied add requests
                    if (addSnapshot.hasData) {
                      for (var doc in addSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['status'] == 'approved' ||
                            data['status'] == 'denied') {
                          data['requestType'] = 'add';
                          data['docId'] = doc.id;
                          allNotifications.add(data);
                        }
                      }
                    }

                    // Add approved drop requests
                    if (dropSnapshot.hasData) {
                      for (var doc in dropSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['approved'] == true) {
                          data['requestType'] = 'drop';
                          data['docId'] = doc.id;
                          allNotifications.add(data);
                        }
                      }
                    }

                    if (allNotifications.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Sort by timestamp (newest first)
                    allNotifications.sort((a, b) {
                      final aTime = a['timestamp'] as Timestamp?;
                      final bTime = b['timestamp'] as Timestamp?;

                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;

                      return bTime.compareTo(aTime);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = allNotifications[index];
                        final isApproved = notification['approved'] == true;
                        final isDrop = notification['requestType'] == 'drop';
                        final timestamp =
                            notification['timestamp'] as Timestamp?;
                        final docId = notification['docId'] as String;

                        // Determine notification type
                        String title;
                        String message;
                        IconData icon;
                        Color color;

                        if (isDrop && isApproved) {
                          title = 'Drop Request Approved';
                          message =
                              'Your request to drop ${notification['courseCode']} has been approved.';
                          icon = Icons.check_circle;
                          color = Colors.orange;
                        } else if (!isDrop && isApproved) {
                          title = 'Add Request Approved';
                          message =
                              'Your request to add ${notification['courseCode']} has been approved.';
                          icon = Icons.check_circle;
                          color = Colors.green;
                        } else {
                          title = 'Add Request Denied';
                          message =
                              'Your request to add ${notification['courseCode']} has been denied.';
                          icon = Icons.cancel;
                          color = Colors.red;
                        }

                        return Dismissible(
                          key: Key(docId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) async {
                            // Delete the notification from Firestore
                            await FirebaseFirestore.instance
                                .collection('requests')
                                .doc(isDrop ? 'drop' : 'add')
                                .collection('items')
                                .doc(docId)
                                .delete();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notification cleared'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(icon, color: color),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(message),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${notification['courseCode'] ?? 'N/A'} - ${notification['courseName'] ?? 'Unknown Course'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (timestamp != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'MMM d, yyyy • h:mm a',
                                      ).format(timestamp.toDate()),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
