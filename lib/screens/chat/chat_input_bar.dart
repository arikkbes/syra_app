// lib/screens/chat/chat_input_bar.dart

import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/liquid_glass_lens_shader.dart';
import '../../widgets/chat_input_bar_liquid_glass.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM GLASSMORPHISM CHAT INPUT BAR WITH LIQUID GLASS
/// ═══════════════════════════════════════════════════════════════
/// Updated with Liquid Glass shader effect:
/// - True liquid glass physics with GLSL shader
/// - Chromatic aberration & distortion
/// - Automatic fallback to blur if shader fails
/// - Optimized background capture with throttling
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
  late LiquidGlassLensShader? _liquidGlassShader;
  bool _useLiquidGlass = true; // Try liquid glass, fallback to blur if fails

  @override
  void initState() {
    super.initState();

    // Initialize Liquid Glass shader if backgroundKey is provided
    if (widget.chatBackgroundKey != null) {
      _liquidGlassShader = LiquidGlassLensShader();
      _liquidGlassShader!.initialize().then((_) {
        if (!_liquidGlassShader!.isLoaded) {
          debugPrint(
              '⚠️ Liquid Glass shader failed to load, using fallback blur');
          if (mounted) {
            setState(() {
              _useLiquidGlass = false;
            });
          }
        } else {
          debugPrint('✅ Liquid Glass shader loaded successfully');
        }
      });
    } else {
      _liquidGlassShader = null;
      _useLiquidGlass = false;
    }
  }

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
  /// GLASSMORPHISM INPUT BAR - Claude-style with buttons below
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildGlassInputBar(bool canSend, bool hasText) {
    final inputBarContent = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                color: const Color(0xFFCFCFCF).withOpacity(0.50),
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
              // Camera icon
              _buildIconButton(
                iconPath: 'assets/icons/camera.svg',
                onTap: widget.onCameraTap ?? () {},
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
                    iconPath: 'assets/icons/mic.svg',
                    onTap: widget.onVoiceInputTap,
                  ),
              ],
            ],
          ),
        ],
      ),
    );

    // Use Liquid Glass if available and enabled
    if (_useLiquidGlass &&
        widget.chatBackgroundKey != null &&
        _liquidGlassShader != null &&
        _liquidGlassShader!.isLoaded) {
      return ChatInputBarLiquidGlass(
        backgroundKey: widget.chatBackgroundKey!,
        shader: _liquidGlassShader!,
        onShaderLoadFailed: () {
          if (mounted) {
            setState(() {
              _useLiquidGlass = false;
            });
          }
        },
        child: inputBarContent,
      );
    }

    // Fallback to standard blur with Claude styling
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 56,
            maxHeight: 200,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Content
              inputBarContent,
              // Top highlight gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.14),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
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
  }) {
    return _TapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.7),
              BlendMode.srcIn,
            ),
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
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/arrow_up.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Colors.black,
              BlendMode.srcIn,
            ),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF33B5E5).withOpacity(0.15),
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
              color: const Color(0xFF33B5E5), // accent
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
                    color: Color(0xFF33B5E5), // accent
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
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Color(0xFF33B5E5)),
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
      ..color = const Color(0xFF33B5E5)
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
