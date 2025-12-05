import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../utils/syra_prefs.dart';

/// ═══════════════════════════════════════════════════════════════
/// MESSAGE LENGTH SCREEN
/// Options: Short / Medium / Long / Adaptive
/// ═══════════════════════════════════════════════════════════════
class MessageLengthScreen extends StatefulWidget {
  const MessageLengthScreen({super.key});

  @override
  State<MessageLengthScreen> createState() => _MessageLengthScreenState();
}

class _MessageLengthScreenState extends State<MessageLengthScreen> {
  String _messageLength = 'medium'; // short, medium, long, adaptive

  final List<Map<String, dynamic>> _lengthOptions = [
    {
      'value': 'short',
      'title': 'Short',
      'description': 'Quick, concise responses (1-2 sentences)',
      'icon': Icons.short_text,
    },
    {
      'value': 'medium',
      'title': 'Medium',
      'description': 'Balanced responses (2-4 sentences)',
      'icon': Icons.text_fields,
    },
    {
      'value': 'long',
      'title': 'Long',
      'description': 'Detailed, thorough responses (4+ sentences)',
      'icon': Icons.notes,
    },
    {
      'value': 'adaptive',
      'title': 'Adaptive',
      'description': 'Adjusts based on your question complexity',
      'icon': Icons.auto_awesome,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final length = SyraPrefs.getString('messageLength', defaultValue: 'medium');
    if (mounted) {
      setState(() {
        _messageLength = length;
      });
    }
  }

  Future<void> _saveMessageLength(String length) async {
    await SyraPrefs.setString('messageLength', length);
    if (mounted) {
      setState(() {
        _messageLength = length;
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
          'Message Length',
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
          const SizedBox(height: 8),
          const Text(
            'Choose how long you want SYRA\'s responses to be',
            style: TextStyle(
              fontSize: 14,
              color: SyraColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          ..._lengthOptions.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLengthOption(
                  value: option['value'] as String,
                  title: option['title'] as String,
                  description: option['description'] as String,
                  icon: option['icon'] as IconData,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLengthOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _messageLength == value;

    return GestureDetector(
      onTap: () => _saveMessageLength(value),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? SyraColors.accent.withValues(alpha: 0.1)
                    : SyraColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
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
                      fontSize: 16,
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
