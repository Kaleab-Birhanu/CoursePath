import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/grade.dart';

class GPACalculatorScreen extends StatefulWidget {
  const GPACalculatorScreen({super.key});

  @override
  State<GPACalculatorScreen> createState() => _GPACalculatorScreenState();
}

class _GPACalculatorScreenState extends State<GPACalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _creditsController = TextEditingController();
  String _selectedGrade = 'A';

  final List<String> _grades = [
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D+',
    'D',
    'F',
  ];

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  Future<void> _addGrade() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final grade = Grade(
      courseCode: _courseCodeController.text.trim(),
      courseName: _courseNameController.text.trim(),
      grade: _selectedGrade,
      credits: int.parse(_creditsController.text.trim()),
    );

    await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .collection('grades')
        .add(grade.toFirestore());

    if (mounted) {
      _courseCodeController.clear();
      _courseNameController.clear();
      _creditsController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Grade added successfully')));
    }
  }

  Future<void> _editGrade(
    BuildContext context,
    String userId,
    String gradeId,
    Grade currentGrade,
  ) async {
    _courseCodeController.text = currentGrade.courseCode;
    _courseNameController.text = currentGrade.courseName;
    _creditsController.text = currentGrade.credits.toString();
    _selectedGrade = currentGrade.grade;

    await showDialog(
      context: context,
      builder: (context) =>
          _buildAddGradeDialog(isEdit: true, gradeId: gradeId, userId: userId),
    );
  }

  double _calculateGPA(List<Grade> grades) {
    if (grades.isEmpty) return 0.0;

    double totalPoints = 0;
    int totalCredits = 0;

    for (var grade in grades) {
      totalPoints += grade.gradePoint * grade.credits;
      totalCredits += grade.credits;
    }

    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Calculator'),
        leading: const BackButton(),
      ),
      body: user == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(user.uid)
                  .collection('grades')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final gradesWithIds =
                    snapshot.data?.docs
                        .map(
                          (doc) => {
                            'id': doc.id,
                            'grade': Grade.fromFirestore(
                              doc.data() as Map<String, dynamic>,
                            ),
                          },
                        )
                        .toList() ??
                    [];

                final grades = gradesWithIds
                    .map((item) => item['grade'] as Grade)
                    .toList();

                final gpa = _calculateGPA(grades);

                return Column(
                  children: [
                    // GPA Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5865F2), Color(0xFF3B3FC4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'GPA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gpa.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${grades.fold<int>(0, (sum, g) => sum + g.credits)} Total Credits',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: grades.isEmpty
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Reset GPA'),
                                        content: const Text(
                                          'Are you sure you want to delete all grades? This cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Reset'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final batch = FirebaseFirestore.instance
                                          .batch();
                                      for (var item in gradesWithIds) {
                                        batch.delete(
                                          FirebaseFirestore.instance
                                              .collection('students')
                                              .doc(user.uid)
                                              .collection('grades')
                                              .doc(item['id'] as String),
                                        );
                                      }
                                      await batch.commit();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('All grades reset'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset GPA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5865F2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Grades List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Course Grades',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${grades.length} courses',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: grades.isEmpty
                          ? const Center(child: Text('No grades added yet'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: gradesWithIds.length,
                              itemBuilder: (context, index) {
                                final gradeItem = gradesWithIds[index];
                                final grade = gradeItem['grade'] as Grade;
                                final gradeId = gradeItem['id'] as String;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(
                                      grade.courseCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(grade.courseName),
                                        Text(
                                          '${grade.credits} credits',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getGradeColor(
                                              grade.grade,
                                            ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            grade.grade,
                                            style: TextStyle(
                                              color: _getGradeColor(
                                                grade.grade,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _editGrade(
                                              context,
                                              user.uid,
                                              gradeId,
                                              grade,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete Grade',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this grade?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    style:
                                                        ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await FirebaseFirestore.instance
                                                  .collection('students')
                                                  .doc(user.uid)
                                                  .collection('grades')
                                                  .doc(gradeId)
                                                  .delete();
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Grade deleted',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _buildAddGradeDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddGradeDialog({
    bool isEdit = false,
    String? gradeId,
    String? userId,
  }) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Grade' : 'Add Grade'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
                items: _grades.map((grade) {
                  return DropdownMenuItem(value: grade, child: Text(grade));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGrade = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(
                  labelText: 'Credits',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Must be a number';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final grade = Grade(
              courseCode: _courseCodeController.text.trim(),
              courseName: _courseNameController.text.trim(),
              grade: _selectedGrade,
              credits: int.parse(_creditsController.text.trim()),
            );

            if (isEdit && gradeId != null && userId != null) {
              await FirebaseFirestore.instance
                  .collection('students')
                  .doc(userId)
                  .collection('grades')
                  .doc(gradeId)
                  .update(grade.toFirestore());

              if (mounted) {
                _courseCodeController.clear();
                _courseNameController.clear();
                _creditsController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Grade updated successfully')),
                );
              }
            } else {
              _addGrade();
            }
          },
          child: Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    final point = Grade(
      courseCode: '',
      courseName: '',
      grade: grade,
      credits: 0,
    ).gradePoint;

    if (point >= 3.7) return Colors.green;
    if (point >= 3.0) return Colors.blue;
    if (point >= 2.0) return Colors.orange;
    return Colors.red;
  }
}
