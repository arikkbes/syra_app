// lib/widgets/mode_switch_sheet.dart

import 'package:flutter/material.dart';
import 'mode_selector_popover.dart';

/// ═══════════════════════════════════════════════════════════════
/// MODE SWITCH SHEET - Backward Compatibility Wrapper
/// ═══════════════════════════════════════════════════════════════
/// This widget now uses ModeSelectorPopover internally
/// to maintain backward compatibility with existing code
/// ═══════════════════════════════════════════════════════════════

class ModeSwitchSheet extends StatelessWidget {
  final String selectedMode;
  final Function(String) onModeSelected;

  const ModeSwitchSheet({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Forward to new premium popover
    return ModeSelectorPopover(
      selectedMode: selectedMode,
      onModeSelected: onModeSelected,
    );
  }
}
