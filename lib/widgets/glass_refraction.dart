// lib/widgets/glass_refraction.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Real Glass Refraction Effect
/// Uses custom GLSL fragment shader for authentic glass physics
class GlassRefraction extends StatefulWidget {
  final Widget child;
  final double thickness;
  final double refractiveIndex;
  final double blur;
  final BorderRadius? borderRadius;

  const GlassRefraction({
    super.key,
    required this.child,
    this.thickness = 0.15,
    this.refractiveIndex = 1.25,
    this.blur = 24.0,
    this.borderRadius,
  });

  @override
  State<GlassRefraction> createState() => _GlassRefractionState();
}

class _GlassRefractionState extends State<GlassRefraction> {
  ui.FragmentShader? _shader;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/glass_refraction.frag',
      );
      setState(() {
        _shader = program.fragmentShader();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load shader: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _shader == null) {
      // Fallback: Simple backdrop filter
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: widget.child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CustomPaint(
        painter: _GlassRefractionPainter(
          shader: _shader!,
          thickness: widget.thickness,
          refractiveIndex: widget.refractiveIndex,
          blur: widget.blur,
        ),
        child: widget.child,
      ),
    );
  }
}

class _GlassRefractionPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double thickness;
  final double refractiveIndex;
  final double blur;

  _GlassRefractionPainter({
    required this.shader,
    required this.thickness,
    required this.refractiveIndex,
    required this.blur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms
    shader.setFloat(0, size.width);  // uSize.x
    shader.setFloat(1, size.height); // uSize.y
    // Note: uTexture will be set by Flutter automatically
    shader.setFloat(2, thickness);        // uThickness
    shader.setFloat(3, refractiveIndex);  // uRefractiveIndex
    shader.setFloat(4, blur);             // uBlur

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_GlassRefractionPainter oldDelegate) {
    return oldDelegate.thickness != thickness ||
        oldDelegate.refractiveIndex != refractiveIndex ||
        oldDelegate.blur != blur;
  }
}
