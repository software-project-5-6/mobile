import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/ai_markdown_message.dart';

void main() {
  group('AiMarkdownMessage and Normalizer Tests', () {
    test('normalizeAiMarkdown preserves fenced code blocks untouched', () {
      const input = '''
Intro with `<br>` and `**emphasis**`.
```dart
// Code block: <br> and **not bold** must be preserved verbatim!
void main() {
  print("Line 1\\nLine 2");
}
```
Outro with <br> tag.
''';

      final result = normalizeAiMarkdown(input);

      expect(result.contains('// Code block: <br> and **not bold** must be preserved verbatim!'), isTrue);
      expect(result.contains('print("Line 1\\nLine 2");'), isTrue);
    });

    test('normalizeAiMarkdown cleans dangerous script tags outside code', () {
      const input = 'Hello <script>alert("hack")</script>World!';
      final result = normalizeAiMarkdown(input);
      expect(result.contains('<script>'), isFalse);
      expect(result.contains('World!'), isTrue);
    });

    testWidgets('Renders bold, headings, lists, emojis, and links', (tester) async {
      String? tappedUrl;

      const markdown = '''
# Project Architecture
**Important Deadline**: Friday, Nov 15th 🚀

Key Objectives:
- First milestone with *italic* note
- Second milestone with `inline_config()`
1. Numbered step one
2. Numbered step two

> A critical architectural quote for the team.

Visit [Documentation](https://psms.majstro.com) for details.
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiMarkdownMessage(
                content: markdown,
                onLinkTap: (url) => tappedUrl = url,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Project Architecture'), findsOneWidget);
      expect(find.textContaining('Important Deadline'), findsOneWidget);
      expect(find.textContaining('Friday, Nov 15th 🚀'), findsOneWidget);
      expect(find.textContaining('First milestone'), findsOneWidget);
      expect(find.textContaining('Numbered step one'), findsOneWidget);
      expect(find.textContaining('Documentation'), findsOneWidget);

      // Verify link tap
      await tester.tap(find.textContaining('Documentation'));
      await tester.pumpAndSettle();
      expect(tappedUrl, equals('https://psms.majstro.com'));
    });

    testWidgets('Renders three-column and very long Markdown tables with horizontal scroll', (tester) async {
      const tableMarkdown = '''
### Component Matrix

| Component | Responsibility | Tech Stack | Status | Lead Contact | Extra Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Mobile App | Cross-platform client for iOS and Android | Flutter 3.35, Dart | Active | Charuka | Fully responsive UI with rich markdown |
| Backend Core | REST APIs, Authentication & Database access | Spring Boot, Render | Stable | Backend Team | Secure PostgreSQL with JWT |
| AI Pipeline | Retrieval-Augmented Generation & Summaries | Python, LangChain | Deployed | AI Specialist | Gmail and Zoom integration |
| Web Portal | Management dashboard for administration | React, Vite | Active | Web Team | Modern purple-themed UI |

Final paragraph after the table.
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340, // Constrained mobile screen width
                child: SingleChildScrollView(
                  child: AiMarkdownMessage(
                    content: tableMarkdown,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Component Matrix'), findsOneWidget);
      expect(find.text('Mobile App'), findsOneWidget);
      expect(find.text('Backend Core'), findsOneWidget);
      expect(find.textContaining('Final paragraph'), findsOneWidget);

      // Verify horizontal scrollview exists for the table
      final scrollFinder = find.byType(SingleChildScrollView);
      // Main scroll view + table scroll view
      expect(scrollFinder, findsNWidgets(2));
    });

    testWidgets('Renders <br> tags properly without breaking tables or paragraphs', (tester) async {
      const brMarkdown = '''
Line A<br>Line B<br/>Line C<br />Line D

| Item | Notes |
| --- | --- |
| Task 1 | First part<br>Second part |
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiMarkdownMessage(
                content: brMarkdown,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
      expect(find.textContaining('Line A'), findsOneWidget);
      expect(find.textContaining('First part'), findsOneWidget);
    });

    testWidgets('Renders long AI responses exceeding screen height without overflow', (tester) async {
      final longMarkdown = StringBuffer('# Extensive Project Summary\n\n');
      for (int i = 1; i <= 30; i++) {
        longMarkdown.writeln('### Section $i');
        longMarkdown.writeln('This is detailed paragraph content for milestone $i of the project.');
        longMarkdown.writeln('- Action item $i.A: Review requirements');
        longMarkdown.writeln('- Action item $i.B: Implement tests');
        longMarkdown.writeln('');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ListView(
                children: [
                  AiMarkdownMessage(
                    content: longMarkdown.toString(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Extensive Project Summary'), findsOneWidget);
      expect(find.text('Section 1'), findsOneWidget);
    });

    testWidgets('Handles empty or blank content gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AiMarkdownMessage(content: '   '),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}

