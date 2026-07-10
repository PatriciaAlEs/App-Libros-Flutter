import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../core/design_system/design_system.dart';

class CoachMarkdown extends StatelessWidget {
  const CoachMarkdown({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = MarkdownStyleSheet.fromTheme(theme);
    return MarkdownBody(
      data: data,
      selectable: true,
      softLineBreak: true,
      styleSheet: base.copyWith(
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        h1: theme.textTheme.headlineSmall,
        h2: theme.textTheme.titleLarge,
        h3: theme.textTheme.titleMedium,
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.all(AppSpacing.md),
        code: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
      builders: {'pre': _CodeBlockBuilder()},
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    dynamic element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent as String;
    String? language;
    final children = element.children as List<dynamic>?;
    if (children != null && children.isNotEmpty) {
      final className = children.first.attributes['class'] as String?;
      if (className != null && className.startsWith('language-')) {
        language = className.substring('language-'.length);
      }
    }
    return _CodeBlock(code: code, language: language);
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({required this.code, this.language});

  final String code;
  final String? language;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.language ?? 'Código',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Copiar bloque de código',
                  child: TextButton.icon(
                    onPressed: _copy,
                    icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                    label: Text(_copied ? 'Copiado' : 'Copiar'),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: SelectableText(
              widget.code,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
