import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// ARCHIVED CHATS SCREEN
/// Simple placeholder screen for archived conversations
/// ═══════════════════════════════════════════════════════════════
class ArchivedChatsScreen extends StatelessWidget {
  const ArchivedChatsScreen({super.key});

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
          'Archived Chats',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: SyraColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: SyraColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SyraColors.border,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.archive_outlined,
                  size: 36,
                  color: SyraColors.iconStroke,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No archived chats yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SyraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Conversations you archive will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: SyraColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SyraColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SyraColors.border,
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
                        'Archive chats to keep them private but still accessible.',
                        style: TextStyle(
                          fontSize: 13,
                          color: SyraColors.textSecondary,
                        ),
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
}
