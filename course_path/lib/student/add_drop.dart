import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddDropScreen extends StatefulWidget {
  const AddDropScreen({super.key});

  @override
  State<AddDropScreen> createState() => _AddDropScreenState();
}

class _AddDropScreenState extends State<AddDropScreen> {
  bool isAddMode = true;
  bool isLoading = true;
  List<Map<String, dynamic>> allCourses = [];

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
      allCourses = courseList.map((c) {
        return {
          'code': c['code'] ?? 'N/A',
          'title': c['name'] ?? 'Unknown Course',
          'credits': c['credits'] ?? 0,
          'eligible': c['eligible'] ?? false,
          'section': c['section'] ?? 'TBA',
          'instructor': c['instructor'] ?? 'TBA',
          'schedule': c['schedule'] ?? 'To be announced',
        };
      }).toList();
    }

    setState(() => isLoading = false);
  }

  Future<void> sendRequest(Map<String, dynamic> course, bool isAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();
    final studentName = studentDoc.data()?['name'] ?? 'Unknown Student';

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(isAdd ? 'add' : 'drop')
          .collection('items')
          .add({
            'studentId': user.uid,
            'studentName': studentName,
            'courseCode': course['code'],
            'courseName': course['title'],
            'section': course['section'],
            'instructor': course['instructor'],
            'schedule': course['schedule'],
            'credits': course['credits'],
            'requestType': isAdd ? 'add' : 'drop',
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request sent to admin')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedCourses = allCourses.where((c) {
      return isAddMode ? c['eligible'] == true : c['eligible'] == false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Add / Drop Courses"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => isAddMode = true),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Course"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAddMode
                          ? Colors.green
                          : Colors.grey[300],
                      foregroundColor: isAddMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => isAddMode = false),
                    icon: const Icon(Icons.remove),
                    label: const Text("Drop Course"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isAddMode
                          ? const Color(0xFFEA3C30)
                          : Colors.grey[300],
                      foregroundColor: !isAddMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedCourses.isEmpty
                  ? const Center(child: Text('No courses available'))
                  : ListView.builder(
                      itemCount: displayedCourses.length,
                      itemBuilder: (context, index) {
                        final course = displayedCourses[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course['code'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        course['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (course['instructor'] != 'TBA' &&
                                          course['instructor'] != null)
                                        Text(
                                          '${course['instructor']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (course['schedule'] !=
                                              'To be announced' &&
                                          course['schedule'] != 'TBA')
                                        Text(
                                          course['schedule'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      Text(
                                        '${course['credits']} Credits',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      sendRequest(course, isAddMode),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAddMode
                                        ? Colors.green
                                        : const Color(0xFFEA3C30),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(isAddMode ? 'Add' : 'Drop'),
                                ),
                              ],
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
}
