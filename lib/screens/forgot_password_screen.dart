import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 1. PURPLE GRADIENT BACKGROUND
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HEADER TEXT
                  const Text(
                    "PSMS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Project Space Management System",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // 2. FORGOT PASSWORD CARD
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B6BBF),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Enter your email to receive a verification code",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 25),

                          // EMAIL INPUT
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Email Address *",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // SEND CODE BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B6BBF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                // Logic to send email goes here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Verification code sent!")),
                                );
                              },
                              child: const Text("Send Verification Code", style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // BACK TO LOGIN LINK
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Goes back to Login
                            },
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text("Back to Login"),
                          ),
                          
                          const Divider(height: 30),

                          // SIGN UP LINK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?", style: TextStyle(fontSize: 12)),
                              TextButton(
                                onPressed: () {
                                  // We can't navigate directly to Signup from here easily
                                  // relying on Login's navigation or using named routes is better
                                  // For now, let's just go back to login so they can click signup there
                                  Navigator.pop(context);
                                },
                                child: const Text("Sign Up", style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}