// lib/screens/chat/chat_input_bar.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as ib;
import '../../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHAT INPUT BAR - Single blur implementation
/// ═══════════════════════════════════════════════════════════════
/// Simplified to use only BackdropFilter blur (no shader effects)
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
  final GlobalKey? chatBackgroundKey; // Unused - kept for API compatibility

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
  // No shader initialization needed - using simple BackdropFilter only

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
      bottom: false, // Home indicator'a yaklaştırmak için kapatıldı
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
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
  /// GLASSMORPHISM INPUT BAR - Claude-style frosted glass
  /// ═══════════════════════════════════════════════════════════════
  /// Settings: blur 9, tint 0.004, border 0.10, outer shadow for separation
  Widget _buildGlassInputBar(bool canSend, bool hasText) {
    // GLASS EFFECT: Claude-style frosted glass (crisp but premium)
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 72, // 56 → 72 (daha yüksek)
            maxHeight: 240, // 200 → 240
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: ib.BoxDecoration(
            color: Colors.white.withValues(alpha: 0.004),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: [
              // Outer shadow for separation from background glass (crucial for Claude-like depth)
              ib.BoxShadow(
                inset: false,
                offset: const Offset(0, 10),
                blurRadius: 24,
                color: Colors.black.withValues(alpha: 0.30),
              ),
              // Inset shadow top (refined)
              ib.BoxShadow(
                inset: true,
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black.withValues(alpha: 0.18),
              ),
              // Inset shadow bottom (refined)
              ib.BoxShadow(
                inset: true,
                offset: const Offset(0, 2),
                blurRadius: 4,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // TextField - üstte, tam genişlik
              TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                enabled: !widget.isSending,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => widget.onTextChanged(),
                style: const TextStyle(
                  color: Color(0xFFCFCFCF),
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
                  hintText: 'SYRA\'ya sor…',
                  hintStyle: TextStyle(
                    color: const Color(0xFFFFFFFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'DMSerifDisplay',
                  ),
                ),
                onSubmitted: (_) {
                  if (canSend) {
                    HapticFeedback.mediumImpact();
                    widget.onSendMessage();
                  }
                },
              ),
              const SizedBox(height: 8),
              // Butonlar - altta
              Row(
                children: [
                  // Plus icon
                  _buildIconButton(
                    iconPath: 'assets/icons/plus.svg',
                    onTap: widget.onAttachmentTap,
                  ),
                  const SizedBox(width: 4),
                  // Logo icon (disabled)
                  _buildIconButton(
                    iconPath: 'assets/icons/logo.svg',
                    onTap: () {}, // Disabled for now
                  ),
                  const Spacer(),
                  // Mic veya Send - sağ
                  if (canSend) ...[
                    _buildSendButton(),
                  ] else ...[
                    if (widget.isListening)
                      _buildVoiceWaveButton()
                    else
                      _buildIconButton(
                        iconPath: 'assets/icons/waveform.svg',
                        onTap: widget.onVoiceInputTap,
                        useColorFilter: false,
                        iconSize: 29, // 26 → 29 (3px büyütüldü)
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// ICON BUTTON - Claude-style smaller icons
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildIconButton({
    required String iconPath,
    required VoidCallback onTap,
    bool useColorFilter = true,
    double? iconSize,
  }) {
    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 39, // 36 → 39 (3px büyütüldü)
        height: 39, // 36 → 39 (3px büyütüldü)
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: iconSize ?? 27, // 24 → 27 (3px büyütüldü)
            height: iconSize ?? 27, // 24 → 27 (3px büyütüldü)
            colorFilter: useColorFilter
                ? const ColorFilter.mode(
                    Color(0xFFFFFFFF),
                    BlendMode.srcIn,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// SEND BUTTON - Claude-style
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildSendButton() {
    return _TapScale(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onSendMessage();
      },
      child: SizedBox(
        width: 39, // 36 → 39 (3px büyütüldü)
        height: 39, // 36 → 39 (3px büyütüldü)
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/arrow-up.svg',
            width: 29, // 26 → 29 (3px büyütüldü)
            height: 29, // 26 → 29 (3px büyütüldü)
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// VOICE WAVE BUTTON - Shows while listening
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildVoiceWaveButton() {
    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onVoiceInputTap();
      },
      child: Container(
        width: 31, // 28 → 31 (3px büyütüldü)
        height: 31, // 28 → 31 (3px büyütüldü)
        decoration: BoxDecoration(
          color: SyraColors.accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
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
