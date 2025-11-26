import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/syra_theme.dart';
import '../widgets/syra_orb.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIDE MENU – Premium v1.1
/// Neon orb avatar + glassmorphism
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
    return SlideTransition(
      position: slideAnimation,
      child: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SyraColors.surface.withOpacity(0.55),
                    SyraColors.surface.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  right: BorderSide(
                    color: SyraColors.glassBorder,
                    width: 0.6,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AVATAR + USER INFO
                  Row(
                    children: [
                      // 🔥 NEW: REAL SYRA ORB AVATAR (idle state)
                      const SyraOrb(
                        state: OrbState.idle,
                        size: 64,
                      ),

                      const SizedBox(width: 14),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kanka",
                            style: TextStyle(
                              color: SyraColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient:
                                  isPremium ? SyraColors.accentGradient : null,
                              color: isPremium ? null : SyraColors.glassBg,
                              border: isPremium
                                  ? null
                                  : Border.all(color: SyraColors.glassBorder),
                            ),
                            child: Text(
                              isPremium ? "SYRA Plus" : "Free Plan",
                              style: TextStyle(
                                color: isPremium
                                    ? Colors.white
                                    : SyraColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // PREMIUM BUTTON
                  GestureDetector(
                    onTap: onTapPremium,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isPremium ? null : SyraColors.accentGradient,
                        color: isPremium ? SyraColors.glassBg : null,
                        border: isPremium
                            ? Border.all(color: SyraColors.glassBorder)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPremium
                                ? Icons.settings_rounded
                                : Icons.workspace_premium_rounded,
                            color:
                                isPremium ? SyraColors.neonCyan : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
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

                  const SizedBox(height: 28),

                  _buildSectionTitle("Modlar"),
                  const SizedBox(height: 12),

                  _SideMenuItem(
                    icon: Icons.forum_rounded,
                    text: "Sohbetler",
                    iconColor: const Color(0xFF64B5F6),
                    onTap: onTapChatSessions,
                  ),
                  _SideMenuItem(
                    icon: Icons.flash_on_rounded,
                    text: "Tactical Moves",
                    iconColor: const Color(0xFFFFD54F),
                    onTap: onTapTactical,
                  ),
                  _SideMenuItem(
                    icon: Icons.psychology_rounded,
                    text: "İlişki Analizi",
                    iconColor: SyraColors.neonViolet,
                    onTap: onTapAnalysis,
                  ),
                  _SideMenuItem(
                    icon: Icons.bookmark_rounded,
                    text: "Konuşma Arşivi",
                    iconColor: SyraColors.neonCyan,
                    onTap: onTapArchive,
                  ),
                  _SideMenuItem(
                    icon: Icons.tips_and_updates_rounded,
                    text: "Günlük Tavsiye",
                    iconColor: SyraColors.neonPink,
                    onTap: onTapDailyTip,
                  ),

                  const SizedBox(height: 28),

                  _buildSectionTitle("Ayarlar"),
                  const SizedBox(height: 12),

                  _SideMenuItem(
                    icon: Icons.settings_rounded,
                    text: "Uygulama Ayarları",
                    iconColor: SyraColors.textSecondary,
                    onTap: onTapSettings,
                  ),

                  const Spacer(),

                  Center(
                    child: Text(
                      "SYRA v1.1",
                      style: TextStyle(
                        color: SyraColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Text(
      label,
      style: TextStyle(
        color: SyraColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }
}

/// ITEM WIDGET
class _SideMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: SyraColors.glassBg,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                text,
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: SyraColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
