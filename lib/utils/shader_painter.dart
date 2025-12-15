import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Custom painter that renders the liquid glass effect on the captured background
/// Used by ChatInputBar to paint shader effects
class ShaderPainter extends CustomPainter {
  ShaderPainter(
    this.shader,
  );

  final ui.FragmentShader shader;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      if (size.width <= 0 || size.height <= 0) {
        return;
      }

      final paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    } catch (e) {
      debugPrint('❌ ShaderPainter error: $e');
      // Fallback: transparent
      final paint = Paint()..color = Colors.transparent;
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
