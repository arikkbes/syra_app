import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'base_shader.dart';

/// Liquid Glass Lens Shader for ChatInputBar
/// Creates premium glass physics with distortion and chromatic aberration
class LiquidGlassLensShader extends BaseShader {
  LiquidGlassLensShader()
      : super(shaderAssetPath: 'shaders/liquid_glass_lens.frag');

  @override
  void updateShaderUniforms({
    required double width,
    required double height,
    required ui.Image? backgroundImage,
  }) {
    if (!isLoaded) return;

    try {
      // Set resolution (indices 0-1)
      shader.setFloat(0, width);
      shader.setFloat(1, height);

      // Set mouse position to center (indices 2-3)
      // For ChatInputBar, we center the effect
      shader.setFloat(2, width / 2);
      shader.setFloat(3, height / 2);

      // Set effect size (index 4)
      // Larger value = bigger glass effect
      // For full bar coverage, use width/height dependent value
      final effectSize = width / 80.0; // Adjusts based on width
      shader.setFloat(4, effectSize);

      // Set blur intensity (index 5)
      // 0.0 = no blur, 2.0 = heavy blur
      shader.setFloat(5, 0.0); // Minimal blur for clarity

      // Set dispersion strength (index 6)
      // Chromatic aberration strength
      shader.setFloat(6, 0.3);

      // Set background texture (sampler index 0)
      if (backgroundImage != null &&
          backgroundImage.width > 0 &&
          backgroundImage.height > 0) {
        shader.setImageSampler(0, backgroundImage);
      }
    } catch (e) {
      debugPrint('❌ Error setting shader uniforms: $e');
    }
  }
}
