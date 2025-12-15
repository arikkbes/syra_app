// lib/screens/kim_daha_cok_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../services/relationship_stats_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// KIM DAHA ÇOK? SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Uploaded relationship verilerinden "kim daha çok" istatistiklerini gösterir.
/// ═══════════════════════════════════════════════════════════════

class KimDahaCokScreen extends StatefulWidget {
  const KimDahaCokScreen({super.key});

  @override
  State<KimDahaCokScreen> createState() => _KimDahaCokScreenState();
}

class _KimDahaCokScreenState extends State<KimDahaCokScreen> {
  bool _isLoading = true;
  bool _hasData = false;
  String? _errorMessage;

  Map<String, dynamic>? _stats;
  String? _summary;
  String? _startDate;
  String? _endDate;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final result = await RelationshipStatsService.getStats();
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _hasData = true;
          _stats = result['stats'] as Map<String, dynamic>?;
          _summary = result['summary'] as String?;
          final range = result['dateRange'] as Map<String, dynamic>?;
          _startDate = range?['startDate'] as String?;
          _endDate = range?['endDate'] as String?;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        // success: false → muhtemelen hiç data yok
        setState(() {
          _hasData = false;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      var msg = 'Veriler yüklenirken bir hata oluştu.';
      final text = e.toString();

      if (text.contains('404') || text.contains('bulunamadı')) {
        msg =
            'Backend servisi henüz deploy edilmemiş.\n\nLütfen önce:\n1. cd functions\n2. firebase deploy --only functions';
      } else if (text.contains('zaman aşımı')) {
        msg =
            'Sunucu yanıt vermiyor.\n\nLütfen internet bağlantınızı kontrol edin.';
      } else if (text.contains('Kullanıcı')) {
        msg = 'Oturum hatası.\n\nLütfen yeniden giriş yapın.';
      }

      setState(() {
        _hasData = false;
        _isLoading = false;
        _errorMessage = msg;
      });

      // Debug log
      // ignore: avoid_print
      print('❌ Error loading stats: $e');
    }
  }

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
                _buildAppBar(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _hasData
                          ? _buildStatsContent()
                          : _buildEmptyState(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── APP BAR ─────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SyraColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SyraColors.border.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: SyraColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Kim Daha Çok?',
            style: TextStyle(
              color: SyraColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── LOADING STATE ─────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(SyraColors.accent),
          ),
          SizedBox(height: 16),
          Text(
            'İstatistikler yükleniyor...',
            style: TextStyle(
              color: SyraColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── EMPTY / ERROR STATE ─────────────────────

  Widget _buildEmptyState() {
    final hasError = _errorMessage != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SyraColors.accent.withOpacity(0.2),
                    SyraColors.accent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.info_outline,
                color: SyraColors.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasError ? 'Bir Hata Oluştu' : 'Henüz İstatistik Yok',
              style: const TextStyle(
                color: SyraColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasError
                  ? _errorMessage!
                  : 'Bu modu kullanmak için önce Relationship Upload ile bir sohbet yüklemen gerekiyor.',
              style: TextStyle(
                color: SyraColors.textSecondary.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SyraColors.accent, SyraColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────── MAIN CONTENT ─────────────────────

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_summary != null) ...[
            _buildSummaryCard(),
            const SizedBox(height: 16),
          ],
          _buildStatCard(
            title: 'Kim daha çok mesaj atmış?',
            stat: _stats?['whoSentMoreMessages'] ?? 'balanced',
            icon: Icons.message_outlined,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: 'Kim daha çok "seni seviyorum" demiş?',
            stat: _stats?['whoSaidILoveYouMore'] ?? 'none',
            icon: Icons.favorite_border,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: 'Kim daha çok özür dilemiş?',
            stat: _stats?['whoApologizedMore'] ?? 'none',
            icon: Icons.emoji_emotions_outlined,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            title: 'Kim daha çok emoji kullanmış?',
            stat: _stats?['whoUsedMoreEmojis'] ?? 'none',
            icon: Icons.sentiment_satisfied_alt_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SyraColors.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SyraColors.border.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    color: SyraColors.accent,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Özet',
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _summary ?? '',
                style: TextStyle(
                  color: SyraColors.textSecondary.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (_startDate != null && _endDate != null) ...[
                const SizedBox(height: 12),
                Text(
                  '$_startDate - $_endDate',
                  style: TextStyle(
                    color: SyraColors.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String stat,
    required IconData icon,
  }) {
    final displayText = _getDisplayText(stat);
    final displayColor = _getDisplayColor(stat);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SyraColors.surface.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SyraColors.border.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      displayColor.withOpacity(0.2),
                      displayColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: displayColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: SyraColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayText,
                      style: TextStyle(
                        color: displayColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayText(String stat) {
    switch (stat) {
      case 'user':
        return 'Sen';
      case 'partner':
        return 'Karşı taraf';
      case 'balanced':
        return 'Dengeli';
      case 'none':
        return 'Tespit edilemedi';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getDisplayColor(String stat) {
    switch (stat) {
      case 'user':
        return SyraColors.accent;
      case 'partner':
        return Colors.purple;
      case 'balanced':
        return Colors.teal;
      case 'none':
      default:
        return SyraColors.textSecondary;
    }
  }
}
