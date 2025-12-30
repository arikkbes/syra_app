import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/relationship_analysis_result.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP ANALYSIS RESULT SCREEN V2
/// ═══════════════════════════════════════════════════════════════
/// Displays the analysis result from uploaded WhatsApp chat
/// Updated for new chunked pipeline architecture
/// ═══════════════════════════════════════════════════════════════

class RelationshipAnalysisResultScreen extends StatelessWidget {
  final RelationshipAnalysisResult analysisResult;

  const RelationshipAnalysisResultScreen({
    super.key,
    required this.analysisResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        if (analysisResult.personalities != null &&
                            analysisResult.personalities!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildPersonalitiesCard(),
                        ],
                        if (analysisResult.dynamics != null) ...[
                          const SizedBox(height: 16),
                          _buildDynamicsCard(),
                        ],
                        if (analysisResult.patterns != null) ...[
                          const SizedBox(height: 16),
                          _buildPatternsCard(),
                        ],
                        if (analysisResult.timeline != null &&
                            analysisResult.timeline!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildTimelineCard(),
                        ],
                      ],
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

  Widget _buildAppBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: SyraColors.background.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: SyraColors.divider,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: SyraColors.textPrimary,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: SyraColors.accent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "İlişki Analizi",
                        style: TextStyle(
                          color: SyraColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraColors.accent.withOpacity(0.2),
                      SyraColors.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sohbet İstatistikleri',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            icon: Icons.message_outlined,
            label: 'Toplam Mesaj',
            value: '${analysisResult.totalMessages}',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.folder_outlined,
            label: 'Analiz Edilen Dönem',
            value: '${analysisResult.totalChunks} parça',
          ),
          if (analysisResult.speakers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.people_outline_rounded,
              label: 'Konuşmacılar',
              value: analysisResult.speakers.join(' & '),
              valueSize: 13,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    double? valueSize,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: SyraColors.textSecondary,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: SyraColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: SyraColors.textPrimary,
              fontSize: valueSize ?? 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraColors.accent.withOpacity(0.2),
                      SyraColors.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Genel Özet',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysisResult.shortSummary,
            style: const TextStyle(
              color: SyraColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitiesCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraColors.accent.withOpacity(0.2),
                      SyraColors.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kişilik Profilleri',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...analysisResult.personalities!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPersonalitySection(entry.key, entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection(String name, PersonalityProfile profile) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SyraColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraColors.border.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: SyraColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (profile.traits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.traits.map((trait) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SyraColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trait,
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (profile.communicationStyle != null) ...[
            const SizedBox(height: 10),
            Text(
              'İletişim: ${profile.communicationStyle}',
              style: TextStyle(
                color: SyraColors.textSecondary.withOpacity(0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicsCard() {
    final dynamics = analysisResult.dynamics!;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraColors.accent.withOpacity(0.2),
                      SyraColors.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'İlişki Dinamikleri',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (dynamics.conflictStyle != null)
            _buildDynamicItem(
              icon: Icons.flash_on_rounded,
              label: 'Tartışma Tarzı',
              value: dynamics.conflictStyle!,
            ),
          if (dynamics.attachmentPattern != null) ...[
            const SizedBox(height: 12),
            _buildDynamicItem(
              icon: Icons.link_rounded,
              label: 'Bağlanma Şekli',
              value: _formatAttachment(dynamics.attachmentPattern!),
            ),
          ],
          if (dynamics.loveLanguages.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDynamicItem(
              icon: Icons.favorite_outline_rounded,
              label: 'Sevgi Dilleri',
              value: dynamics.loveLanguages.join(', '),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAttachment(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'secure':
        return 'Güvenli';
      case 'anxious':
        return 'Kaygılı';
      case 'avoidant':
        return 'Kaçıngan';
      case 'mixed':
        return 'Karışık';
      default:
        return pattern;
    }
  }

  Widget _buildDynamicItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SyraColors.textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: SyraColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatternsCard() {
    final patterns = analysisResult.patterns!;
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraColors.accent.withOpacity(0.2),
                      SyraColors.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pattern_rounded,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Örüntüler',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (patterns.strengths.isNotEmpty) ...[
            _buildPatternSection('💚 Güçlü Yanlar', patterns.strengths, Colors.green),
            const SizedBox(height: 16),
          ],
          if (patterns.recurringIssues.isNotEmpty) ...[
            _buildPatternSection('⚠️ Tekrar Eden Sorunlar', patterns.recurringIssues, Colors.orange),
            const SizedBox(height: 16),
          ],
          if (patterns.redFlags.isNotEmpty) ...[
            _buildPatternSection('🚩 Kırmızı Bayraklar', patterns.redFlags, Colors.red),
          ],
          if (patterns.greenFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPatternSection('✅ Yeşil Bayraklar', patterns.greenFlags, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: SyraColors.textSecondary.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimelineCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraColors.accent.withOpacity(0.2),
                      SyraColors.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'İlişki Zaman Çizelgesi',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...analysisResult.timeline!.asMap().entries.map((entry) {
            final index = entry.key;
            final phase = entry.value;
            final isLast = index == analysisResult.timeline!.length - 1;
            
            return _buildTimelineItem(phase, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(RelationshipPhase phase, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: SyraColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: SyraColors.accent.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase.name,
                  style: const TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (phase.period != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    phase.period!,
                    style: TextStyle(
                      color: SyraColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (phase.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    phase.description!,
                    style: TextStyle(
                      color: SyraColors.textSecondary.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// GlassCard widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SyraColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SyraColors.border.withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
