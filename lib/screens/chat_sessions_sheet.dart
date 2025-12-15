import 'package:flutter/material.dart';

import '../models/chat_session.dart';
import '../theme/syra_theme.dart';

/// Chat sessions picker content for `SyraBottomPanel.show(...)`.
/// - Content only (NO SyraBottomPanel inside)
/// - No dummy/mock data
class ChatSessionsSheet extends StatelessWidget {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final VoidCallback onNewChat;
  final ValueChanged<String> onSelectSession;
  final VoidCallback? onRefresh;

  const ChatSessionsSheet({
    super.key,
    required this.sessions,
    required this.onNewChat,
    required this.onSelectSession,
    this.currentSessionId,
    this.onRefresh,
  });

  String _subtitle(ChatSession s) {
    final last = (s.lastMessage ?? '').trim();
    if (last.isNotEmpty) return last;
    if (s.messageCount > 0) return '${s.messageCount} mesaj';
    return 'Henüz mesaj yok';
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    if (diff.inDays < 7) return '${diff.inDays} g';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Text(
                'Sohbet Geçmişi',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onRefresh != null)
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded,
                    color: SyraColors.iconStroke),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (sessions.isEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SyraColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SyraColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.history_rounded, color: SyraColors.textSecondary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Henüz kayıtlı sohbet yok.\nYeni bir sohbet başlatabilirsin.',
                    style: TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sessions.length,
              separatorBuilder: (_, __) => Divider(
                color: SyraColors.divider.withOpacity(0.6),
                height: 1,
              ),
              itemBuilder: (context, i) {
                final s = sessions[i];
                final isSelected = s.id == currentSessionId;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: SyraColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? SyraColors.accent : SyraColors.border,
                      ),
                    ),
                    child: const Icon(Icons.chat_bubble_rounded,
                        color: SyraColors.accent, size: 18),
                  ),
                  title: Text(
                    s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _subtitle(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    _timeLabel(s.lastUpdatedAt),
                    style: const TextStyle(
                      color: SyraColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSelectSession(s.id);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // New chat button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SyraColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(context);
              onNewChat();
            },
            child: const Text(
              'Yeni Sohbet Başlat',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
