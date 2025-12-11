// lib/screens/chat/chat_input_bar.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM CHAT INPUT BAR - ChatGPT iOS Style
/// ═══════════════════════════════════════════════════════════════
/// Clean single-layer glassmorphism design with:
/// - Subtle backdrop blur
/// - Clean input field without nested containers
/// - Bottom action row with glass buttons
/// ═══════════════════════════════════════════════════════════════

class ChatInputBar extends StatefulWidget {
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
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onModeTap;
  final String? currentMode;

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
    this.onCameraTap,
    this.onGalleryTap,
    this.onModeTap,
    this.currentMode,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller.text.trim().isNotEmpty;
    final bool isUploadingImage =
        widget.pendingImage != null && widget.pendingImageUrl == null;
    final bool hasPendingImage =
        widget.pendingImage != null && widget.pendingImageUrl != null;
    final bool canSend = (hasText || hasPendingImage) &&
        !widget.isSending &&
        !widget.isLoading &&
        !isUploadingImage;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            if (widget.replyingTo != null) ...[
              _buildReplyPreview(),
              const SizedBox(height: 8),
            ],
            // Image preview
            if (widget.pendingImage != null) ...[
              _buildImagePreview(),
              const SizedBox(height: 8),
            ],
            // Main input container
            _buildMainContainer(canSend, hasText),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// MAIN GLASS CONTAINER
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildMainContainer(bool canSend, bool hasText) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          decoration: BoxDecoration(
            // Clean gradient background
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2A2D35).withOpacity(0.85),
                const Color(0xFF1E2128).withOpacity(0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            // Subtle top highlight
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            // Soft shadow
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Input field row
              _buildInputRow(canSend, hasText),
              // Bottom action row
              _buildActionRow(canSend),
            ],
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// INPUT ROW - TextField with mic/send button
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildInputRow(bool canSend, bool hasText) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              enabled: !widget.isSending,
              maxLines: 5,
              minLines: 1,
              onChanged: (_) => widget.onTextChanged(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'SYRA\'ya sor',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              onSubmitted: (_) {
                if (canSend) {
                  HapticFeedback.mediumImpact();
                  widget.onSendMessage();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Mic or Send button
          _buildInputAction(canSend),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// INPUT ACTION - Mic or Send button
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildInputAction(bool canSend) {
    // Voice wave when listening
    if (widget.isListening) {
      return _buildVoiceWaveButton();
    }

    // Send button when can send
    if (canSend) {
      return _TapScale(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onSendMessage();
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_upward_rounded,
            size: 20,
            color: Color(0xFF1E2128),
          ),
        ),
      );
    }

    // Mic button default
    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onVoiceInputTap();
      },
      child: Container(
        width: 36,
        height: 36,
        child: Icon(
          Icons.mic_none_rounded,
          size: 22,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// ACTION ROW - Bottom buttons
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildActionRow(bool canSend) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Row(
        children: [
          // Plus button
          _buildActionButton(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onAttachmentTap();
            },
          ),
          const SizedBox(width: 4),
          // Camera button
          _buildActionButton(
            icon: Icons.camera_alt_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onCameraTap != null) {
                widget.onCameraTap!();
              } else {
                widget.onAttachmentTap();
              }
            },
          ),
          const SizedBox(width: 4),
          // Gallery button
          _buildActionButton(
            icon: Icons.photo_library_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              if (widget.onGalleryTap != null) {
                widget.onGalleryTap!();
              } else {
                widget.onAttachmentTap();
              }
            },
          ),
          const Spacer(),
          // Mode selector
          _buildModeSelector(),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// ACTION BUTTON - Circular icon button
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// MODE SELECTOR
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildModeSelector() {
    final modeName = widget.currentMode ?? 'Pro';

    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onModeTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              modeName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// VOICE WAVE BUTTON
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildVoiceWaveButton() {
    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onVoiceInputTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const _VoiceWaveAnimation(),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// REPLY PREVIEW
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D35).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SyraColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: SyraColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yanıtlanıyor',
                  style: TextStyle(
                    color: SyraColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyingTo?['text'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _TapScale(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onCancelReply();
            },
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// IMAGE PREVIEW
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildImagePreview() {
    final bool isUploading = widget.pendingImageUrl == null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D35).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(widget.pendingImage!, fit: BoxFit.cover),
                  if (isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(SyraColors.accent),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isUploading ? 'Yükleniyor...' : 'Resim hazır',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          if (!isUploading)
            _TapScale(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onClearImage();
              },
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VOICE WAVE ANIMATION
// ═══════════════════════════════════════════════════════════════

class _VoiceWaveAnimation extends StatefulWidget {
  const _VoiceWaveAnimation();

  @override
  State<_VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<_VoiceWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(24, 24),
          painter: _VoiceWavePainter(_controller.value),
        );
      },
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  final double progress;

  _VoiceWavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2128)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    const barWidth = 2.5;
    const spacing = 3.5;
    const bars = 5;

    for (int i = 0; i < bars; i++) {
      final offset = (progress + i / bars) % 1.0;
      final height = sin(offset * pi * 2) * (size.height / 2 - 4) + 6;
      final x = (size.width - (bars - 1) * (barWidth + spacing)) / 2 +
          i * (barWidth + spacing);

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VoiceWavePainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════
// TAP SCALE ANIMATION
// ═══════════════════════════════════════════════════════════════

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
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
