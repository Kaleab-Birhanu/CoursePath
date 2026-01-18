import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/grade.dart';

class PrerequisiteChecker {
  static Future<PrerequisiteResult> checkPrerequisites(
    String studentId,
    Course course,
  ) async {
    if (course.prerequisites.isEmpty) {
      return PrerequisiteResult(
        canEnroll: true,
        message: 'No prerequisites required',
      );
    }

    // Get student's completed courses
    final gradesSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .collection('grades')
        .get();

    final completedCourses = gradesSnapshot.docs
        .map((doc) => Grade.fromFirestore(doc.data()))
        .where((grade) => _isPassing(grade.grade))
        .map((grade) => grade.courseCode)
        .toSet();

    // Check if all prerequisites are met
    final missingPrereqs = <String>[];
    for (var prereq in course.prerequisites) {
      if (!completedCourses.contains(prereq)) {
        missingPrereqs.add(prereq);
      }
    }

    if (missingPrereqs.isEmpty) {
      return PrerequisiteResult(
        canEnroll: true,
        message: 'All prerequisites met',
      );
    }

    return PrerequisiteResult(
      canEnroll: false,
      message: 'Missing prerequisites: ${missingPrereqs.join(", ")}',
      missingPrerequisites: missingPrereqs,
    );
  }

  static bool _isPassing(String grade) {
    final passingGrades = [
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
    ];
    return passingGrades.contains(grade.toUpperCase());
  }
}

class PrerequisiteResult {
  final bool canEnroll;
  final String message;
  final List<String> missingPrerequisites;

  PrerequisiteResult({
    required this.canEnroll,
    required this.message,
    this.missingPrerequisites = const [],
  });
}
