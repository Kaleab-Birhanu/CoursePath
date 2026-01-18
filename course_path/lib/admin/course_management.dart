import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Management'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No courses available'));
                }

                var courses = snapshot.data!.docs
                    .map(
                      (doc) => MapEntry(
                        doc.id,
                        Course.fromFirestore(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      ),
                    )
                    .toList();

                if (_searchQuery.isNotEmpty) {
                  courses = courses.where((entry) {
                    final course = entry.value;
                    return course.courseCode.toLowerCase().contains(
                          _searchQuery,
                        ) ||
                        course.courseName.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final courseId = courses[index].key;
                    final course = courses[index].value;
                    return _CourseManagementCard(
                      courseId: courseId,
                      course: course,
                      onEdit: () =>
                          _showCourseDialog(course: course, courseId: courseId),
                      onDelete: () => _deleteCourse(courseId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
      ),
    );
  }

  Future<void> _showCourseDialog({Course? course, String? courseId}) async {
    await showDialog(
      context: context,
      builder: (context) =>
          _CourseFormDialog(course: course, courseId: courseId),
    );
  }

  Future<void> _deleteCourse(String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Course deleted')));
      }
    }
  }
}

class _CourseManagementCard extends StatelessWidget {
  final String courseId;
  final Course course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseManagementCard({
    required this.courseId,
    required this.course,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(course.courseName),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${course.department} • Level ${course.level} • ${course.credits} credits',
            ),
            Text('${course.enrolled}/${course.capacity} enrolled'),
            Text('${course.instructor} • ${course.section}'),
          ],
        ),
      ),
    );
  }
}

class _CourseFormDialog extends StatefulWidget {
  final Course? course;
  final String? courseId;

  const _CourseFormDialog({this.course, this.courseId});

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseCodeController;
  late final TextEditingController _courseNameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _levelController;
  late final TextEditingController _creditsController;
  late final TextEditingController _instructorController;
  late final TextEditingController _sectionController;
  late final TextEditingController _scheduleController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _enrolledController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prerequisitesController;

  @override
  void initState() {
    super.initState();
    final course = widget.course;
    _courseCodeController = TextEditingController(
      text: course?.courseCode ?? '',
    );
    _courseNameController = TextEditingController(
      text: course?.courseName ?? '',
    );
    _departmentController = TextEditingController(
      text: course?.department ?? '',
    );
    _levelController = TextEditingController(
      text: course?.level.toString() ?? '',
    );
    _creditsController = TextEditingController(
      text: course?.credits.toString() ?? '',
    );
    _instructorController = TextEditingController(
      text: course?.instructor ?? '',
    );
    _sectionController = TextEditingController(text: course?.section ?? '');
    _scheduleController = TextEditingController(text: course?.schedule ?? '');
    _locationController = TextEditingController(text: course?.location ?? '');
    _capacityController = TextEditingController(
      text: course?.capacity.toString() ?? '',
    );
    _enrolledController = TextEditingController(
      text: course?.enrolled.toString() ?? '0',
    );
    _descriptionController = TextEditingController(
      text: course?.description ?? '',
    );
    _prerequisitesController = TextEditingController(
      text: course?.prerequisites.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _creditsController.dispose();
    _instructorController.dispose();
    _sectionController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _enrolledController.dispose();
    _descriptionController.dispose();
    _prerequisitesController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final prerequisites = _prerequisitesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final courseData = {
      'courseCode': _courseCodeController.text.trim(),
      'courseName': _courseNameController.text.trim(),
      'department': _departmentController.text.trim(),
      'level': int.parse(_levelController.text.trim()),
      'credits': int.parse(_creditsController.text.trim()),
      'instructor': _instructorController.text.trim(),
      'section': _sectionController.text.trim(),
      'schedule': _scheduleController.text.trim(),
      'location': _locationController.text.trim(),
      'capacity': int.parse(_capacityController.text.trim()),
      'enrolled': int.parse(_enrolledController.text.trim()),
      'prerequisites': prerequisites,
      'description': _descriptionController.text.trim(),
    };

    if (widget.courseId != null) {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update(courseData);
    } else {
      await FirebaseFirestore.instance.collection('courses').add(courseData);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.courseId != null ? 'Course updated' : 'Course added',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.course != null ? 'Edit Course' : 'Add Course'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_courseCodeController, 'Course Code'),
              _buildTextField(_courseNameController, 'Course Name'),
              _buildTextField(_departmentController, 'Department'),
              _buildTextField(_levelController, 'Level', isNumber: true),
              _buildTextField(_creditsController, 'Credits', isNumber: true),
              _buildTextField(_instructorController, 'Instructor'),
              _buildTextField(_sectionController, 'Section'),
              _buildTextField(_scheduleController, 'Schedule'),
              _buildTextField(_locationController, 'Location'),
              _buildTextField(_capacityController, 'Capacity', isNumber: true),
              _buildTextField(_enrolledController, 'Enrolled', isNumber: true),
              _buildTextField(
                _descriptionController,
                'Description',
                maxLines: 3,
              ),
              _buildTextField(
                _prerequisitesController,
                'Prerequisites (comma-separated)',
                required: false,
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
        ElevatedButton(onPressed: _saveCourse, child: const Text('Save')),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (value) {
          if (required && (value?.isEmpty ?? true)) return 'Required';
          if (isNumber && int.tryParse(value!) == null) {
            return 'Must be a number';
          }
          return null;
        },
      ),
    );
  }
}
