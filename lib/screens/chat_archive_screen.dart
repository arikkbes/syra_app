import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHAT ARCHIVE SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Konuşma arşivi - Dummy verilerle iskelet.
/// ═══════════════════════════════════════════════════════════════

class ChatArchiveScreen extends StatelessWidget {
  const ChatArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> archivedChats = [
      {
        "title": "İlk buluşma tavsiyeleri",
        "preview": "Buluşmadan önce neler yapmalıyım...",
        "date": "15 Kas 2024",
        "messageCount": 24,
        "icon": Icons.favorite_rounded,
        "color": const Color(0xFFFF6B9D),
      },
      {
        "title": "Mesajlaşma stratejisi",
        "preview": "Ne zaman yazmalıyım, ne kadar beklemeliyim...",
        "date": "12 Kas 2024",
        "messageCount": 18,
        "icon": Icons.chat_rounded,
        "color": const Color(0xFF64B5F6),
      },
      {
        "title": "İlişki analizi - Ayşe",
        "preview": "Son konuşmamızı analiz edelim...",
        "date": "8 Kas 2024",
        "messageCount": 32,
        "icon": Icons.psychology_rounded,
        "color": const Color(0xFFB388FF),
      },
      {
        "title": "Red flag kontrolü",
        "preview": "Bu davranışlar normal mi...",
        "date": "3 Kas 2024",
        "messageCount": 15,
        "icon": Icons.flag_rounded,
        "color": const Color(0xFFFFD54F),
      },
    ];

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
                        _buildInfoBanner(),
                        const SizedBox(height: 20),
                        ...archivedChats.map((chat) => Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: _buildArchiveItem(context, chat),
                            )),
                        const SizedBox(height: 20),
                        _buildComingSoonNote(),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
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
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        color: Color(0xFF00D4FF),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Konuşma Arşivi",
                        style: TextStyle(
                          color: Colors.white,
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

  Widget _buildInfoBanner() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.archive_rounded,
              color: Color(0xFF00D4FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Arşivlenmiş Sohbetler",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Önemli konuşmalarını burada sakla ve istediğin zaman geri dön.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveItem(BuildContext context, Map<String, dynamic> chat) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (chat["color"] as Color).withValues(alpha: 0.15),
            ),
            child: Icon(
              chat["icon"] as IconData,
              color: chat["color"] as Color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat["title"] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chat["preview"] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chat["date"] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${chat["messageCount"]} mesaj",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Gerçek arşiv Firestore bağlantısı ile SYRA 1.1'de gelecek.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
