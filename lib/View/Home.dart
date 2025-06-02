import 'package:flutter/material.dart';
import 'package:smart_attend/View/Add_Student.dart';
import 'package:smart_attend/View/Show%20All%20Student.dart';
import 'create_session_screen.dart';
import 'attendance_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel'),actions: [
       ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Create New Session'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateSessionScreen()));
              },
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              child: const Text('View Attendance Reports'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AttendanceListScreen()));
              },
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              child: const Text('Add Student'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Add_Student()));
              },
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              child: const Text('Show Student'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ShowAllStudent()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
