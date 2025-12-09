import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../theme/design_system.dart';
import '../../utils/syra_prefs.dart';

/// ═══════════════════════════════════════════════════════════════
/// THEME SETTINGS SCREEN
/// Let user choose: Dark / Light / Pure Black
/// ═══════════════════════════════════════════════════════════════
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = 'dark'; // default

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = SyraPrefs.getString('theme', defaultValue: 'dark');
    if (mounted) {
      setState(() {
        _selectedTheme = theme;
      });
    }
  }

  Future<void> _saveTheme(String theme) async {
    await SyraPrefs.setString('theme', theme);
    if (mounted) {
      setState(() {
        _selectedTheme = theme;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SyraPage(
      title: 'Theme',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: SyraTokens.paddingXs),
          Text(
            'Choose your preferred theme',
            style: SyraTokens.bodyMd.copyWith(
              color: SyraTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SyraTokens.paddingLg),

          _buildThemeOption(
            value: 'dark',
            title: 'Dark',
            description: 'Modern dark theme with cool tones',
            icon: Icons.dark_mode_outlined,
          ),
          const SizedBox(height: SyraTokens.paddingSm),
          _buildThemeOption(
            value: 'light',
            title: 'Light',
            description: 'Clean light theme for daytime use',
            icon: Icons.light_mode_outlined,
          ),
          const SizedBox(height: SyraTokens.paddingSm),
          _buildThemeOption(
            value: 'pure_black',
            title: 'Pure Black',
            description: 'AMOLED-friendly true black theme',
            icon: Icons.brightness_2_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedTheme == value;

    return GestureDetector(
      onTap: () => _saveTheme(value),
      child: Container(
        padding: EdgeInsets.all(SyraTokens.paddingMd),
        decoration: BoxDecoration(
          color: SyraTokens.card,
          borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
          border: Border.all(
            color: isSelected ? SyraTokens.accent : SyraTokens.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? SyraTokens.accent.withValues(alpha: 0.1)
                    : SyraTokens.cardElevated,
                borderRadius: BorderRadius.circular(SyraTokens.radiusSm),
              ),
              child: Icon(
                icon,
                color: isSelected ? SyraTokens.accent : SyraColors.iconStroke,
                size: 24,
              ),
            ),
            const SizedBox(width: SyraTokens.paddingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SyraTokens.titleSm.copyWith(
                      color: isSelected
                          ? SyraTokens.accent
                          : SyraTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SyraTokens.paddingXxs),
                  Text(
                    description,
                    style: SyraTokens.bodySm,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: SyraTokens.accent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
