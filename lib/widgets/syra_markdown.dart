// lib/widgets/syra_markdown.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA MARKDOWN WIDGET - Premium markdown rendering with copy
/// ═══════════════════════════════════════════════════════════════

class SyraMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;

  const SyraMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: selectable,
      builders: {
        'code': SyraCodeElementBuilder(),
      },
      styleSheet: MarkdownStyleSheet(
        // Paragraph text (main body)
        p: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.textPrimary,
          fontSize: 16,
          height: 1.42,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
        // Bold text
        strong: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15,
        ),
        // Italic text
        em: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.textPrimary,
          fontSize: 16,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.15,
        ),
        // Inline code (chip style)
        code: SyraTextStyles.bodyMedium.copyWith(
          fontFamily: 'monospace',
          fontSize: 13,
          color: SyraColors.accent,
          backgroundColor: SyraColors.surface.withValues(alpha: 0.4),
          letterSpacing: 0,
        ),
        // Code block decoration
        codeblockDecoration: BoxDecoration(
          color: SyraColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(SyraRadius.md),
          border: Border.all(
            color: SyraColors.border.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        // Code block padding
        codeblockPadding: EdgeInsets.all(SyraSpacing.md),
        // Lists - tighter spacing
        listBullet: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.accent.withValues(alpha: 0.8),
          fontSize: 16,
        ),
        listIndent: 20,
        // Links - subtle accent
        a: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.accent.withValues(alpha: 0.9),
          fontSize: 16,
          decoration: TextDecoration.underline,
          decorationColor: SyraColors.accent.withValues(alpha: 0.5),
          letterSpacing: 0.15,
        ),
        // Headings
        h1: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h2: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h3: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        // Blockquote
        blockquote: SyraTextStyles.bodyMedium.copyWith(
          color: SyraColors.textSecondary,
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: SyraColors.accent.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
        ),
        blockquotePadding: EdgeInsets.symmetric(
          horizontal: SyraSpacing.md,
          vertical: SyraSpacing.xs,
        ),
      ),
    );
  }
}

/// Custom code block builder with copy button
class SyraCodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String code = element.textContent;

    // Inline code (no copy button)
    if (!code.contains('\n')) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: SyraColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: SyraColors.accent,
              letterSpacing: 0,
            ),
          ),
        ),
      );
    }

    // Code block with copy button
    return SyraCodeBlock(code: code);
  }
}

/// Premium code block card with copy button
class SyraCodeBlock extends StatefulWidget {
  final String code;

  const SyraCodeBlock({super.key, required this.code});

  @override
  State<SyraCodeBlock> createState() => _SyraCodeBlockState();
}

class _SyraCodeBlockState extends State<SyraCodeBlock> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);

    // Reset after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: SyraSpacing.sm),
      decoration: BoxDecoration(
        color: SyraColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(SyraRadius.md),
        border: Border.all(
          color: SyraColors.border.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Code content with horizontal scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(SyraSpacing.md),
            child: SelectableText(
              widget.code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: SyraColors.textPrimary.withValues(alpha: 0.9),
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),

          // Copy button (top-right)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _copyToClipboard,
                borderRadius: BorderRadius.circular(SyraRadius.sm),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SyraColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(SyraRadius.sm),
                    border: Border.all(
                      color: _copied
                          ? SyraColors.accent.withValues(alpha: 0.4)
                          : SyraColors.border.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy_rounded,
                        size: 14,
                        color: _copied
                            ? SyraColors.accent
                            : SyraColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: SyraTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: _copied
                              ? SyraColors.accent
                              : SyraColors.textSecondary,
                          fontWeight: _copied ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
