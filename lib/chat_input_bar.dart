// lib/screens/chat/chat_input_bar.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../theme/syra_glass.dart';
import '../../theme/syra_glass_tokens.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM CHAT INPUT BAR
/// ═══════════════════════════════════════════════════════════════
/// Floating glass input with:
/// - Attachment, text field, voice, send buttons
/// - Reply preview
/// - Image upload preview
/// - Premium animations and styling
/// ═══════════════════════════════════════════════════════════════

class ChatInputBar extends StatelessWidget {
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

  const ChatInputBar({
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
        SyraSpacing.md,
        SyraSpacing.sm,
        SyraSpacing.md,
        max(SyraSpacing.sm, MediaQuery.of(context).padding.bottom),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SyraColors.background.withValues(alpha: 0),
            SyraColors.background.withValues(alpha: 0.95),
            SyraColors.background,
          ],
          stops: [0, 0.3, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null) _buildReplyPreview(),
          if (pendingImage != null) _buildImagePreview(),
          
          // Main input bar with glass effect
          ClipRRect(
            borderRadius: BorderRadius.circular(SyraRadius.full),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: SyraGlassSpec.blurSubtle,
                sigmaY: SyraGlassSpec.blurSubtle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          SyraGlassSpec.whiteOverlay,
          SyraGlassSpec.blackOverlay,
        ],
      ),
                  borderRadius: BorderRadius.circular(SyraRadius.full),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.5,
                  ),
                  boxShadow: SyraGlass.glassShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Attachment button
                    _buildIconButton(
                      icon: Icons.add_circle_outline,
                      onTap: onAttachmentTap,
                      color: SyraColors.iconMuted,
                    ),

                    // Text field
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: SyraSpacing.sm,
                        ),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: !isSending,
                          maxLines: 5,
                          minLines: 1,
                          onChanged: (_) => onTextChanged(),
                          style: SyraTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: SyraSpacing.xs,
                              vertical: 0,
                            ),
                            border: InputBorder.none,
                            hintText: "Message",
                            hintStyle: SyraTextStyles.bodyMedium.copyWith(
                              color: SyraColors.textHint,
                            ),
                          ),
                          onSubmitted: (_) => canSend ? onSendMessage() : null,
                        ),
                      ),
                    ),

                    // Voice button
                    _buildIconButton(
                      icon: isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      onTap: onVoiceInputTap,
                      color: isListening
                          ? SyraColors.accent
                          : SyraColors.iconMuted,
                      isActive: isListening,
                    ),

                    SizedBox(width: SyraSpacing.xs),

                    // Send button (pill shape when active)
                    _buildSendButton(
                      canSend: canSend,
                      isSending: isSending,
                      onSend: onSendMessage,
                    ),

                    SizedBox(width: SyraSpacing.xs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ICON BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    bool isActive = false,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: EdgeInsets.only(left: SyraSpacing.xs),
        child: Center(
          child: AnimatedSwitcher(
            duration: SyraAnimation.fast,
            child: Icon(
              icon,
              key: ValueKey(icon),
              color: color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSendButton({
    required bool canSend,
    required bool isSending,
    required VoidCallback onSend,
  }) {
    return _TapScale(
      onTap: canSend ? onSend : null,
      child: AnimatedContainer(
        duration: SyraAnimation.fast,
        curve: SyraAnimation.spring,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: canSend
              ? SyraColors.accentGradient
              : null,
          color: canSend ? null : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: SyraColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isSending
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  color: canSend ? Colors.white : SyraColors.iconMuted,
                  size: 20,
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REPLY PREVIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReplyPreview() {
    final replyText = replyingTo?["text"] ?? "";
    final isUserReply = replyingTo?["sender"] == "user";

    return Container(
      margin: EdgeInsets.only(bottom: SyraSpacing.sm),
      padding: EdgeInsets.all(SyraSpacing.sm),
      decoration: BoxDecoration(
        color: SyraColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(SyraRadius.md),
        border: Border.all(
          color: SyraColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: SyraColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: SyraSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUserReply ? "You" : "SYRA",
                  style: SyraTextStyles.caption.copyWith(
                    color: SyraColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  replyText,
                  style: SyraTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancelReply,
            icon: Icon(
              Icons.close,
              size: 18,
              color: SyraColors.iconMuted,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE PREVIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildImagePreview() {
    return Container(
      margin: EdgeInsets.only(bottom: SyraSpacing.sm),
      height: 100,
      decoration: BoxDecoration(
        color: SyraColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(SyraRadius.md),
        border: Border.all(
          color: SyraColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SyraRadius.md),
            child: pendingImage != null
                ? Image.file(
                    pendingImage!,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: SyraColors.surface,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: SyraColors.iconMuted,
                        size: 32,
                      ),
                    ),
                  ),
          ),
          if (pendingImageUrl == null)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(SyraRadius.md),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(SyraColors.accent),
                ),
              ),
            ),
          Positioned(
            top: SyraSpacing.xs,
            right: SyraSpacing.xs,
            child: _TapScale(
              onTap: onClearImage,
              child: Container(
                padding: EdgeInsets.all(SyraSpacing.xs),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// TAP SCALE ANIMATION
/// ═══════════════════════════════════════════════════════════════

class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SyraAnimation.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraAnimation.emphasize,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
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
        child: widget.child,
      ),
    );
  }
}
