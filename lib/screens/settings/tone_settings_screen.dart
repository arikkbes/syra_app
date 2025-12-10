import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../utils/syra_prefs.dart';

/// ═══════════════════════════════════════════════════════════════
/// TONE SETTINGS SCREEN
/// Energy Level (0-4), Personality Style, Use Emojis, Humor Level
/// ═══════════════════════════════════════════════════════════════
class ToneSettingsScreen extends StatefulWidget {
  const ToneSettingsScreen({super.key});

  @override
  State<ToneSettingsScreen> createState() => _ToneSettingsScreenState();
}

class _ToneSettingsScreenState extends State<ToneSettingsScreen> {
  double _energyLevel = 2.0; // 0-4
  String _personalityStyle = 'mentor'; // cool, mentor, street, sweetAssertive, analyst
  bool _useEmojis = true;
  double _humorLevel = 2.0; // 0-4

  final List<Map<String, dynamic>> _personalityOptions = [
    {
      'value': 'cool',
      'title': 'Cool',
      'description': 'Relaxed and confident vibe',
      'icon': Icons.waves,
    },
    {
      'value': 'mentor',
      'title': 'Mentor',
      'description': 'Wise and supportive guidance',
      'icon': Icons.school_outlined,
    },
    {
      'value': 'street',
      'title': 'Street',
      'description': 'Direct and street-smart',
      'icon': Icons.flash_on,
    },
    {
      'value': 'sweetAssertive',
      'title': 'Sweet Assertive',
      'description': 'Kind yet firm approach',
      'icon': Icons.favorite_outline,
    },
    {
      'value': 'analyst',
      'title': 'Analyst',
      'description': 'Logical and detailed',
      'icon': Icons.analytics_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final energy = SyraPrefs.getDouble('energyLevel', defaultValue: 2.0);
    final personality =
        SyraPrefs.getString('personalityStyle', defaultValue: 'mentor');
    final emojis = SyraPrefs.getBool('useEmojis', defaultValue: true);
    final humor = SyraPrefs.getDouble('humorLevel', defaultValue: 2.0);

    if (mounted) {
      setState(() {
        _energyLevel = energy;
        _personalityStyle = personality;
        _useEmojis = emojis;
        _humorLevel = humor;
      });
    }
  }

  Future<void> _saveEnergyLevel(double value) async {
    await SyraPrefs.setDouble('energyLevel', value);
    if (mounted) {
      setState(() {
        _energyLevel = value;
      });
    }
  }

  Future<void> _savePersonality(String value) async {
    await SyraPrefs.setString('personalityStyle', value);
    if (mounted) {
      setState(() {
        _personalityStyle = value;
      });
    }
  }

  Future<void> _saveEmojis(bool value) async {
    await SyraPrefs.setBool('useEmojis', value);
    if (mounted) {
      setState(() {
        _useEmojis = value;
      });
    }
  }

  Future<void> _saveHumorLevel(double value) async {
    await SyraPrefs.setDouble('humorLevel', value);
    if (mounted) {
      setState(() {
        _humorLevel = value;
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
          'Tone',
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
          // ENERGY LEVEL
          // ═══════════════════════════════════════════════════════════════
          const SizedBox(height: 8),
          const Text(
            'ENERGY LEVEL',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calm',
                      style: TextStyle(
                        fontSize: 13,
                        color: SyraColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getEnergyLabel(_energyLevel),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: SyraColors.accent,
                      ),
                    ),
                    const Text(
                      'High Energy',
                      style: TextStyle(
                        fontSize: 13,
                        color: SyraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _energyLevel,
                  min: 0,
                  max: 4,
                  divisions: 4,
                  activeColor: SyraColors.accent,
                  inactiveColor: SyraColors.divider,
                  onChanged: (value) => _saveEnergyLevel(value),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // PERSONALITY STYLE
          // ═══════════════════════════════════════════════════════════════
          const SizedBox(height: 32),
          const Text(
            'PERSONALITY STYLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          ..._personalityOptions.map((option) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _buildPersonalityOption(
                  value: option['value'] as String,
                  title: option['title'] as String,
                  description: option['description'] as String,
                  icon: option['icon'] as IconData,
                ),
              )),

          // ═══════════════════════════════════════════════════════════════
          // USE EMOJIS
          // ═══════════════════════════════════════════════════════════════
          const SizedBox(height: 20),
          const Text(
            'EMOJIS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SyraColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SyraColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_emotions_outlined,
                  color: SyraColors.iconStroke,
                  size: 24,
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Emojis',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: SyraColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Add emojis to responses',
                        style: TextStyle(
                          fontSize: 13,
                          color: SyraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useEmojis,
                  onChanged: (value) => _saveEmojis(value),
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // HUMOR LEVEL
          // ═══════════════════════════════════════════════════════════════
          const SizedBox(height: 32),
          const Text(
            'HUMOR LEVEL',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Serious',
                      style: TextStyle(
                        fontSize: 13,
                        color: SyraColors.textSecondary,
                      ),
                    ),
                    Text(
                      _getHumorLabel(_humorLevel),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: SyraColors.accent,
                      ),
                    ),
                    const Text(
                      'Playful',
                      style: TextStyle(
                        fontSize: 13,
                        color: SyraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _humorLevel,
                  min: 0,
                  max: 4,
                  divisions: 4,
                  activeColor: SyraColors.accent,
                  inactiveColor: SyraColors.divider,
                  onChanged: (value) => _saveHumorLevel(value),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPersonalityOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _personalityStyle == value;

    return GestureDetector(
      onTap: () => _savePersonality(value),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? SyraColors.accent.withValues(alpha: 0.1)
                    : SyraColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? SyraColors.accent : SyraColors.iconStroke,
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 2),
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

  String _getEnergyLabel(double level) {
    if (level == 0) return 'Very Calm';
    if (level == 1) return 'Relaxed';
    if (level == 2) return 'Balanced';
    if (level == 3) return 'Energetic';
    return 'Very Energetic';
  }

  String _getHumorLabel(double level) {
    if (level == 0) return 'No Humor';
    if (level == 1) return 'Subtle';
    if (level == 2) return 'Moderate';
    if (level == 3) return 'Witty';
    return 'Very Playful';
  }
}
