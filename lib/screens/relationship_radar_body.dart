// lib/screens/relationship_radar_body.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../models/relationship_analysis_result.dart';
import '../models/relationship_memory.dart';
import '../theme/design_system.dart';
import '../services/relationship_stats_service.dart';
import '../services/relationship_memory_service.dart';
import '../utils/subscription_flow.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP RADAR BODY
/// ═══════════════════════════════════════════════════════════════
/// Unified full-screen body for ChatScreen that displays:
/// 1. Optional Scoreboard (Kim Daha Çok) - async loaded, can fail
/// 2. Detailed Analysis blocks - always rendered from memory
/// ═══════════════════════════════════════════════════════════════

class RelationshipRadarBody extends StatefulWidget {
  final RelationshipMemory memory;
  final VoidCallback onMenuTap;

  const RelationshipRadarBody({
    super.key,
    required this.memory,
    required this.onMenuTap,
  });

  @override
  State<RelationshipRadarBody> createState() => _RelationshipRadarBodyState();
}

class _RelationshipRadarBodyState extends State<RelationshipRadarBody> {
  // Scoreboard state
  bool _isStatsLoading = true;
  bool _hasStatsError = false;
  String? _statsErrorMessage;
  Map<String, dynamic>? _stats;
  String? _statsSummary;
  String? _statsStartDate;
  String? _statsEndDate;
  String _statsPlan = 'free';
  String _statsAccess = 'full';
  List<String> _lockedKeys = const [];
  String? _statsAccessMessage;

