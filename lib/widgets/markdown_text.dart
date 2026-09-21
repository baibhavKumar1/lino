import 'package:flutter/material.dart';

/// Senior developer grade inline Markdown renderer for AI chat and recipe cards.
/// Parses **bold**, *italic*, ***bold-italic***, and `code` spans into rich Flutter [TextSpan]s
/// so that asterisks are never shown raw, rendering styled bold text seamlessly.
/// Strictly adheres to the project UI constraint: "DO NOT BRING DOT IN UI".
class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? boldStyle;
  final TextStyle? italicStyle;
  final TextStyle? codeStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const MarkdownText(
    this.text, {
    super.key,
    this.style,
    this.boldStyle,
    this.italicStyle,
    this.codeStyle,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    final effectiveStyle = defaultTextStyle.style.merge(style);

    // PREVIOUS LOGIC - COMMENTED OUT: passed raw text directly to inline parser
    // final spans = parseMarkdownSpans(
    //   text,
    //   baseStyle: effectiveStyle,
    //   boldStyle: boldStyle,
    //   italicStyle: italicStyle,
    //   codeStyle: codeStyle,
    // );

    // New: Preprocess block-level markdown (headings, lists, code fences)
    // before inline span parsing so raw # - * 1. syntax never leaks into UI
    final preprocessed = _preprocessBlockMarkdown(text);
    final spans = parseMarkdownSpans(
      preprocessed,
      baseStyle: effectiveStyle,
      boldStyle: boldStyle,
      italicStyle: italicStyle,
      codeStyle: codeStyle,
    );

    return Text.rich(
      TextSpan(children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Pre-processes block-level markdown into clean inline-styled text.
  /// Strips heading markers (converts to bold), list prefixes, numbered
  /// list markers, and code fence delimiters so inline parser can handle the rest.
  static String _preprocessBlockMarkdown(String input) {
    if (!input.contains('\n') &&
        !input.startsWith('#') &&
        !input.startsWith('- ') &&
        !input.startsWith('* ') &&
        !RegExp(r'^\d+\.\s').hasMatch(input)) {
      return input;
    }

    final lines = input.split('\n');
    final processed = <String>[];
    bool inCodeBlock = false;

    for (final line in lines) {
      final trimmed = line.trim();

      // Handle code fences — strip the ``` delimiter lines entirely
      if (trimmed.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      // Inside code block — keep content as-is (no markdown processing)
      if (inCodeBlock) {
        processed.add(line);
        continue;
      }

      // Strip heading markers and wrap in bold so inline parser renders them bold
      if (trimmed.startsWith('### ')) {
        processed.add('**${trimmed.substring(4)}**');
      } else if (trimmed.startsWith('## ')) {
        processed.add('**${trimmed.substring(3)}**');
      } else if (trimmed.startsWith('# ')) {
        processed.add('**${trimmed.substring(2)}**');
      }
      // Strip unordered list markers (- or * at line start)
      else if (trimmed.startsWith('- ')) {
        processed.add('  ${trimmed.substring(2)}');
      } else if (trimmed.startsWith('* ') && !trimmed.startsWith('**')) {
        processed.add('  ${trimmed.substring(2)}');
      }
      // Strip numbered list markers (1. , 2. , 10. , etc.)
      else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        processed.add('  ${trimmed.replaceFirst(RegExp(r'^\d+\.\s'), '')}');
      }
      // Strip blockquote markers
      else if (trimmed.startsWith('> ')) {
        processed.add(trimmed.substring(2));
      }
      else {
        processed.add(line);
      }
    }

    return processed.join('\n');
  }

  /// Parses text with inline Markdown tokens into a list of [InlineSpan]s
  static List<InlineSpan> parseMarkdownSpans(
    String input, {
    required TextStyle baseStyle,
    TextStyle? boldStyle,
    TextStyle? italicStyle,
    TextStyle? codeStyle,
  }) {
    if (input.isEmpty) return const [];

    final effectiveBold = boldStyle ??
        baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: baseStyle.color,
        );
    final effectiveItalic = italicStyle ??
        baseStyle.copyWith(
          fontStyle: FontStyle.italic,
        );
    final effectiveBoldItalic = effectiveBold.copyWith(
      fontStyle: FontStyle.italic,
    );
    final effectiveCode = codeStyle ??
        baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: const Color(0x180F172A),
          fontSize: (baseStyle.fontSize ?? 13) * 0.92,
        );

    final List<InlineSpan> spans = [];

    // Markdown token regex matching:
    // 1. ***bold italic***
    // 2. **bold**
    // 3. ___bold italic___
    // 4. __bold__
    // 5. *italic* (bounded by non-space)
    // 6. _italic_ (bounded by non-space)
    // 7. `code`
    final RegExp tokenRegex = RegExp(
      r'(\*\*\*([^\*\n]+?)\*\*\*|'
      r'\*\*([^\*\n]+?)\*\*|'
      r'___([^_\n]+?)___|'
      r'__([^_\n]+?)__|'
      r'(?<!\*)\*(?!\s)([^\*\n]+?)(?<!\s)\*(?!\*)|'
      r'(?<!_)_(?!\s)([^_\n]+?)(?<!\s)_(?!_)|'
      r'`([^`\n]+?)`)',
    );

    int currentIndex = 0;

    for (final Match match in tokenRegex.allMatches(input)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: input.substring(currentIndex, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(2) != null) {
        // ***bold italic***
        spans.add(TextSpan(
          text: match.group(2),
          style: effectiveBoldItalic,
        ));
      } else if (match.group(3) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(3),
          style: effectiveBold,
        ));
      } else if (match.group(4) != null) {
        // ___bold italic___
        spans.add(TextSpan(
          text: match.group(4),
          style: effectiveBoldItalic,
        ));
      } else if (match.group(5) != null) {
        // __bold__
        spans.add(TextSpan(
          text: match.group(5),
          style: effectiveBold,
        ));
      } else if (match.group(6) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(6),
          style: effectiveItalic,
        ));
      } else if (match.group(7) != null) {
        // _italic_
        spans.add(TextSpan(
          text: match.group(7),
          style: effectiveItalic,
        ));
      } else if (match.group(8) != null) {
        // `code`
        spans.add(TextSpan(
          text: match.group(8),
          style: effectiveCode,
        ));
      }

      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      spans.add(TextSpan(
        text: input.substring(currentIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
