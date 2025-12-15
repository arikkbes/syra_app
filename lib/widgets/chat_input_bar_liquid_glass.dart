import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../utils/base_shader.dart';
import '../utils/shader_painter.dart';

/// Optimized Liquid Glass widget for ChatInputBar
/// Features:
/// - Throttled background capture (30-50ms)
/// - Captures only on specific events (scroll, keyboard, etc.)
/// - Automatic fallback to blur if shader fails
class ChatInputBarLiquidGlass extends StatefulWidget {
  const ChatInputBarLiquidGlass({
    super.key,
    required this.child,
    required this.backgroundKey,
    required this.shader,
    this.captureThrottle = const Duration(milliseconds: 40),
    this.onShaderLoadFailed,
  });

  final Widget child;
  final GlobalKey backgroundKey;
  final BaseShader shader;
  final Duration captureThrottle;
  final VoidCallback? onShaderLoadFailed;

  @override
  State<ChatInputBarLiquidGlass> createState() =>
      _ChatInputBarLiquidGlassState();
}

class _ChatInputBarLiquidGlassState extends State<ChatInputBarLiquidGlass> {
  ui.Image? _capturedBackground;
  bool _isCapturing = false;
  DateTime? _lastCaptureTime;
  bool _shaderFailed = false;

  @override
  void initState() {
    super.initState();

    // Check if shader loaded successfully
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.shader.isLoaded) {
        setState(() {
          _shaderFailed = true;
        });
        widget.onShaderLoadFailed?.call();
        debugPrint(
            '⚠️ Liquid Glass shader failed to load, using fallback blur');
      } else {
        // Initial capture
        _captureBackground();
      }
    });
  }

  @override
  void dispose() {
    _capturedBackground?.dispose();
    super.dispose();
  }

  /// Throttled background capture
  /// Only captures if enough time has passed since last capture
  Future<void> _captureBackground() async {
    if (_isCapturing || !mounted || _shaderFailed) return;

    // Throttle check
    final now = DateTime.now();
    if (_lastCaptureTime != null) {
      final timeSinceLastCapture = now.difference(_lastCaptureTime!);
      if (timeSinceLastCapture < widget.captureThrottle) {
        return; // Skip this capture
      }
    }

    _isCapturing = true;
    _lastCaptureTime = now;

    try {
      // Get the RepaintBoundary
      final boundary = widget.backgroundKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      final ourBox = context.findRenderObject() as RenderBox?;

      if (boundary == null ||
          !boundary.attached ||
          ourBox == null ||
          !ourBox.hasSize) {
        return;
      }

      // Calculate the capture region
      final boundaryBox = boundary as RenderBox;
      if (!boundaryBox.hasSize) {
        return;
      }

      final widgetRectInBoundary = Rect.fromPoints(
        boundaryBox.globalToLocal(ourBox.localToGlobal(Offset.zero)),
        boundaryBox.globalToLocal(
          ourBox.localToGlobal(ourBox.size.bottomRight(Offset.zero)),
        ),
      );

      final boundaryRect = Rect.fromLTWH(
        0,
        0,
        boundaryBox.size.width,
        boundaryBox.size.height,
      );
      final regionToCapture = widgetRectInBoundary.intersect(boundaryRect);

      if (regionToCapture.isEmpty) {
        return;
      }

      // Capture the image
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final offsetLayer = boundary.debugLayer! as OffsetLayer;
      final croppedImage = await offsetLayer.toImage(
        regionToCapture,
        pixelRatio: pixelRatio,
      );

      // Update state
      if (mounted) {
        setState(() {
          _capturedBackground?.dispose();
          _capturedBackground = croppedImage;
        });
      } else {
        croppedImage.dispose();
      }
    } catch (e) {
      debugPrint('❌ Error capturing background: $e');
      // On first error, fall back to blur
      if (mounted && !_shaderFailed) {
        setState(() {
          _shaderFailed = true;
        });
        widget.onShaderLoadFailed?.call();
      }
    } finally {
      if (mounted) {
        _isCapturing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fallback: use standard blur if shader failed or not loaded
    if (_shaderFailed || !widget.shader.isLoaded) {
      return _buildFallbackBlur();
    }

    // Normal liquid glass with shader
    return _buildLiquidGlass();
  }

  /// Build liquid glass with shader
  Widget _buildLiquidGlass() {
    if (_capturedBackground == null) {
      // Still loading first capture
      return _buildFallbackBlur();
    }

    // Update shader uniforms with dynamic height
    final size = MediaQuery.of(context).size;
    widget.shader.updateShaderUniforms(
      width: size.width - 32,
      height: 120, // Increased for multiline support
      backgroundImage: _capturedBackground,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 56,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
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
            // Shader background
            CustomPaint(
              size: Size(size.width - 32, 120),
              painter: ShaderPainter(widget.shader.shader),
            ),
            // Tint overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
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
            // Content
            widget.child,
          ],
        ),
      ),
    );
  }

  /// Fallback to standard blur effect with Claude styling
  Widget _buildFallbackBlur() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
              widget.child,
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

  /// Public method to trigger capture on demand
  /// Call this from parent on scroll, keyboard events, etc.
  void triggerCapture() {
    if (!_shaderFailed && widget.shader.isLoaded) {
      _captureBackground();
    }
  }
}
