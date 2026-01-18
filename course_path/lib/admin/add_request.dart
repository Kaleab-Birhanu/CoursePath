import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddRequestsScreen extends StatelessWidget {
  const AddRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF1A237E),
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Requests',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF5C6BC0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Pending Add Requests',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('requests')
                  .doc('add')
                  .collection('items')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter out requests that already have a status (approved/denied)
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == null;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No requests currently'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return RequestCard(
                      courseCode: data['courseCode'] ?? '',
                      courseName: data['courseName'] ?? '',
                      requester: data['studentName'] ?? 'Unknown',
                      onAccept: () async {
                        await docs[index].reference.update({
                          'approved': true,
                          'status': 'approved',
                        });
                      },
                      onDeny: () async {
                        await docs[index].reference.update({
                          'approved': false,
                          'status': 'denied',
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final String requester;
  final VoidCallback onAccept;
  final VoidCallback onDeny;

  const RequestCard({
    super.key,
    required this.courseCode,
    required this.courseName,
    required this.requester,
    required this.onAccept,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            courseCode,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            courseName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Requested by: $requester',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
              fontSize: 16,
            ),
          ),
          const Divider(height: 30, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                label: 'Accept',
                color: Colors.green.shade500,
                onPressed: onAccept,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                label: 'Deny',
                color: Colors.red.shade400,
                onPressed: onDeny,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 45,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
