import 'package:flutter/material.dart';
import 'login_screen.dart'; // To navigate safely after success

class VerifyEmailScreen extends StatefulWidget {
  final String email; // We accept the email to show it in the message
  
  const VerifyEmailScreen({super.key, this.email = "pavani@gmail.com"});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();

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

                  // 2. VERIFICATION CARD
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
                            "Verify Email",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5B6BBF),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Enter the verification code sent to your email",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 20),

                          // BLUE INFO BOX
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05), // Light blue background
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                                      children: [
                                        const TextSpan(text: "We've sent a verification code to\n"),
                                        TextSpan(
                                          text: widget.email, 
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(text: ". Check your email (including spam folder) and enter the code below."),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // CODE INPUT
                          TextField(
                            controller: _codeController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: "Verification Code",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // VERIFY BUTTON
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
                                // Logic to verify code goes here
                                // For now, let's assume success and go to Login
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Email Verified Successfully!")),
                                );
                                Navigator.pushAndRemoveUntil(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const LoginScreen()), 
                                  (route) => false // Clears all history so they can't go back
                                );
                              },
                              child: const Text("Verify Email", style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // RESEND CODE LINK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Didn't receive the code?", style: TextStyle(fontSize: 12)),
                              TextButton(
                                onPressed: () {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Code resent!")),
                                  );
                                },
                                child: const Text("Resend Code", style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),

                          // BACK TO SIGN UP
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Back to Sign Up", 
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                            ),
                          ),
                          
                          // RED ERROR MESSAGE (Static for now as per design)
                          const SizedBox(height: 10),
                          const Text(
                            "Verification code sent to your email.", 
                            style: TextStyle(color: Colors.red, fontSize: 11)
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