  // Participant selection state
  String? _selectedParticipant;
  bool _isUpdatingParticipant = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected participant from synced state
    _initializeSelectedParticipant();
    _loadStats();
  }

  Future<void> _initializeSelectedParticipant() async {
    // Get synced selectedSelfParticipant from shared state
    final savedParticipant =
        await RelationshipMemoryService.getSelectedSelfParticipant();

    // Validate: check if saved participant exists in current relationship
    if (savedParticipant != null &&
        widget.memory.speakers.contains(savedParticipant)) {
      setState(() {
        _selectedParticipant = savedParticipant;
      });
      debugPrint('✅ Loaded synced participant: $savedParticipant');
    } else {
      // Fallback to memory.selfParticipant if sync state invalid
      setState(() {
        _selectedParticipant = widget.memory.selfParticipant;
      });
      debugPrint(
        '⚠️ Saved participant invalid, using memory.selfParticipant: ${widget.memory.selfParticipant}',
      );
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() {
      _isStatsLoading = true;
      _hasStatsError = false;
      _statsErrorMessage = null;
    });

    try {
      final result = await RelationshipStatsService.getStats();

      if (!mounted) return;

      if (result['success'] == true) {
        final lockedKeys = (result['lockedKeys'] is List)
            ? (result['lockedKeys'] as List).whereType<String>().toList()
            : <String>[];

        setState(() {
          _stats = result['stats'] as Map<String, dynamic>?;
          _statsSummary = result['summary'] as String?;
          final range = result['dateRange'] as Map<String, dynamic>?;
          _statsStartDate = range?['startDate'] as String?;
          _statsEndDate = range?['endDate'] as String?;
          _statsPlan = result['plan'] is String
              ? result['plan'] as String
              : 'free';
          _statsAccess = result['access'] is String
              ? result['access'] as String
              : 'full';
          _lockedKeys = lockedKeys;
          _statsAccessMessage = result['message'] is String
              ? result['message'] as String
              : null;
          _isStatsLoading = false;
          _hasStatsError = false;
        });
      } else {
        setState(() {
          _isStatsLoading = false;
          _hasStatsError = false;
          _stats = null;
          _statsAccess = 'full';
          _statsPlan = 'free';
          _lockedKeys = const [];
          _statsAccessMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      var msg = 'Veriler yüklenirken bir hata oluştu.';
      final text = e.toString();

      if (text.contains('404') || text.contains('bulunamadı')) {
        msg = 'Servis henüz hazır değil.';
      } else if (text.contains('zaman aşımı')) {
        msg = 'Bağlantı zaman aşımına uğradı.';
      } else if (text.contains('Kullanıcı')) {
        msg = 'Oturum hatası.';
      }

      setState(() {
        _isStatsLoading = false;
        _hasStatsError = true;
        _statsErrorMessage = msg;
        _stats = null;
        _statsAccess = 'full';
        _lockedKeys = const [];
        _statsAccessMessage = null;
      });

      debugPrint('❌ RelationshipRadarBody stats error: $e');
    }
  }

  /// Convert memory to analysis result
  RelationshipAnalysisResult _getAnalysisResult() {
    final mem = widget.memory;
    return RelationshipAnalysisResult(
      relationshipId: mem.id,
      totalMessages: mem.totalMessages ?? 0,
      totalChunks: mem.totalChunks ?? 0,
      speakers: mem.speakers,
      shortSummary: mem.shortSummary ?? '',
      personalities: mem.personalities != null
          ? (mem.personalities! as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                PersonalityProfile.fromJson(value as Map<String, dynamic>),
              ),
            )
          : null,
      dynamics: mem.dynamics != null
          ? RelationshipDynamics.fromJson(mem.dynamics! as Map<String, dynamic>)
          : null,
      patterns: mem.patterns != null
          ? RelationshipPatterns.fromJson(mem.patterns! as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisResult = _getAnalysisResult();
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      color: SyraTokens.background,
      child: Stack(
        children: [
          // Background
          const SyraBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SCOREBOARD SECTION (Optional, can fail)
                        _buildScoreboardSection(),

                        const SizedBox(height: 20),

                        // PARTICIPANT SELECTOR (always show if 2+ speakers)
                        if (widget.memory.speakers.length >= 2)
                          _buildParticipantSelector(),

                        if (widget.memory.speakers.length >= 2)
                          const SizedBox(height: 20),

                        // ANALYSIS SECTION (Always rendered)
                        _buildStatsCard(analysisResult),
                        const SizedBox(height: 16),
                        _buildSummaryCard(analysisResult),
                        if (analysisResult.personalities != null &&
                            analysisResult.personalities!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildPersonalitiesCard(analysisResult),
                        ],
                        if (analysisResult.dynamics != null) ...[
                          const SizedBox(height: 16),
                          _buildDynamicsCard(analysisResult),
                        ],
                        if (analysisResult.patterns != null) ...[
                          const SizedBox(height: 16),
                          _buildPatternsCard(analysisResult),
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

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: SyraTokens.background.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(color: SyraTokens.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Hamburger menu button (same as chat screen)
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onMenuTap();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  color: SyraTokens.textSecondary,
                  size: 24,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        color: SyraTokens.accent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "İlişki Radarı",
                        style: TextStyle(
                          color: SyraTokens.textPrimary,
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

  // ═══════════════════════════════════════════════════════════════
  // SCOREBOARD SECTION (Kim Daha Çok)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildScoreboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.withOpacity(0.2),
                    Colors.purple.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.pinkAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kim Daha Çok?',
              style: TextStyle(
                color: SyraTokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Content based on state
        if (_isStatsLoading)
          _buildScoreboardLoading()
        else if (_hasStatsError)
          _buildScoreboardError()
        else if (_stats == null)
          _buildScoreboardNoData()
        else
          _buildScoreboardContent(),
      ],
    );
  }

  Widget _buildScoreboardLoading() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 4, right: 4),
        itemCount: 4, // 4 skeleton cards
        itemBuilder: (context, index) {
          final isFirst = index == 0;
          final isLast = index == 3;

          return Padding(
            padding: EdgeInsets.only(
              left: isFirst ? 0 : 8,
              right: isLast ? 0 : 8,
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: _GlassCard(
                padding: const EdgeInsets.all(16),
                child: Shimmer.fromColors(
                  baseColor: SyraTokens.surface,
                  highlightColor: SyraTokens.surfaceLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 80,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreboardError() {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kim Daha Çok verisi hazır değil',
                      style: TextStyle(
                        color: SyraTokens.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statsErrorMessage ?? 'Bir hata oluştu',
                      style: TextStyle(
                        color: SyraTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _loadStats,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: SyraTokens.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SyraTokens.border.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: SyraTokens.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tekrar Dene',
                    style: TextStyle(
                      color: SyraTokens.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboardNoData() {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SyraTokens.textMuted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              color: SyraTokens.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Henüz yeterli veri yok.\nDaha fazla sohbet yüklendikçe istatistikler görünecek.',
              style: TextStyle(
                color: SyraTokens.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboardContent() {
    final isTeaser = _statsAccess == 'teaser' || _lockedKeys.isNotEmpty;
    final teaserMessage =
        (_statsAccessMessage != null && _statsAccessMessage!.trim().isNotEmpty)
        ? _statsAccessMessage!
        : 'Kim Daha Çok’un tamamı CORE/PLUS’ta açık kanka. Şimdilik küçük bir ön izleme bıraktım.';

    // Prepare stat cards data
    final statCards = [
      {
        'title': 'Kim daha çok mesaj atmış?',
        'stat': _stats?['whoSentMoreMessages'] ?? 'none',
        'icon': Icons.message_outlined,
        'key': 'whoSentMoreMessages',
      },
      {
        'title': 'Kim daha çok "seni seviyorum" demiş?',
        'stat': _stats?['whoSaidILoveYouMore'] ?? 'none',
        'icon': Icons.favorite_border,
        'key': 'whoSaidILoveYouMore',
      },
      {
        'title': 'Kim daha çok özür dilemiş?',
        'stat': _stats?['whoApologizedMore'] ?? 'none',
        'icon': Icons.emoji_emotions_outlined,
        'key': 'whoApologizedMore',
      },
      {
        'title': 'Kim daha çok emoji kullanmış?',
        'stat': _stats?['whoUsedMoreEmojis'] ?? 'none',
        'icon': Icons.sentiment_satisfied_alt_outlined,
        'key': 'whoUsedMoreEmojis',
      },
    ];

    return Column(
      children: [
        // Summary card if available
        if (_statsSummary != null && _statsSummary!.isNotEmpty) ...[
          _GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      color: SyraTokens.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Özet',
                      style: TextStyle(
                        color: SyraTokens.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _statsSummary!,
                  style: TextStyle(
                    color: SyraTokens.textSecondary.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (_statsStartDate != null && _statsEndDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$_statsStartDate - $_statsEndDate',
                    style: TextStyle(color: SyraTokens.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Horizontal carousel of stat cards
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 4, right: 4),
            itemCount: statCards.length,
            itemBuilder: (context, index) {
              final card = statCards[index];
              final isFirst = index == 0;
              final isLast = index == statCards.length - 1;

              return Padding(
                padding: EdgeInsets.only(
                  left: isFirst ? 0 : 8,
                  right: isLast ? 0 : 8,
                ),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.75,
                  child: _buildScoreboardStatCard(
                    title: card['title'] as String,
                    stat: card['stat'] as String,
                    icon: card['icon'] as IconData,
                    isLocked:
                        (card['stat'] as String) == 'locked' ||
                        _lockedKeys.contains(card['key'] as String),
                  ),
                ),
              );
            },
          ),
        ),
        if (isTeaser) ...[
          const SizedBox(height: 12),
          _GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: SyraTokens.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        teaserMessage,
                        style: const TextStyle(
                          color: SyraTokens.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _openPremiumManagement,
                    icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                    label: const Text("CORE'a gec"),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: SyraTokens.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreboardStatCard({
    required String title,
    required String stat,
    required IconData icon,
    required bool isLocked,
  }) {
    if (isLocked) {
      return _GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SyraTokens.textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: SyraTokens.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: SyraTokens.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kilitli',
                    style: TextStyle(
                      color: SyraTokens.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final displayText = _getStatDisplayText(stat);
    final displayColor = _getStatDisplayColor(stat);

    // Hide card if no meaningful data
    if (stat == 'none' || stat.isEmpty) {
      return _GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SyraTokens.textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: SyraTokens.textMuted, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: SyraTokens.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Veri yetersiz',
                    style: TextStyle(
                      color: SyraTokens.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
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
            child: Icon(icon, color: displayColor, size: 24),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            title,
            style: const TextStyle(
              color: SyraTokens.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Result
          Text(
            displayText,
            style: TextStyle(
              color: displayColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatDisplayText(String stat) {
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
        return stat.isNotEmpty ? stat : 'Bilinmiyor';
    }
  }

  Color _getStatDisplayColor(String stat) {
    switch (stat) {
      case 'user':
        return SyraTokens.accent;
      case 'partner':
        return Colors.purple;
      case 'balanced':
        return Colors.teal;
      case 'none':
      default:
        return SyraTokens.textSecondary;
    }
  }

  void _openPremiumManagement() {
    openPaywallSheet(context, initialTab: SubscriptionTab.core);
  }

  // ═══════════════════════════════════════════════════════════════
  // PARTICIPANT SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildParticipantSelector() {
    final speakers = widget.memory.speakers;
    final hasPartner = speakers.length == 2;

    return _GlassCard(
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
                      SyraTokens.accent.withOpacity(0.2),
                      SyraTokens.accent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: SyraTokens.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sen kimsin?',
                      style: TextStyle(
                        color: SyraTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'İstatistiklerde "Sen" olarak görünmen için seç',
                      style: TextStyle(
                        color: SyraTokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: speakers.map((speaker) {
              final isSelected = _selectedParticipant == speaker;
              final isPartner =
                  hasPartner &&
                  _selectedParticipant != null &&
                  speaker != _selectedParticipant;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: speakers.last == speaker ? 0 : 8,
                  ),
                  child: _buildParticipantCard(
                    speaker: speaker,
                    isSelected: isSelected,
                    isPartner: isPartner,
                    onTap: _isUpdatingParticipant
                        ? null
                        : () => _selectSelfParticipant(speaker),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard({
    required String speaker,
    required bool isSelected,
    required bool isPartner,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SyraTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SyraTokens.accent
                : SyraTokens.border.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SyraTokens.accent.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Check icon for selected state
            if (isSelected)
              Positioned(
                top: -10,
                left: -12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: SyraTokens.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),

            // Main content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  speaker,
                  style: TextStyle(
                    color: isSelected
                        ? SyraTokens.accent
                        : SyraTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (isSelected || isPartner) ...[
                  const SizedBox(height: 4),
                  Text(
                    isSelected ? 'Sen' : 'Karşı taraf',
                    style: TextStyle(
                      color: isSelected
                          ? SyraTokens.accent.withOpacity(0.8)
                          : SyraTokens.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectSelfParticipant(String speaker) async {
    // Don't allow selection if already updating
    if (_isUpdatingParticipant) return;

    // Don't reselect the same participant
    if (_selectedParticipant == speaker) return;

    // Store previous selection for rollback
    final previousSelection = _selectedParticipant;

    try {
      // Optimistic update - update UI immediately
      setState(() {
        _selectedParticipant = speaker;
        _isUpdatingParticipant = true;
      });

      final speakers = widget.memory.speakers;
      String? partner;

      if (speakers.length == 2) {
        partner = speakers.firstWhere((s) => s != speaker);
      }

      debugPrint('🔍 Selecting participant: $speaker');
      debugPrint('🔍 Partner: $partner');
      debugPrint('🔍 Relationship ID: ${widget.memory.id}');

      final success = await RelationshipMemoryService.updateParticipants(
        selfParticipant: speaker,
        partnerParticipant: partner,
        relationshipId: widget.memory.id,
      );

      if (!mounted) return;

      setState(() {
        _isUpdatingParticipant = false;
      });

      debugPrint('✅ Update result: $success');

      if (success) {
        // Reload stats to get updated user/partner labels
        _loadStats();

        // Show success feedback
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('✓ "$speaker" olarak seçildin')),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: SyraTokens.accent.withOpacity(0.9),
          ),
        );
      } else {
        // Rollback to previous selection
        setState(() {
          _selectedParticipant = previousSelection;
        });

        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Seçim kaydedilemedi. Lütfen tekrar deneyin.'),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.withOpacity(0.9),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Participant selection error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;

      // Rollback on error
      setState(() {
        _selectedParticipant = previousSelection;
        _isUpdatingParticipant = false;
      });

      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Hata: ${e.toString()}')),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.withOpacity(0.9),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ANALYSIS CARDS (Always rendered from memory)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsCard(RelationshipAnalysisResult result) {
    return _GlassCard(
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
                      SyraTokens.accent.withOpacity(0.2),
                      SyraTokens.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: SyraTokens.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sohbet İstatistikleri',
                style: TextStyle(
                  color: SyraTokens.textPrimary,
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
            value: '${result.totalMessages}',
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.folder_outlined,
            label: 'Analiz Edilen Dönem',
            value: '${result.totalChunks} parça',
          ),
          if (result.speakers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.people_outline_rounded,
              label: 'Konuşmacılar',
              value: result.speakers.join(' & '),
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
        Icon(icon, color: SyraTokens.textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: SyraTokens.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: SyraTokens.textPrimary,
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

  Widget _buildSummaryCard(RelationshipAnalysisResult result) {
    return _GlassCard(
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
                      SyraTokens.accent.withOpacity(0.2),
                      SyraTokens.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: SyraTokens.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Genel Özet',
                style: TextStyle(
                  color: SyraTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.shortSummary.isNotEmpty
                ? result.shortSummary
                : 'Özet mevcut değil.',
            style: const TextStyle(
              color: SyraTokens.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitiesCard(RelationshipAnalysisResult result) {
    return _GlassCard(
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
                      SyraTokens.accent.withOpacity(0.2),
                      SyraTokens.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: SyraTokens.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kişilik Profilleri',
                style: TextStyle(
                  color: SyraTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...result.personalities!.entries.map((entry) {
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
        color: SyraTokens.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraTokens.border.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: SyraTokens.accent,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: SyraTokens.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trait,
                    style: const TextStyle(
                      color: SyraTokens.textPrimary,
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
                color: SyraTokens.textSecondary.withOpacity(0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDynamicsCard(RelationshipAnalysisResult result) {
    final dynamics = result.dynamics!;

    return _GlassCard(
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
                      SyraTokens.accent.withOpacity(0.2),
                      SyraTokens.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sync_alt_rounded,
                  color: SyraTokens.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'İlişki Dinamikleri',
                style: TextStyle(
                  color: SyraTokens.textPrimary,
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
        Icon(icon, color: SyraTokens.textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: SyraTokens.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: SyraTokens.textPrimary,
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

  Widget _buildPatternsCard(RelationshipAnalysisResult result) {
    final patterns = result.patterns!;

    return _GlassCard(
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
                      SyraTokens.accent.withOpacity(0.2),
                      SyraTokens.accent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pattern_rounded,
                  color: SyraTokens.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Örüntüler',
                style: TextStyle(
                  color: SyraTokens.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (patterns.strengths.isNotEmpty) ...[
            _buildPatternSection(
              '💚 Güçlü Yanlar',
              patterns.strengths,
              Colors.green,
            ),
            const SizedBox(height: 16),
          ],
          if (patterns.recurringIssues.isNotEmpty) ...[
            _buildPatternSection(
              '⚠️ Tekrar Eden Sorunlar',
              patterns.recurringIssues,
              Colors.orange,
            ),
            const SizedBox(height: 16),
          ],
          if (patterns.redFlags.isNotEmpty) ...[
            _buildPatternSection(
              '🚩 Kırmızı Bayraklar',
              patterns.redFlags,
              Colors.red,
            ),
          ],
          if (patterns.greenFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPatternSection(
              '✅ Yeşil Bayraklar',
              patterns.greenFlags,
              Colors.green,
            ),
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
            color: SyraTokens.textPrimary,
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
                      color: SyraTokens.textSecondary.withOpacity(0.9),
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
}

// ═══════════════════════════════════════════════════════════════
// GLASS CARD WIDGET
// ═══════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SyraTokens.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SyraTokens.border.withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
