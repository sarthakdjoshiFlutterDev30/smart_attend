import 'package:flutter/material.dart';
import 'package:smart_attend/Controller/ApiService.dart';
import 'package:smart_attend/View/Add_Student.dart';
import 'package:smart_attend/View/Show%20All%20Student.dart';

import 'attendance_list_screen.dart';
import 'create_session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var title=TextEditingController();
    var body=TextEditingController();
    ApiService api=ApiService();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel'), actions: []),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Create New Session'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateSessionScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: const Text('View Attendance Reports'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendanceListScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Add Student'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Add_Student()),
                );
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Show Student'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShowAllStudent()),
                );
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Send Notification To Students'),
              onPressed: () {
                showDialog(context: context, builder: (context) {
                  return AlertDialog(
                    title: Text("Change Password"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: title,
                          decoration: InputDecoration(
                            labelText: "Enter Notification Title",
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: body,
                          decoration: InputDecoration(
                            labelText: "Enter Notification Body",
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          title.clear();
                          body.clear();
                        },
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (title.text.isEmpty || body.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Fields cannot be empty")));
                            return;
                          }else{
                            String title1=title.text;
                            String body1=body.text;
                            print(title1);
                            print(body1);
                            title.clear();
                            body.clear();
                            api.sendNotification(title1, body1).then((_){
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Notification Sent")));
                            });
                            Navigator.pop(context);

                          }

                          },

                        child: Text("Send"),
                      ),
                    ],
                  );

                },);
              },
            ),
          ],
        ),
      ),
    );
  }
}
