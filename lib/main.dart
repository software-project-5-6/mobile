import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart'; // Ensure this file exists in lib/
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // Make sure this is imported

void main() async {
  // 1. Ensure Flutter bindings are initialized before doing async native calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Boot up the Firebase Core engine
  try {
    await Firebase.initializeApp();
    print('✅ Successfully initialized Firebase');
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
  }

  // 3. Boot up AWS Amplify
  await _configureAmplify();
  
  // 4. Launch the App
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