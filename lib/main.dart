import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSMS Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _statusMessage = "Press the button to test connection";
  
  // URL CONFIGURATION:
  // Android Emulator uses 10.0.2.2 to access your PC's localhost
  final String backendUrl = "http://10.0.2.2:8080/api/projects"; 

  Future<void> testConnection() async {
    setState(() {
      _statusMessage = "Connecting...";
    });

    try {
      final response = await http.get(Uri.parse(backendUrl));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = "Success! Connected to Backend.\n\nData: ${response.body}";
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _statusMessage = "Connected, but 401 Unauthorized.\n(You need to log in first)";
        });
      } else {
        setState(() {
          _statusMessage = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Connection Failed.\n\nMake sure Spring Boot is running.\nError: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PSMS Mobile Test")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mobile_friendly, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: testConnection,
                icon: const Icon(Icons.wifi),
                label: const Text("Test Backend Connection"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}