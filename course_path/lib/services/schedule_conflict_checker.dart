import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleConflictChecker {
  static Future<ConflictResult> checkConflicts(
    String studentId,
    String newSchedule,
  ) async {
    // Get student's approved add requests
    final addSnapshot = await FirebaseFirestore.instance
        .collection('requests')
        .doc('add')
        .collection('items')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'approved')
        .get();

    final enrolledSchedules = <Map<String, dynamic>>[];

    for (var doc in addSnapshot.docs) {
      final data = doc.data();
      enrolledSchedules.add({
        'courseCode': data['courseCode'],
        'courseName': data['courseName'],
        'schedule': data['schedule'],
      });
    }

    // Parse the new schedule
    final newTimes = _parseSchedule(newSchedule);
    if (newTimes.isEmpty) {
      return ConflictResult(
        hasConflict: false,
        message: 'No schedule conflicts',
      );
    }

    // Check for conflicts
    for (var enrolled in enrolledSchedules) {
      final enrolledSchedule = enrolled['schedule'] as String;
      final enrolledTimes = _parseSchedule(enrolledSchedule);

      if (_hasTimeOverlap(newTimes, enrolledTimes)) {
        return ConflictResult(
          hasConflict: true,
          message:
              'Schedule conflict with ${enrolled['courseCode']} (${enrolled['courseName']})',
          conflictingCourse: enrolled['courseCode'],
        );
      }
    }

    return ConflictResult(hasConflict: false, message: 'No schedule conflicts');
  }

  static List<ScheduleTime> _parseSchedule(String schedule) {
    // Expected format: "MWF 10:00-11:00" or "TR 14:00-15:30"
    final times = <ScheduleTime>[];

    try {
      final parts = schedule.split(' ');
      if (parts.length < 2) return times;

      final days = parts[0];
      final timeRange = parts[1];
      final timeParts = timeRange.split('-');

      if (timeParts.length != 2) return times;

      final startTime = _parseTime(timeParts[0]);
      final endTime = _parseTime(timeParts[1]);

      // Parse days
      final daysList = <String>[];
      for (var i = 0; i < days.length; i++) {
        final day = days[i];
        if (i + 1 < days.length && days[i + 1] == 'R') {
          // Handle 'TR' for Thursday
          daysList.add('TR');
          i++; // Skip next character
        } else {
          daysList.add(day);
        }
      }

      for (var day in daysList) {
        times.add(
          ScheduleTime(day: day, startMinutes: startTime, endMinutes: endTime),
        );
      }
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }

    return times;
  }

  static int _parseTime(String time) {
    // Convert "10:00" to minutes since midnight
    final parts = time.split(':');
    if (parts.length != 2) return 0;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;

    return hours * 60 + minutes;
  }

  static bool _hasTimeOverlap(
    List<ScheduleTime> times1,
    List<ScheduleTime> times2,
  ) {
    for (var t1 in times1) {
      for (var t2 in times2) {
        if (t1.day == t2.day) {
          // Check if times overlap
          if (t1.startMinutes < t2.endMinutes &&
              t1.endMinutes > t2.startMinutes) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

class ScheduleTime {
  final String day;
  final int startMinutes;
  final int endMinutes;

  ScheduleTime({
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });
}

class ConflictResult {
  final bool hasConflict;
  final String message;
  final String? conflictingCourse;

  ConflictResult({
    required this.hasConflict,
    required this.message,
    this.conflictingCourse,
  });
}
