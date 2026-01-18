class Grade {
  final String courseCode;
  final String courseName;
  final String grade;
  final int credits;
  final String semester;

  Grade({
    required this.courseCode,
    required this.courseName,
    required this.grade,
    required this.credits,
    required this.semester,
  });

  factory Grade.fromFirestore(Map<String, dynamic> data) {
    return Grade(
      courseCode: data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      grade: data['grade'] ?? '',
      credits: data['credits'] ?? 0,
      semester: data['semester'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'grade': grade,
      'credits': credits,
      'semester': semester,
    };
  }

  double get gradePoint {
    switch (grade.toUpperCase()) {
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return 0.0;
    }
  }
}
