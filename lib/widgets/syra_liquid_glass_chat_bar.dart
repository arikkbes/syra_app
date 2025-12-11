// lib/widgets/syra_liquid_glass_chat_bar.dart

import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass_tokens.dart';
import '../theme/syra_tokens.dart';

/// Premium Liquid Glass Chat Input Bar
/// 
/// Figma-derived Apple-style iOS 26 Liquid Glass UI
/// Pixel-perfect symmetrical design with elevated interactions
/// 
/// Features:
/// - Full-width rounded liquid glass container (radius 55px from Figma)
/// - Layered fills: #000000 100%, #333333 45%, #999999 30%
/// - Multiple inner shadows for depth and bevel effect
/// - Gaussian blur (20-28 range)
/// - Material 3 icons (24×24) with theme token colors
/// - Elevated hover/tap animations (scale 0.92 → 1.0)
/// - SafeArea compatible
class SyraLiquidGlassChatBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isLoading;
  final bool isListening;
  final Map<String, dynamic>? replyingTo;
  final File? pendingImage;
  final String? pendingImageUrl;
  final VoidCallback onAttachmentTap;
  final VoidCallback onVoiceInputTap;
  final VoidCallback onSendMessage;
  final VoidCallback onCancelReply;
  final VoidCallback onClearImage;
  final VoidCallback onTextChanged;

  const SyraLiquidGlassChatBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isLoading,
    required this.isListening,
    this.replyingTo,
    this.pendingImage,
    this.pendingImageUrl,
    required this.onAttachmentTap,
    required this.onVoiceInputTap,
    required this.onSendMessage,
    required this.onCancelReply,
    required this.onClearImage,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasText = controller.text.trim().isNotEmpty;
    final bool isUploadingImage = pendingImage != null && pendingImageUrl == null;
    final bool hasPendingImage = pendingImage != null && pendingImageUrl != null;
    final bool canSend = (hasText || hasPendingImage) &&
        !isSending &&
        !isLoading &&
        !isUploadingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(
        SyraGlassTokens.chatBarPaddingHorizontal,
        8,
        SyraGlassTokens.chatBarPaddingHorizontal,
        max(8.0, MediaQuery.of(context).padding.bottom - 20),
      ),
      decoration: BoxDecoration(
        color: SyraColors.background,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null) _buildReplyPreview(),
          if (pendingImage != null) _buildImagePreview(),
          _buildLiquidGlassChatBar(canSend, hasText, hasPendingImage),
        ],
      ),
    );
  }

  /// Main liquid glass chat bar container
  /// Figma-derived with exact values
  Widget _buildLiquidGlassChatBar(bool canSend, bool hasText, bool hasPendingImage) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SyraGlassTokens.chatBarRadius),
        boxShadow: SyraGlassTokens.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SyraGlassTokens.chatBarRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: SyraGlassTokens.chatBarBlur,
            sigmaY: SyraGlassTokens.chatBarBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: SyraGlassTokens.chatBarGradient,
              borderRadius: BorderRadius.circular(SyraGlassTokens.chatBarRadius),
              border: Border.all(
                color: SyraGlassTokens.white20.withOpacity(0.3),
                width: 0.5,
              ),
              boxShadow: SyraGlassTokens.chatBarInnerShadows,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: SyraGlassTokens.chatBarIconSpacing,
              vertical: SyraGlassTokens.chatBarPaddingVertical,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Plus icon (attachment)
                _GlassIconButton(
                  icon: Icons.add_rounded,
                  onTap: onAttachmentTap,
                ),
                
                SizedBox(width: SyraGlassTokens.chatBarIconSpacing),

                // Text input field
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !isSending,
                    maxLines: 5,
                    minLines: 1,
                    onChanged: (_) => onTextChanged(),
                    style: TextStyle(
                      color: SyraTokens.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      hintText: "Message",
                      hintStyle: TextStyle(
                        color: SyraTokens.textMuted.withOpacity(0.6),
                        fontSize: 15,
                      ),
                    ),
                    onSubmitted: (_) => canSend ? onSendMessage() : null,
                  ),
                ),

                SizedBox(width: SyraGlassTokens.chatBarIconSpacing),

                // Mic icon (voice input)
                _GlassIconButton(
                  icon: isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  onTap: onVoiceInputTap,
                  color: isListening ? SyraTokens.accent : null,
                ),

                SizedBox(width: SyraGlassTokens.chatBarIconSpacing),

                // Send button
                _GlassSendButton(
                  canSend: canSend,
                  isLoading: isLoading,
                  onTap: canSend ? onSendMessage : null,
                ),
              ],
            ),
          ),
        ),
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
                  replyingTo!["text"] ?? "",
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
            onTap: onCancelReply,
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

  Widget _buildImagePreview() {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              pendingImage!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Fotoğraf",
                  style: TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (pendingImageUrl == null)
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SyraColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Yükleniyor...",
                        style: TextStyle(
                          color: SyraColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Hazır",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClearImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SyraColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: SyraColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glass Icon Button - Elevated tap animation
/// Material 3 icons (24×24) with theme token colors
class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SyraGlassTokens.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: SyraGlassTokens.scaleUp,
      end: SyraGlassTokens.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraGlassTokens.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: SyraGlassTokens.chatBarIconSize,
            color: widget.color ?? SyraTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Glass Send Button - Circular with fill animation
/// Animated based on message availability
class _GlassSendButton extends StatefulWidget {
  final bool canSend;
  final bool isLoading;
  final VoidCallback? onTap;

  const _GlassSendButton({
    required this.canSend,
    required this.isLoading,
    this.onTap,
  });

  @override
  State<_GlassSendButton> createState() => _GlassSendButtonState();
}

class _GlassSendButtonState extends State<_GlassSendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SyraGlassTokens.animationDuration,
    );
    _scaleAnimation = Tween<double>(
      begin: SyraGlassTokens.scaleUp,
      end: SyraGlassTokens.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraGlassTokens.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.canSend) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.canSend) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.canSend) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: SyraGlassTokens.animationDuration,
          curve: SyraGlassTokens.animationCurve,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.canSend
                ? SyraTokens.textPrimary
                : SyraTokens.textMuted.withOpacity(0.25),
            shape: BoxShape.circle,
            boxShadow: widget.canSend
                ? [
                    BoxShadow(
                      color: SyraTokens.textPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: widget.isLoading
              ? Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SyraColors.background,
                    ),
                  ),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  color: widget.canSend
                      ? SyraColors.background
                      : SyraColors.background.withOpacity(0.4),
                  size: 20,
                ),
        ),
      ),
    );
  }
}
