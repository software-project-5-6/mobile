import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants/app_branding.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase Configuration
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ndetluoghrbtzupuawln.supabase.co',
  );

  const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (supabaseKey.isEmpty) {
    throw StateError('SUPABASE_PUBLISHABLE_KEY is missing');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  debugPrint('Supabase initialized successfully');

  // Initialize ThemeController and restore persisted preference
  final themeController = ThemeController();
  await themeController.loadTheme();

  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  final ThemeController? themeController;

  const MyApp({super.key, this.themeController});

  @override
  Widget build(BuildContext context) {
    final controller = themeController ?? ThemeController();

    return ThemeProvider(
      notifier: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return MaterialApp(
            title: AppBranding.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.themeMode,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
