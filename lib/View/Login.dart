import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_attend/View/Home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var email = TextEditingController();
  var password = TextEditingController();
  bool _isLoading = false;
  bool show = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if the user is already logged in
  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    if (isLoggedIn == true) {
      // Navigate to HomeScreen if already logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: email,
              style: const TextStyle(fontSize: 20, color: Colors.black),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter Email Address",
                hintStyle: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: password,
              style: const TextStyle(fontSize: 20, color: Colors.black),
              keyboardType: TextInputType.text,
              obscureText: show,
              obscuringCharacter: "*",
              decoration: InputDecoration(
                suffixIcon: TextButton(
                  onPressed: () {
                    setState(() {
                      show = !show;
                    });
                  },
                  child: Text(
                    (show) ? "Show" : "Hide",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                ),
                hintText: "Enter Password",
                hintStyle: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 10),
            (_isLoading)
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (email.text.trim().isEmpty ||
                          password.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Enter Email Or Password",
                              style: TextStyle(fontSize: 18),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        if (email.text.toString() == "admin" &&
                            password.text.toString() == "admin123") {
                          // Save login state
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', true);

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Email-Id And Password Is Not Same",
                              ),
                            ),
                          );
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      "Login",
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
