import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import 'syra_bottom_panel.dart';

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
    return SyraBottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12, top: 4),
            child: Text(
              'Konuşma Modu',
              style: TextStyle(
                color: SyraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildModeOption(
            context,
            displayName: 'Normal',
            key: 'standard',
          ),
          _buildModeOption(
            context,
            displayName: 'Derin Analiz',
            key: 'deep',
          ),
          _buildModeOption(
            context,
            displayName: 'Dost Acı Söyler',
            key: 'mentor',
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required String displayName,
    required String key,
  }) {
    final isSelected = selectedMode == key;

    return InkWell(
      onTap: () {
        onModeSelected(key);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? SyraColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SyraColors.accent.withOpacity(0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  color: isSelected
                      ? SyraColors.textPrimary
                      : SyraColors.textSecondary,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: SyraColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
