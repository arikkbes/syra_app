// lib/screens/chat/chat_input_bar.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA CHAT INPUT BAR - NEW GLASS DESIGN (Figma 2024)
/// ═══════════════════════════════════════════════════════════════
/// Glass surface design from Figma Dev Mode:
/// - Main glass: 24px borderRadius, ~7% obsidian overlay
/// - Backdrop blur: 40px (sigmaX/sigmaY)
/// - Subtle outer shadow/glow for premium feel
/// - Layout: [plus icon] [syra logo] [text: "SYRA'ya Sor"] [send/wave]
/// - Responsive: constraints-based, preserves radius 24
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
  final GlobalKey? chatBackgroundKey; // ← New parameter for Liquid Glass

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
    this.chatBackgroundKey,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  // No liquid glass shader - using pure glass design per Figma specs

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
            // Main glassmorphism input container
            _buildGlassInputBar(canSend, hasText),
          ],
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// NEW GLASS INPUT BAR - Figma Design (radius 24, backdrop blur 40)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildGlassInputBar(bool canSend, bool hasText) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 56,
            maxHeight: 200,
          ),
          decoration: BoxDecoration(
            // Obsidian #11131A at ~7% opacity with screen blend approximation
            color: const Color(0xFF11131A).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(24),
            // Subtle outer glow/shadow for premium feel
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF11131A).withValues(alpha: 0.08),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Plus icon
                _buildIconButton(
                  iconPath: 'assets/icons/plus.svg',
                  onTap: widget.onAttachmentTap,
                ),
                const SizedBox(width: 8),
                // SYRA logo icon placeholder (using plus as fallback since logo SVG not found)
                _buildSmallLogoIcon(),
                const SizedBox(width: 12),
                // Center: TextField
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: !widget.isSending,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => widget.onTextChanged(),
                    style: const TextStyle(
                      color: Color(0xFFE7E9EE),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 2),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintText: 'SYRA\'ya Sor',
                      hintStyle: TextStyle(
                        color: const Color(0xFFE7E9EE).withValues(alpha: 0.4),
                        fontSize: 15,
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
                // Right: Send button or Mic/Wave
                if (canSend) ...[
                  _buildSendButton(),
                ] else ...[
                  if (widget.isListening)
                    _buildVoiceWaveButton()
                  else
                    _buildIconButton(
                      iconPath: 'assets/icons/mic.svg',
                      onTap: widget.onVoiceInputTap,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// ICON BUTTON - Minimal style
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildIconButton({
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              const Color(0xFFE7E9EE).withValues(alpha: 0.6),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// SMALL SYRA LOGO ICON - Non-interactive
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildSmallLogoIcon() {
    // Using a small accent-colored circle as logo placeholder
    // Replace with actual SYRA logo SVG when available
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            SyraColors.accent.withValues(alpha: 0.8),
            SyraColors.accentLight.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: SyraColors.accent.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// SEND BUTTON - Circular with accent gradient
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildSendButton() {
    return _TapScale(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onSendMessage();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              SyraColors.accent,
              SyraColors.accentLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: SyraColors.accent.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/arrow_up.svg',
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              Colors.white.withValues(alpha: 0.95),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// VOICE WAVE BUTTON - Shows while listening (circular)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildVoiceWaveButton() {
    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onVoiceInputTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: SyraColors.accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: SyraColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Center(
          child: _VoiceWaveAnimation(),
        ),
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
        color: const Color(0x1A33B5E5), // accent with 10% opacity
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x4D33B5E5), // accent with 30% opacity
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: SyraColors.accent, // accent
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yanıtlanıyor',
                  style: TextStyle(
                    color: SyraColors.accent, // accent
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
                    color: Colors.white.withValues(alpha: 0.6),
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
              color: Colors.white.withValues(alpha: 0.5),
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
        color: const Color(0xCC1B202C), // surfaceElevated with 80% opacity
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
                      color: Colors.black.withValues(alpha: 0.5),
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
                color: Colors.white.withValues(alpha: 0.6),
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
                color: Colors.white.withValues(alpha: 0.5),
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
          size: const Size(18, 18),
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
      ..color = SyraColors.accent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    const barWidth = 2.0;
    const spacing = 3.0;
    const bars = 4;

    for (int i = 0; i < bars; i++) {
      final offset = (progress + i / bars) % 1.0;
      final height = sin(offset * pi * 2) * (size.height / 2 - 3) + 4;
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
