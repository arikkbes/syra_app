import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/relationship_analysis_result.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP ANALYSIS RESULT SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Displays the analysis result from uploaded WhatsApp chat
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
                        if (analysisResult.energyTimeline.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildEnergyTimelineCard(),
                        ],
                        if (analysisResult.keyMoments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildKeyMomentsCard(),
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
    final dateFormatter = DateFormat('dd MMM yyyy');
    String dateRange = 'Tarih bilgisi yok';
    
    if (analysisResult.startDate != null && analysisResult.endDate != null) {
      dateRange = '${dateFormatter.format(analysisResult.startDate!)} - ${dateFormatter.format(analysisResult.endDate!)}';
    }

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
            icon: Icons.calendar_today_rounded,
            label: 'Tarih Aralığı',
            value: dateRange,
            valueSize: 13,
          ),
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
        Text(
          value,
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: valueSize ?? 15,
            fontWeight: FontWeight.w600,
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

  Widget _buildEnergyTimelineCard() {
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
                'Enerji Zaman Çizelgesi',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...analysisResult.energyTimeline.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEnergyPoint(point),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnergyPoint(EnergyPoint point) {
    Color levelColor;
    IconData levelIcon;

    switch (point.level.toLowerCase()) {
      case 'high':
        levelColor = Colors.green;
        levelIcon = Icons.arrow_upward_rounded;
        break;
      case 'low':
        levelColor = Colors.red;
        levelIcon = Icons.arrow_downward_rounded;
        break;
      default:
        levelColor = Colors.orange;
        levelIcon = Icons.remove_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: levelColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            levelIcon,
            color: levelColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.label,
                style: const TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (point.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  point.description!,
                  style: TextStyle(
                    color: SyraColors.textSecondary.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMomentsCard() {
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
                  Icons.star_rounded,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Önemli Anlar',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...analysisResult.keyMoments.map((moment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildKeyMoment(moment),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKeyMoment(KeyMoment moment) {
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
            moment.title,
            style: const TextStyle(
              color: SyraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            moment.description,
            style: TextStyle(
              color: SyraColors.textSecondary.withOpacity(0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (moment.date != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: SyraColors.textMuted,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMMM yyyy').format(moment.date!),
                  style: const TextStyle(
                    color: SyraColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// GlassCard widget (eğer yoksa)
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
