import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';

/// ChatGPT-style input bar for ChatScreen
/// 
/// Features:
/// - Text input with auto-resize (1-5 lines)
/// - Attachment button (left)
/// - Voice input button
/// - Send button (animated based on state)
/// - Reply preview
/// - Image upload preview
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

    final bool isFocused = focusNode.hasFocus;
    final bool isActive = isFocused || hasText || hasPendingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        max(8.0, MediaQuery.of(context).padding.bottom - 20),
      ),
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
          if (replyingTo != null) _buildReplyPreview(),
          if (pendingImage != null) _buildImagePreview(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isActive ? SyraColors.surfaceLight : SyraColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? SyraColors.accent.withOpacity(0.8)
                    : SyraColors.border,
                width: isActive ? 1.2 : 0.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TapScale(
                  onTap: onAttachmentTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: EdgeInsets.only(left: 4, bottom: 4),
                    child: const Icon(
                      Icons.add_rounded,
                      color: SyraColors.textMuted,
                      size: 24,
                    ),
                  ),
                ),

                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !isSending,
                    maxLines: 5,
                    minLines: 1,
                    onChanged: (_) => onTextChanged(),
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
                      hintText: "Message",
                      hintStyle: TextStyle(
                        color: SyraColors.textHint,
                        fontSize: 15,
                      ),
                    ),
                    onSubmitted: (_) => canSend ? onSendMessage() : null,
                  ),
                ),

                _TapScale(
                  onTap: onVoiceInputTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: EdgeInsets.only(bottom: 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        key: ValueKey(isListening),
                        color: isListening
                            ? SyraColors.accent
                            : SyraColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Send button with smooth animation
                _TapScale(
                  onTap: canSend ? onSendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 40,
                    height: 40,
                    margin: EdgeInsets.only(right: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: canSend
                          ? SyraColors.textPrimary
                          : SyraColors.textMuted.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? const Padding(
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
                            color: canSend
                                ? SyraColors.background
                                : SyraColors.background.withOpacity(0.5),
                            size: 20,
                          ),
                  ),
                ),
              ],
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

  /// Pending image preview (ChatGPT/Claude style)
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
          // Resim thumbnail
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

          // Upload durumu
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

          // Kapat butonu
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

/// Simple tap scale animation widget
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
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
        child: widget.child,
      ),
    );
  }
}
