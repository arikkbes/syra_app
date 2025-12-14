import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// GLASS INPUT BAR — Legacy Compatibility
/// ═══════════════════════════════════════════════════════════════
/// The new chat screen uses an integrated input bar.
/// ═══════════════════════════════════════════════════════════════

class GlassInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final String? replyingToText;
  final VoidCallback? onCancelReply;
  final String hintText;

  const GlassInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.replyingToText,
    this.onCancelReply,
    this.hintText = "Message",
  });

  @override
  State<GlassInputBar> createState() => _GlassInputBarState();
}

class _GlassInputBarState extends State<GlassInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _handleSend() {
    if (widget.isLoading || !_hasText) return;
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: SyraColors.background,
          border: Border(
            top: BorderSide(
              color: SyraColors.divider,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingToText != null) _buildReplyPreview(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: SyraColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 44,
            height: 44,
            margin: EdgeInsets.only(left: 4, bottom: 4),
            child: const Icon(
              Icons.add_rounded,
              color: SyraColors.textMuted,
              size: 24,
            ),
          ),

          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: !widget.isLoading,
              maxLines: 5,
              minLines: 1,
              style: const TextStyle(
                color: SyraColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                border: InputBorder.none,
                hintText: widget.replyingToText != null
                    ? "Yanıt yaz..."
                    : widget.hintText,
                hintStyle: TextStyle(
                  color: SyraColors.textHint,
                  fontSize: 15,
                ),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),

          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.only(right: 6, bottom: 6),
              decoration: BoxDecoration(
                color: _hasText && !widget.isLoading
                    ? SyraColors.textPrimary
                    : SyraColors.textMuted.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: widget.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SyraColors.background,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
                      color: SyraColors.background,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: SyraColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Yanıtlanıyor",
                  style: TextStyle(
                    color: SyraColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyingToText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SyraColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onCancelReply,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: SyraColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
