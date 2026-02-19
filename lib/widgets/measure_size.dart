// lib/widgets/measure_size.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A widget that measures and reports its child's size
/// 
/// Usage:
/// ```dart
/// MeasureSize(
///   onChange: (Size size) {
///     syraLog('Child size: ${size.width} x ${size.height}');
///   },
///   child: YourWidget(),
/// )
/// ```
class MeasureSize extends StatefulWidget {
  final Widget child;
  final ValueChanged<Size> onChange;

  const MeasureSize({
    super.key,
    required this.onChange,
    required this.child,
  });

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    return _MeasureSizeRenderObject(
      onChange: widget.onChange,
      child: widget.child,
    );
  }
}

class _MeasureSizeRenderObject extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onChange;

  const _MeasureSizeRenderObject({
    required this.onChange,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderBox(onChange);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _MeasureSizeRenderBox renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderBox extends RenderProxyBox {
  ValueChanged<Size> onChange;
  Size? _oldSize;

  _MeasureSizeRenderBox(this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    final newSize = child?.size;
    if (newSize != null && newSize != _oldSize) {
      _oldSize = newSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onChange(newSize);
      });
    }
  }
}
