import 'dart:ui';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final bool isPremium;

  final VoidCallback onTapPremium;
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
            topRight: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: 290,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------------------------
                  // PROFILE AREA
                  // -------------------------------------
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kanka",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPremium ? "SYRA Plus" : "Free User",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // -------------------------------------
                  // PREMIUM BUTTON
                  // -------------------------------------
                  if (!isPremium)
                    GestureDetector(
                      onTap: onTapPremium,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF3B6F),
                              Color(0xFFFF7AB8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B6F).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "SYRA Plus’a Geç",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (!isPremium) const SizedBox(height: 28),

                  // -------------------------------------
                  // SECTIONS: MODLAR
                  // -------------------------------------
                  Text(
                    "Modlar",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SideMenuItem(
                    icon: Icons.flash_on_rounded,
                    text: "Tactical Moves",
                    onTap: onTapTactical,
                  ),
                  _SideMenuItem(
                    icon: Icons.analytics_rounded,
                    text: "İlişki Analizi",
                    onTap: onTapAnalysis,
                  ),
                  _SideMenuItem(
                    icon: Icons.bookmark_rounded,
                    text: "Konuşma Arşivi",
                    onTap: onTapArchive,
                  ),
                  _SideMenuItem(
                    icon: Icons.tips_and_updates_rounded,
                    text: "Günlük Tavsiye",
                    onTap: onTapDailyTip,
                  ),

                  const SizedBox(height: 28),

                  // -------------------------------------
                  // SECTIONS: AYARLAR
                  // -------------------------------------
                  Text(
                    "Ayarlar",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _SideMenuItem(
                    icon: Icons.settings_rounded,
                    text: "Uygulama Ayarları",
                    onTap: onTapSettings,
                  ),

                  const Spacer(),

                  // -------------------------------------
                  // LOGOUT KALDIRILDI
                  // Çıkış sadece SettingsScreen içinden.
                  // -------------------------------------
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.95), size: 22),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
