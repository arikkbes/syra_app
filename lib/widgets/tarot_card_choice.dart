import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

class TarotCardChoice extends StatefulWidget {
  final int cardId;
  final String label;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onTap;

  const TarotCardChoice({
    super.key,
    required this.cardId,
    required this.label,
    required this.isSelected,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<TarotCardChoice> createState() => _TarotCardChoiceState();
}

class _TarotCardChoiceState extends State<TarotCardChoice>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TarotCardChoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward().then((_) {
        if (mounted) {
          _scaleController.reverse();
        }
      });
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isActive) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isActive ? widget.onTap : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 90,
          height: 130,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : 1.0),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? SyraColors.accent.withValues(alpha: 0.15)
                : SyraColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? SyraColors.accent : SyraColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: SyraColors.accent.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 78,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [
                            SyraColors.accent.withValues(alpha: 0.3),
                            SyraColors.accentLight.withValues(alpha: 0.2),
                          ]
                        : [
                            SyraColors.surface,
                            SyraColors.surfaceLight,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isSelected
                        ? SyraColors.accent.withValues(alpha: 0.5)
                        : SyraColors.border,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: widget.isSelected
                              ? SyraColors.accent
                              : SyraColors.textMuted,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                        ),
                        child: const Text('✦'),
                      ),
                    ),
                    if (widget.isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: RadialGradient(
                              colors: [
                                SyraColors.accent.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              center: Alignment.center,
                              radius: 0.8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? SyraColors.accent
                        : SyraColors.textMuted,
                    fontSize: 10,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
