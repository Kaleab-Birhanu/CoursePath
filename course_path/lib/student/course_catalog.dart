import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseCatalogScreen extends StatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  State<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends State<CourseCatalogScreen> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedLevel = 'All';
  String _selectedInstructor = 'All';
  List<String> _departments = ['All'];
  List<String> _instructors = ['All'];

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .get();
    final departments = <String>{'All'};
    final instructors = <String>{'All'};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['department'] != null) departments.add(data['department']);
      if (data['instructor'] != null) instructors.add(data['instructor']);
    }

    setState(() {
      _departments = departments.toList()..sort();
      _instructors = instructors.toList()..sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Catalog'),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          // Search bar
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

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  'Department',
                  _selectedDepartment,
                  _departments,
                  (value) {
                    setState(() => _selectedDepartment = value);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Level',
                  _selectedLevel,
                  ['All', '100', '200', '300', '400'],
                  (value) {
                    setState(() => _selectedLevel = value);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Instructor',
                  _selectedInstructor,
                  _instructors,
                  (value) {
                    setState(() => _selectedInstructor = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Course list
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
                      (doc) => Course.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();

                // Apply filters
                courses = courses.where((course) {
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      course.courseCode.toLowerCase().contains(_searchQuery) ||
                      course.courseName.toLowerCase().contains(_searchQuery);
                  final matchesDept =
                      _selectedDepartment == 'All' ||
                      course.department == _selectedDepartment;
                  final matchesLevel =
                      _selectedLevel == 'All' ||
                      course.level.toString().startsWith(_selectedLevel[0]);
                  final matchesInstructor =
                      _selectedInstructor == 'All' ||
                      course.instructor == _selectedInstructor;

                  return matchesSearch &&
                      matchesDept &&
                      matchesLevel &&
                      matchesInstructor;
                }).toList();

                if (courses.isEmpty) {
                  return const Center(
                    child: Text('No courses match your filters'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    return _CourseCard(course: courses[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selected,
    List<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return options.map((option) {
          return PopupMenuItem(value: option, child: Text(option));
        }).toList();
      },
      child: Chip(
        label: Text('$label: $selected'),
        avatar: const Icon(Icons.filter_list, size: 18),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _CourseDetailsDialog(course: course),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                        Text(
                          course.courseName,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: course.isFull
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          course.isFull
                              ? 'Full'
                              : '${course.availableSeats} seats',
                          style: TextStyle(
                            color: course.isFull ? Colors.red : Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${course.credits} credits',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.instructor,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.schedule,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.location,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseDetailsDialog extends StatelessWidget {
  final Course course;

  const _CourseDetailsDialog({required this.course});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(course.courseCode),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              course.courseName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (course.description != null) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(course.description!),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Department', course.department),
            _buildDetailRow('Level', course.level.toString()),
            _buildDetailRow('Credits', course.credits.toString()),
            _buildDetailRow('Instructor', course.instructor),
            _buildDetailRow('Section', course.section),
            _buildDetailRow('Schedule', course.schedule),
            _buildDetailRow('Location', course.location),
            _buildDetailRow(
              'Capacity',
              '${course.enrolled}/${course.capacity}',
            ),
            if (course.prerequisites.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Prerequisites:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...course.prerequisites.map((prereq) => Text('• $prereq')),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
