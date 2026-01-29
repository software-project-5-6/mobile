import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart'; // Ensure this file exists in lib/
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureAmplify();
  runApp(const MyApp());
}

// This function connects your app to AWS
Future<void> _configureAmplify() async {
  try {
    // 1. Create the Auth Plugin
    final auth = AmplifyAuthCognito();
    
    // 2. Add the Plugin to Amplify
    await Amplify.addPlugin(auth);

    // 3. Configure Amplify with your keys
    await Amplify.configure(amplifyconfig);
    
    print('✅ Successfully configured AWS Amplify');
  } on Exception catch (e) {
    print('❌ Error configuring Amplify: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PSMS Mobile',
      debugShowCheckedModeBanner: false, // Removes the "Debug" banner
      theme: ThemeData(
        // Matching your purple/blue theme
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A11CB)),
        useMaterial3: true,
      ),
      // Start directly at the Login Screen
      home: const LoginScreen(),
    );
  }
}