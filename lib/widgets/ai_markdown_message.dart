import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// Inline syntax that converts HTML `<br>`, `<br/>`, and `<br />` tags
/// into Markdown `br` elements for clean line breaks across text and tables.
class HtmlBreakSyntax extends md.InlineSyntax {
  HtmlBreakSyntax() : super(r'<br\s*/?>', caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty('br'));
    return true;
  }
}

/// Normalizes raw AI markdown responses safely before rendering.
///
/// - Preserves 100% of text inside fenced code blocks (` ```...``` `).
/// - Normalizes line endings (`\r\n` and `\r` to `\n`).
/// - Converts escaped `\n` sequences if unescaped by the backend.
/// - Strips potentially unsafe script / embed tags.
/// - Preserves valid Markdown tables, headings, links, emphasis, and emojis.
String normalizeAiMarkdown(String raw) {
  if (raw.isEmpty) return raw;

  // Split into fenced code blocks and regular markdown segments.
  final RegExp codeBlockRegex = RegExp(
    r'(```[\s\S]*?```|~~~[\s\S]*?~~~)',
    multiLine: true,
  );

  final List<String> segments = [];
  int lastEnd = 0;

  for (final match in codeBlockRegex.allMatches(raw)) {
    if (match.start > lastEnd) {
      segments.add(_normalizeTextSegment(raw.substring(lastEnd, match.start)));
    }
    // Fenced code block: preserve untouched
    segments.add(match.group(0)!);
    lastEnd = match.end;
  }

  if (lastEnd < raw.length) {
    segments.add(_normalizeTextSegment(raw.substring(lastEnd)));
  }

  return segments.join();
}

String _normalizeTextSegment(String text) {
  var result = text;

  // 1. Normalize line endings
  result = result.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  // 2. Safely expand escaped newlines if the entire text lacks real newlines
  if (!result.contains('\n') && result.contains(r'\n')) {
    result = result.replaceAll(r'\n', '\n');
  }

  // 3. Strip dangerous executable HTML tags
  result = result.replaceAll(
    RegExp(
      r'<(script|iframe|style|object|embed)[\s\S]*?>[\s\S]*?<\/\1>',
      caseSensitive: false,
    ),
    '',
  );
  result = result.replaceAll(
    RegExp(
      r'<(script|iframe|style|object|embed)[^>]*\/?>',
      caseSensitive: false,
    ),
    '',
  );

  return result;
}

/// A reusable, ChatGPT-style rich Markdown message renderer for AI responses.
///
/// Features:
/// - Full Markdown formatting (Bold, Italic, Headings, Lists, Blockquotes, Links, Code)
/// - Horizontally scrollable Markdown tables with subtle borders & styled headers
/// - Safe handling of `<br>` tags and escaped newlines
/// - Non-overflowing horizontal scroll for wide tables and code blocks
/// - PSMS purple branding accent
/// - Text selectable and copyable
/// - Dynamic Light and Dark Mode theme-aware styling
class AiMarkdownMessage extends StatelessWidget {
  final String content;
  final bool selectable;
  final void Function(String url)? onLinkTap;

  const AiMarkdownMessage({
    super.key,
    required this.content,
    this.selectable = true,
    this.onLinkTap,
  });

  static const Color primaryColor = Color(0xFF6A11CB);

  Future<void> _defaultLaunchUrl(String url) async {
    try {
      var trimmed = url.trim();
      if (trimmed.isEmpty) return;
      if (!trimmed.startsWith('http://') &&
          !trimmed.startsWith('https://') &&
          !trimmed.startsWith('mailto:')) {
        trimmed = 'https://$trimmed';
      }
      final uri = Uri.parse(trimmed);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final normalized = normalizeAiMarkdown(content);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isDark ? const Color(0xFFF8FAFC) : Colors.black87;
    final Color headerColor = isDark ? Colors.white : Colors.black87;
    final Color mutedColor = isDark ? const Color(0xFF94A3B8) : Colors.black54;
    final Color linkColor = isDark ? const Color(0xFFA5B4FC) : primaryColor;
    final Color borderColor = isDark
        ? const Color(0xFF334155)
        : Colors.grey.shade300;

    // Custom extension set: GitHub Flavored Markdown + custom HTML break syntax
    final extensionSet = md.ExtensionSet(
      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      [HtmlBreakSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
    );

    // Professional, theme-aware stylesheet tailored for mobile chat bubbles
    final styleSheet = MarkdownStyleSheet(
      // Paragraph
      p: TextStyle(
        fontSize: 15.0,
        height: 1.45,
        color: textColor,
        fontWeight: FontWeight.w400,
      ),
      pPadding: const EdgeInsets.only(bottom: 8.0),

      // Headings (compact, proportional for chat)
      h1: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        color: headerColor,
        height: 1.3,
      ),
      h1Padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      h2: TextStyle(
        fontSize: 17.0,
        fontWeight: FontWeight.w700,
        color: headerColor,
        height: 1.3,
      ),
      h2Padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
      h3: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: headerColor,
        height: 1.3,
      ),
      h3Padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
      h4: TextStyle(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        color: headerColor,
        height: 1.3,
      ),
      h4Padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
      h5: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: headerColor,
      ),
      h6: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),

      // Text Formatting
      strong: TextStyle(fontWeight: FontWeight.w700, color: headerColor),
      em: TextStyle(fontStyle: FontStyle.italic, color: textColor),

      // Links
      a: TextStyle(
        color: linkColor,
        decoration: TextDecoration.underline,
        fontWeight: FontWeight.w500,
      ),

      // Lists
      listBullet: TextStyle(
        color: linkColor,
        fontSize: 15.0,
        fontWeight: FontWeight.bold,
      ),
      listIndent: 20.0,

      // Blockquote
      blockquote: TextStyle(
        fontSize: 14.5,
        fontStyle: FontStyle.italic,
        color: isDark ? const Color(0xFFE2E8F0) : Colors.black87,
        height: 1.4,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF312E81).withValues(alpha: 0.3)
            : primaryColor.withValues(alpha: 0.05),
        border: Border(left: BorderSide(color: linkColor, width: 3.5)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),

      // Inline Code
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13.5,
        color: linkColor,
        backgroundColor: isDark
            ? const Color(0xFF334155)
            : Colors.black.withValues(alpha: 0.06),
        fontWeight: FontWeight.w600,
      ),

      // Fenced Code Blocks
      codeblockDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      codeblockPadding: const EdgeInsets.all(12.0),

      // Horizontal Divider
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
      ),

      // Tables (IntrinsicColumnWidth enables horizontal scrolling without clipping!)
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableHead: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        color: headerColor,
      ),
      tableBody: TextStyle(fontSize: 13.5, color: textColor, height: 1.35),
      tableHeadAlign: TextAlign.left,
      tableHeadCellsPadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 10.0,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),
      tableHeadCellsDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
      ),
      tableCellsDecoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.transparent,
      ),
      tableBorder: TableBorder.all(
        color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
        width: 1.0,
        borderRadius: BorderRadius.circular(4),
      ),
      tablePadding: const EdgeInsets.symmetric(vertical: 8.0),
    );

    return MarkdownBody(
      data: normalized,
      selectable: selectable,
      extensionSet: extensionSet,
      styleSheet: styleSheet,
      onTapLink: (text, href, title) {
        if (onLinkTap != null && href != null) {
          onLinkTap!(href);
        } else if (href != null) {
          _defaultLaunchUrl(href);
        }
      },
    );
  }
}
