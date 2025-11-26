import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA GLASS INPUT BAR — Premium Glassmorphism
/// ═══════════════════════════════════════════════════════════════
/// - Background: rgba(255,255,255,0.06)
/// - Blur: 22-26px
/// - Border: 1px subtle stroke (#2A2A2A)
/// - Soft inner shadow on top
/// - Icons glow slightly when focused
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
    this.hintText = "Send a message...",
  });

  @override
  State<GlassInputBar> createState() => _GlassInputBarState();
}

class _GlassInputBarState extends State<GlassInputBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

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
    _sendButtonController.dispose();
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            // rgba(255,255,255,0.06)
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            // 1px subtle stroke
            border: Border.all(
              color: const Color(0xFF2A2A2A),
              width: 1,
            ),
            // Soft inner shadow simulation
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: -2,
              ),
              // Subtle glow when focused
              if (_isFocused)
                BoxShadow(
                  color: SyraColors.neonCyan.withValues(alpha: 0.05),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Profile icon
              _buildIcon(
                Icons.person_outline_rounded,
                glowWhenFocused: _isFocused,
              ),

              // Text input
              Expanded(
                child: Focus(
                  onFocusChange: (focused) {
                    setState(() => _isFocused = focused);
                  },
                  child: TextField(
                    controller: widget.controller,
                    enabled: !widget.isLoading,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      hintText: widget.replyingToText != null
                          ? "Yanıt yaz..."
                          : widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.28),
                        fontSize: 15,
                      ),
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
              ),

              // Search icon
              _buildIcon(
                Icons.search_rounded,
                glowWhenFocused: _isFocused,
              ),

              // Favorite icon
              _buildIcon(
                Icons.star_outline_rounded,
                glowWhenFocused: _isFocused,
              ),

              const SizedBox(width: 4),

              // Send button
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, {bool glowWhenFocused = false}) {
    return Container(
      width: 34,
      height: 34,
      decoration: glowWhenFocused
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SyraColors.neonCyan.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: Icon(
        icon,
        size: 20,
        color: Colors.white.withValues(alpha: glowWhenFocused ? 0.5 : 0.35),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTapDown: (_) => _sendButtonController.forward(),
      onTapUp: (_) {
        _sendButtonController.reverse();
        _handleSend();
      },
      onTapCancel: () => _sendButtonController.reverse(),
      child: AnimatedBuilder(
        animation: _sendButtonScale,
        builder: (context, _) {
          return Transform.scale(
            scale: _sendButtonScale.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _hasText && !widget.isLoading
                    ? const LinearGradient(
                        colors: [SyraColors.neonPink, SyraColors.neonCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.06),
                        ],
                      ),
                boxShadow: _hasText && !widget.isLoading
                    ? [
                        BoxShadow(
                          color: SyraColors.neonPink.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: SyraColors.neonCyan.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: widget.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: _hasText
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SyraColors.neonCyan, SyraColors.neonPink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
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
                    color: SyraColors.neonCyan.withValues(alpha: 0.8),
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
                    color: Colors.white.withValues(alpha: 0.6),
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
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
