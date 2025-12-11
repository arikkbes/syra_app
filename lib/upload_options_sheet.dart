// lib/widgets/upload_options_sheet.dart

import 'dart:ui';
// LEGACY / UNUSED COPY – canonical version lives under lib/widgets/upload_options_sheet.dart
// Kept only as backup. Do not import this file from production code.

import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import '../theme/syra_animations.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM UPLOAD OPTIONS SHEET
/// ═══════════════════════════════════════════════════════════════
/// Bottom sheet for relationship/WhatsApp chat upload:
/// - Glass blur effect
/// - Primary action (upload)
/// - Support info
/// - Smooth animations
/// ═══════════════════════════════════════════════════════════════

class UploadOptionsSheet extends StatelessWidget {
  final VoidCallback onUploadWhatsApp;

  const UploadOptionsSheet({
    super.key,
    required this.onUploadWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SyraColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SyraRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: SyraSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SyraColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ).fadeInSlide(delay: Duration(milliseconds: 50)),

          SizedBox(height: SyraSpacing.lg),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SyraSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(SyraSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            SyraColors.accent.withValues(alpha: 0.2),
                            SyraColors.accent.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(SyraRadius.md),
                      ),
                      child: Icon(
                        Icons.upload_file_outlined,
                        color: SyraColors.accent,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: SyraSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'İlişki Analizi',
                            style: SyraTextStyles.headingMedium,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Beta',
                            style: SyraTextStyles.caption.copyWith(
                              color: SyraColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).fadeInSlide(delay: Duration(milliseconds: 100)),

                SizedBox(height: SyraSpacing.lg),

                // Description
                Text(
                  'WhatsApp sohbetini dışa aktar, buraya yükle.\nSYRA ilişki dinamiğini senin yerine analiz etsin.',
                  style: SyraTextStyles.bodyMedium.copyWith(
                    color: SyraColors.textSecondary,
                    height: 1.6,
                  ),
                ).fadeInSlide(delay: Duration(milliseconds: 150)),

                SizedBox(height: SyraSpacing.xl),

                // Primary upload button
                _buildPrimaryButton(
                  context: context,
                  onTap: () {
                    Navigator.pop(context);
                    onUploadWhatsApp();
                  },
                ).fadeInSlide(delay: Duration(milliseconds: 200)),

                SizedBox(height: SyraSpacing.lg),

                // Support info
                _buildSupportInfo().fadeInSlide(
                  delay: Duration(milliseconds: 250),
                ),

                SizedBox(height: SyraSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIMARY BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPrimaryButton({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: SyraSpacing.md + 2),
        decoration: BoxDecoration(
          gradient: SyraColors.accentGradient,
          borderRadius: BorderRadius.circular(SyraRadius.lg),
          boxShadow: [
            BoxShadow(
              color: SyraColors.accent.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 0,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: SyraSpacing.sm),
            Text(
              'WhatsApp Chat Yükle',
              style: SyraTextStyles.button.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUPPORT INFO
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSupportInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SyraRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: SyraGlass.blurSubtle,
          sigmaY: SyraGlass.blurSubtle,
        ),
        child: Container(
          padding: EdgeInsets.all(SyraSpacing.md),
          decoration: BoxDecoration(
            color: SyraColors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(SyraRadius.md),
            border: Border.all(
              color: SyraColors.border.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: SyraColors.accent.withValues(alpha: 0.7),
              ),
              SizedBox(width: SyraSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Desteklenen formatlar',
                      style: SyraTextStyles.labelMedium.copyWith(
                        color: SyraColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: SyraSpacing.xs - 2),
                    Text(
                      'WhatsApp dışa aktarma: .txt veya .zip dosyası',
                      style: SyraTextStyles.caption.copyWith(
                        color: SyraColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
