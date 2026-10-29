// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/constants/app_branding.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App renders LoginScreen smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the rebranded login screen header and button are present.
    expect(find.text(AppBranding.appName), findsOneWidget);
    expect(find.text(AppBranding.productDescription), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
