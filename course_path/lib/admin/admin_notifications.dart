import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
        backgroundColor: const Color(0xFF4F63F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
              if (addSnapshot.connectionState == ConnectionState.waiting ||
                  dropSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRequests = <Map<String, dynamic>>[];

              // Add pending add requests (no status field)
              if (addSnapshot.hasData) {
                for (var doc in addSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['status'] == null) {
                    data['requestType'] = 'add';
                    data['docId'] = doc.id;
                    allRequests.add(data);
                  }
                }
              }

              // Add pending drop requests (no status field)
              if (dropSnapshot.hasData) {
                for (var doc in dropSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['status'] == null) {
                    data['requestType'] = 'drop';
                    data['docId'] = doc.id;
                    allRequests.add(data);
                  }
                }
              }

              if (allRequests.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No pending requests',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All requests have been processed',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              // Sort by timestamp (newest first)
              allRequests.sort((a, b) {
                final aTime = a['timestamp'] as Timestamp?;
                final bTime = b['timestamp'] as Timestamp?;

                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;

                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allRequests.length,
                itemBuilder: (context, index) {
                  final request = allRequests[index];
                  final isDrop = request['requestType'] == 'drop';
                  final timestamp = request['timestamp'] as Timestamp?;
                  final docId = request['docId'] as String;

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
                      child: const Icon(Icons.delete, color: Colors.white),
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
                            content: Text('Request cleared'),
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
                          backgroundColor: isDrop
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15),
                          child: Icon(
                            isDrop ? Icons.remove : Icons.add,
                            color: isDrop ? Colors.orange : Colors.blue,
                          ),
                        ),
                        title: Text(
                          isDrop ? 'Drop Request' : 'Add Request',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${request['courseCode'] ?? 'N/A'} - ${request['courseName'] ?? 'Unknown Course'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Student: ${request['studentName'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
