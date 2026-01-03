import 'package:flutter/material.dart';

class AddDropScreen extends StatefulWidget {
  const AddDropScreen({super.key});

  @override
  State<AddDropScreen> createState() => _AddDropScreenState();
}

class _AddDropScreenState extends State<AddDropScreen> {
  bool isAddMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Add / Drop Courses"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add / Drop toggle buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isAddMode = true;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Add Course"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isAddMode ? Colors.blue : Colors.grey[300],
                      foregroundColor:
                          isAddMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        isAddMode = false;
                      });
                    },
                    icon: const Icon(Icons.remove),
                    label: const Text("Drop Course"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          !isAddMode ? Colors.red : Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: isAddMode
                    ? "Search courses to add..."
                    : "Search courses to drop...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Course list
            Expanded(
              child: ListView(
                children: [
                  CourseCard(
                    code: "CS301",
                    section: "Section A",
                    title: "Database Systems",
                    instructor: "Dr. Smith",
                    schedule: "Mon, Wed 10:00 - 11:30",
                    credits: "3 Credits",
                    seats: "12/30 seats",
                    lowSeats: false,
                    actionText: isAddMode ? "Add" : "Drop",
                    actionColor: isAddMode ? Colors.blue : Colors.red,
                  ),
                  CourseCard(
                    code: "CS320",
                    section: "Section B",
                    title: "Software Engineering",
                    instructor: "Prof. Johnson",
                    schedule: "Tue, Thu 14:00 - 15:30",
                    credits: "3 Credits",
                    seats: "5/25 seats",
                    lowSeats: true,
                    actionText: isAddMode ? "Add" : "Drop",
                    actionColor: isAddMode ? Colors.blue : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class CourseCard extends StatelessWidget {
  final String code;
  final String section;
  final String title;
  final String instructor;
  final String schedule;
  final String credits;
  final String seats;
  final bool lowSeats;
  final String actionText;
  final Color actionColor;

  const CourseCard({
    super.key,
    required this.code,
    required this.section,
    required this.title,
    required this.instructor,
    required this.schedule,
    required this.credits,
    required this.seats,
    required this.actionText,
    required this.actionColor,
    this.lowSeats = false,
  });

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$code  •  $section",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(instructor),
                  const SizedBox(height: 6),
                  Text(schedule),
                  const SizedBox(height: 6),
                  Text(
                    "$credits   $seats",
                    style: TextStyle(
                      color: lowSeats ? Colors.orange : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}
