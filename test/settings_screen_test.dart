import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/theme/app_theme.dart';
import 'package:mobile/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default Light mode', () {
      final controller = ThemeController();
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, false);
    });

    test('setThemeMode changes mode and persists to SharedPreferences',
        () async {
      final controller = ThemeController();
      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.themePrefKey), 'dark');

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, false);
      expect(prefs.getString(ThemeController.themePrefKey), 'light');
    });

    test('toggleTheme alternates between light and dark', () async {
      final controller = ThemeController();
      expect(controller.isDarkMode, false);

      controller.toggleTheme();
      expect(controller.isDarkMode, true);

      controller.toggleTheme();
      expect(controller.isDarkMode, false);
    });

    test('loadTheme restores persisted dark mode', () async {
      SharedPreferences.setMockInitialValues({
        ThemeController.themePrefKey: 'dark',
      });

      final controller = ThemeController();
      await controller.loadTheme();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, true);
    });
  });

  group('SettingsScreen Widget Tests', () {
    late ThemeController testThemeController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testThemeController = ThemeController();
    });

    Widget createTestSettingsApp({required bool isAdmin}) {
      return ThemeProvider(
        notifier: testThemeController,
        child: ListenableBuilder(
          listenable: testThemeController,
          builder: (context, _) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: testThemeController.themeMode,
              home: SettingsScreen(isAdmin: isAdmin),
            );
          },
        ),
      );
    }

    testWidgets('Renders all standard sections for regular user',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestSettingsApp(isAdmin: false));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Settings'), findsNWidgets(2)); // AppBar + Header
      expect(find.text('Personal Settings'), findsOneWidget);
      expect(
        find.text(
          'Manage your appearance preferences, account details, and security credentials.',
        ),
        findsOneWidget,
      );

      // Appearance Card
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Light Mode Active'), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      // Account Card
      expect(find.text('My Account'), findsOneWidget);
      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('APP_USER'), findsOneWidget);

      // Password Card
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);

      // Session Card
      expect(find.text('Session & Sign Out'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Admin Tools MUST NOT appear for regular user
      expect(find.text('Administrator Tools'), findsNothing);
      expect(find.text('Open User Management'), findsNothing);
    });

    testWidgets('Tapping Dark Mode updates theme across the app immediately',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestSettingsApp(isAdmin: false));
      await tester.pumpAndSettle();

      expect(testThemeController.isDarkMode, false);
      expect(find.text('Light Mode Active'), findsOneWidget);

      // Tap Dark Mode option
      final darkModeOption = find.text('Dark Mode');
      await tester.tap(darkModeOption);
      await tester.pumpAndSettle();

      expect(testThemeController.isDarkMode, true);
      expect(find.text('Dark Mode Active'), findsOneWidget);

      // Verify persisted to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeController.themePrefKey), 'dark');
    });

    testWidgets('Renders Administrator Tools only for APP_ADMIN',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestSettingsApp(isAdmin: true));
      await tester.pumpAndSettle();

      // Admin header badge
      expect(find.text('Administrator'), findsOneWidget);
      expect(find.text('APP_ADMIN'), findsOneWidget);

      // Admin Tools section
      expect(find.text('Administrator Tools'), findsOneWidget);
      expect(find.text('APP_ADMIN Authorized'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Open User Management'), findsOneWidget);
      expect(find.text('Backend Health Diagnostic'), findsOneWidget);
      expect(find.text('Run Health Check'), findsOneWidget);
    });

    testWidgets('Validates password fields on submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestSettingsApp(isAdmin: false));
      await tester.pumpAndSettle();

      final updateButton = find.text('Update Password');

      // 1. Empty submission
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();
      expect(find.text('Please enter a new password.'), findsOneWidget);

      // 2. Short password (< 6 chars)
      final newPasswordField = find.widgetWithText(TextField, 'New Password');
      await tester.enterText(newPasswordField, '12345');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();
      expect(
        find.text('Password must be at least 6 characters long.'),
        findsOneWidget,
      );

      // 3. Mismatching confirm password
      final confirmPasswordField =
          find.widgetWithText(TextField, 'Confirm New Password');
      await tester.enterText(newPasswordField, 'secret123');
      await tester.enterText(confirmPasswordField, 'different123');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();
      expect(
        find.text('Passwords do not match. Please re-enter.'),
        findsOneWidget,
      );
    });
  });
}
