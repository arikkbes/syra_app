import 'package:flutter/material.dart';
import '../models/chat_session.dart';
import '../theme/syra_theme.dart';

class ChatSessionsSheet extends StatelessWidget {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final Function(String) onSessionSelected;

  const ChatSessionsSheet({
    super.key,
    required this.sessions,
    this.currentSessionId,
    required this.onSessionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SyraColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Sohbet Geçmişi",
              style: TextStyle(
                color: SyraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sessions list
          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'Henüz sohbet yok',
                style: TextStyle(
                  color: SyraColors.textMuted,
                  fontSize: 14,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final isSelected = session.id == currentSessionId;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSessionSelected(session.id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SyraColors.accent.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: isSelected
                                  ? SyraColors.accent
                                  : SyraColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.title,
                                    style: TextStyle(
                                      color: SyraColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (session.lastMessage != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      session.lastMessage!,
                                      style: const TextStyle(
                                        color: SyraColors.textMuted,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check,
                                color: SyraColors.accent,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
