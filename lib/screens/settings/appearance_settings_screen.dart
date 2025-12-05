import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../utils/syra_prefs.dart';

/// ═══════════════════════════════════════════════════════════════
/// APPEARANCE SETTINGS SCREEN
/// Font size slider (12-20) + UI scale (Compact/Standard/Spacious)
/// ═══════════════════════════════════════════════════════════════
class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  double _fontSize = 15.0;
  String _uiScale = 'standard'; // compact, standard, spacious

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fontSize = SyraPrefs.getDouble('fontSize', defaultValue: 15.0);
    final uiScale = SyraPrefs.getString('uiScale', defaultValue: 'standard');
    if (mounted) {
      setState(() {
        _fontSize = fontSize;
        _uiScale = uiScale;
      });
    }
  }

  Future<void> _saveFontSize(double size) async {
    await SyraPrefs.setDouble('fontSize', size);
    if (mounted) {
      setState(() {
        _fontSize = size;
      });
    }
  }

  Future<void> _saveUIScale(String scale) async {
    await SyraPrefs.setString('uiScale', scale);
    if (mounted) {
      setState(() {
        _uiScale = scale;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: SyraColors.iconStroke,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Appearance',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: SyraColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══════════════════════════════════════════════════════════════
          // FONT SIZE
          // ═══════════════════════════════════════════════════════════════
          const SizedBox(height: 8),
          const Text(
            'FONT SIZE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SyraColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SyraColors.border),
            ),
            child: Column(
              children: [
                Text(
                  'Preview Text',
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w500,
                    color: SyraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'A',
                      style: TextStyle(
                        fontSize: 12,
                        color: SyraColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 12.0,
                        max: 20.0,
                        divisions: 8,
                        activeColor: SyraColors.accent,
                        inactiveColor: SyraColors.divider,
                        label: _fontSize.toStringAsFixed(0),
                        onChanged: (value) => _saveFontSize(value),
                      ),
                    ),
                    const Text(
                      'A',
                      style: TextStyle(
                        fontSize: 18,
                        color: SyraColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_fontSize.toStringAsFixed(0)} pt',
                  style: const TextStyle(
                    fontSize: 13,
                    color: SyraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // UI SCALE
          // ═══════════════════════════════════════════════════════════════
          const SizedBox(height: 32),
          const Text(
            'UI SCALE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          _buildScaleOption(
            value: 'compact',
            title: 'Compact',
            description: 'Tighter spacing, more content',
          ),
          const SizedBox(height: 12),
          _buildScaleOption(
            value: 'standard',
            title: 'Standard',
            description: 'Balanced and comfortable',
          ),
          const SizedBox(height: 12),
          _buildScaleOption(
            value: 'spacious',
            title: 'Spacious',
            description: 'Larger spacing, easier to read',
          ),
        ],
      ),
    );
  }

  Widget _buildScaleOption({
    required String value,
    required String title,
    required String description,
  }) {
    final isSelected = _uiScale == value;

    return GestureDetector(
      onTap: () => _saveUIScale(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SyraColors.accent : SyraColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? SyraColors.accent
                          : SyraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SyraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: SyraColors.accent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
