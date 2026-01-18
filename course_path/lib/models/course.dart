class Course {
  final String id;
  final String courseCode;
  final String courseName;
  final String department;
  final int level;
  final int credits;
  final String instructor;
  final String section;
  final String schedule;
  final String location;
  final int capacity;
  final int enrolled;
  final List<String> prerequisites;
  final String? description;

  Course({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.department,
    required this.level,
    required this.credits,
    required this.instructor,
    required this.section,
    required this.schedule,
    required this.location,
    required this.capacity,
    required this.enrolled,
    required this.prerequisites,
    this.description,
  });

  factory Course.fromFirestore(Map<String, dynamic> data, String id) {
    return Course(
      id: id,
      courseCode: data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      department: data['department'] ?? '',
      level: data['level'] ?? 0,
      credits: data['credits'] ?? 0,
      instructor: data['instructor'] ?? '',
      section: data['section'] ?? '',
      schedule: data['schedule'] ?? '',
      location: data['location'] ?? '',
      capacity: data['capacity'] ?? 0,
      enrolled: data['enrolled'] ?? 0,
      prerequisites: List<String>.from(data['prerequisites'] ?? []),
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'department': department,
      'level': level,
      'credits': credits,
      'instructor': instructor,
      'section': section,
      'schedule': schedule,
      'location': location,
      'capacity': capacity,
      'enrolled': enrolled,
      'prerequisites': prerequisites,
      'description': description,
    };
  }

  bool get isFull => enrolled >= capacity;
  int get availableSeats => capacity - enrolled;
}
