import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIDE MENU v2.0 – ChatGPT 2025 Style
/// Clean, minimal drawer with proper sections
/// ═══════════════════════════════════════════════════════════════

class SideMenu extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final bool isPremium;

  final VoidCallback onTapPremium;
  final VoidCallback onTapChatSessions;
  final VoidCallback onTapTactical;
  final VoidCallback onTapAnalysis;
  final VoidCallback onTapArchive;
  final VoidCallback onTapDailyTip;
  final VoidCallback onTapSettings;
  final VoidCallback onTapLogout;

  const SideMenu({
    super.key,
    required this.slideAnimation,
    required this.isPremium,
    required this.onTapPremium,
    required this.onTapChatSessions,
    required this.onTapTactical,
    required this.onTapAnalysis,
    required this.onTapArchive,
    required this.onTapDailyTip,
    required this.onTapSettings,
    required this.onTapLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? "Misafir";

    return SlideTransition(
      position: slideAnimation,
      child: SafeArea(
        child: Container(
          width: 300,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: SyraColors.background,
            border: Border(
              right: BorderSide(
                color: SyraColors.divider,
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────────────────────
              // HEADER - SYRA Logo + User Info
              // ─────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: SyraColors.divider,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Text(
                          "SYRA",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: SyraColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isPremium
                                ? SyraColors.accent.withOpacity(0.2)
                                : SyraColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isPremium
                                  ? SyraColors.accent.withOpacity(0.4)
                                  : SyraColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            isPremium ? "Plus" : "Free",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPremium
                                  ? SyraColors.accent
                                  : SyraColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "İlişki Danışmanın",
                      style: TextStyle(
                        fontSize: 12,
                        color: SyraColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─────────────────────────────────────────────────────
              // PREMIUM BUTTON
              // ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: onTapPremium,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isPremium
                          ? SyraColors.surface
                          : SyraColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      border: isPremium
                          ? Border.all(color: SyraColors.border)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPremium
                              ? Icons.settings_rounded
                              : Icons.workspace_premium_rounded,
                          color: isPremium
                              ? SyraColors.textSecondary
                              : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPremium ? "Premium Yönetimi" : "SYRA Plus'a Geç",
                          style: TextStyle(
                            color: isPremium
                                ? SyraColors.textPrimary
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─────────────────────────────────────────────────────
              // MAIN MENU ITEMS
              // ─────────────────────────────────────────────────────
              _buildSectionTitle("Sohbet"),
              _SideMenuItem(
                icon: Icons.chat_bubble_outline_rounded,
                text: "Sohbetler",
                onTap: onTapChatSessions,
              ),

              const SizedBox(height: 16),

              _buildSectionTitle("Analiz"),
              _SideMenuItem(
                icon: Icons.psychology_outlined,
                text: "İlişki Analizi",
                subtitle: "Derin psikolojik analiz",
                onTap: onTapAnalysis,
              ),
              _SideMenuItem(
                icon: Icons.flash_on_outlined,
                text: "Tactical Moves",
                subtitle: "Strateji ve taktikler",
                onTap: onTapTactical,
              ),
              _SideMenuItem(
                icon: Icons.bookmark_outline_rounded,
                text: "Konuşma Arşivi",
                onTap: onTapArchive,
              ),
              _SideMenuItem(
                icon: Icons.lightbulb_outline_rounded,
                text: "Günlük Tavsiye",
                onTap: onTapDailyTip,
              ),

              const SizedBox(height: 16),

              _buildSectionTitle("Ayarlar"),
              _SideMenuItem(
                icon: Icons.settings_outlined,
                text: "Uygulama Ayarları",
                onTap: onTapSettings,
              ),

              const Spacer(),

              // ─────────────────────────────────────────────────────
              // BOTTOM - User & Logout
              // ─────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: SyraColors.divider,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // User info
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SyraColors.surface,
                            border: Border.all(
                              color: SyraColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: SyraColors.textMuted,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            email,
                            style: TextStyle(
                              color: SyraColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onTapLogout,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.logout_rounded,
                              color: SyraColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Version
                    Text(
                      "SYRA v2.0",
                      style: TextStyle(
                        color: SyraColors.textHint,
                        fontSize: 11,
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

  Widget _buildSectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: SyraColors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// MENU ITEM WIDGET
class _SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtitle;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.icon,
    required this.text,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: SyraColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        color: SyraColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: SyraColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SyraColors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
