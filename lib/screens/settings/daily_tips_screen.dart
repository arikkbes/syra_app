import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// DAILY TIPS SCREEN
/// Explains the Daily Tips feature with Basic (free) and Personalized (premium)
/// ═══════════════════════════════════════════════════════════════
class DailyTipsScreen extends StatelessWidget {
  const DailyTipsScreen({super.key});

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
          'Daily Tips',
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
          // Hero section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SyraColors.accent.withValues(alpha: 0.1),
                  SyraColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SyraColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: SyraColors.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    size: 30,
                    color: SyraColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daily Relationship Insights',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: SyraColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get daily tips to improve your relationships and dating life',
                  style: TextStyle(
                    fontSize: 14,
                    color: SyraColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // BASIC TIPS (FREE)
          // ═══════════════════════════════════════════════════════════════
          const Text(
            'BASIC TIPS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SyraColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          _buildTipCard(
            icon: Icons.psychology_outlined,
            title: 'General Advice',
            description:
                'Daily tips on communication, boundaries, and emotional intelligence',
            isFree: true,
          ),
          const SizedBox(height: 12),

          _buildTipCard(
            icon: Icons.favorite_border,
            title: 'Dating Wisdom',
            description:
                'Learn about first dates, texting etiquette, and reading signals',
            isFree: true,
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // PERSONALIZED TIPS (PREMIUM)
          // ═══════════════════════════════════════════════════════════════
          Row(
            children: [
              const Text(
                'PERSONALIZED TIPS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SyraColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: SyraColors.accentGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildTipCard(
            icon: Icons.auto_awesome,
            title: 'AI-Powered Insights',
            description:
                'Tips based on your actual conversations and relationship patterns',
            isFree: false,
          ),
          const SizedBox(height: 12),

          _buildTipCard(
            icon: Icons.track_changes,
            title: 'Progress Tracking',
            description:
                'See how you\'re growing and get targeted advice for your goals',
            isFree: false,
          ),
          const SizedBox(height: 12),

          _buildTipCard(
            icon: Icons.timeline,
            title: 'Situation-Specific',
            description:
                'Advice tailored to your current relationship stage and challenges',
            isFree: false,
          ),

          const SizedBox(height: 32),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SyraColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SyraColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: SyraColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Daily tips are delivered at 9 AM. You can enable or disable them in Notifications settings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: SyraColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isFree,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFree
              ? SyraColors.border
              : SyraColors.accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isFree
                  ? SyraColors.surfaceLight
                  : SyraColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isFree ? SyraColors.iconStroke : SyraColors.accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isFree
                            ? SyraColors.textPrimary
                            : SyraColors.accent,
                      ),
                    ),
                    if (!isFree) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: SyraColors.accent,
                      ),
                    ],
                  ],
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
        ],
      ),
    );
  }
}
