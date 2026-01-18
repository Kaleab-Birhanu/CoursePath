import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AutoAssignmentScreen extends StatelessWidget {
  const AutoAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Assignment'),
        leading: const BackButton(),
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Class Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // All requests (approved adds, denied adds, approved drops)
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final allDocs = <Map<String, dynamic>>[];

                            // Add approved and denied add requests (filter by status)
                            if (addSnapshot.hasData) {
                              for (var doc in addSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                // Only show if status is approved or denied
                                if (data['status'] == 'approved' ||
                                    data['status'] == 'denied') {
                                  data['requestType'] = 'add';
                                  data['docId'] = doc.id;
                                  allDocs.add(data);
                                }
                              }
                            }

                            // Add approved drop requests
                            if (dropSnapshot.hasData) {
                              for (var doc in dropSnapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                // Only show approved drops
                                if (data['approved'] == true) {
                                  data['requestType'] = 'drop';
                                  data['docId'] = doc.id;
                                  allDocs.add(data);
                                }
                              }
                            }

                            if (allDocs.isEmpty) {
                              return const Center(
                                child: Text('No requests yet'),
                              );
                            }

                            // Sort by timestamp (handle null timestamps)
                            allDocs.sort((a, b) {
                              final aTime = a['timestamp'] as Timestamp?;
                              final bTime = b['timestamp'] as Timestamp?;

                              // Handle null timestamps - put them at the end
                              if (aTime == null && bTime == null) return 0;
                              if (aTime == null) return 1;
                              if (bTime == null) return -1;

                              return bTime.compareTo(aTime);
                            });

                            return ListView.builder(
                              itemCount: allDocs.length,
                              itemBuilder: (context, index) {
                                final cls = allDocs[index];
                                final isDrop = cls['requestType'] == 'drop';
                                final docId = cls['docId'] as String;

                                // Determine if approved based on request type
                                final isApproved = isDrop
                                    ? cls['approved'] == true
                                    : cls['status'] == 'approved';

                                // Determine status display
                                String statusText;
                                Color statusColor;

                                if (isDrop && isApproved) {
                                  statusText = 'Confirmed Drop';
                                  statusColor = Colors.orange;
                                } else if (!isDrop && isApproved) {
                                  statusText = 'Confirmed';
                                  statusColor = Colors.green;
                                } else {
                                  statusText = 'Rejected';
                                  statusColor = Colors.red;
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
                                    // Delete the assignment from Firestore
                                    await FirebaseFirestore.instance
                                        .collection('requests')
                                        .doc(isDrop ? 'drop' : 'add')
                                        .collection('items')
                                        .doc(docId)
                                        .delete();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Assignment cleared'),
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
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                cls['courseCode'] ?? 'N/A',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor
                                                          .withValues(
                                                            alpha: 0.15,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      statusText,
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    isApproved && !isDrop
                                                        ? Icons.check_circle
                                                        : isDrop
                                                        ? Icons.remove_circle
                                                        : Icons.cancel,
                                                    color: statusColor,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            cls['courseName'] ??
                                                'Unknown Course',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${cls['section'] ?? 'Section TBA'} - ${cls['instructor'] ?? 'Instructor TBA'}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                cls['schedule'] ??
                                                    'Schedule TBA',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (cls['location'] != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  cls['location'],
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
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
                  ),
                ],
              ),
            ),
    );
  }
}
