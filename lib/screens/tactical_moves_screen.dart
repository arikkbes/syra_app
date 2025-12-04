import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// TACTICAL MOVES SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Tanışma, mesajlaşma ve buluşma taktikleri.
/// ═══════════════════════════════════════════════════════════════

class TacticalMovesScreen extends StatelessWidget {
  const TacticalMovesScreen({super.key});

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
                        _buildInfoCard(),
                        const SizedBox(height: 24),
                        _buildTacticCard(
                          icon: Icons.waving_hand_rounded,
                          iconColor: const Color(0xFF64B5F6),
                          title: "İlk Tanışma",
                          subtitle: "Güçlü bir ilk izlenim bırak",
                          tips: [
                            "Göz teması kur ve samimi gülümse.",
                            "Ortak noktalar bulmaya çalış.",
                            "Kendinden çok karşı tarafı dinle.",
                            "Doğal ol, ezberlenmiş cümlelerden kaçın.",
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTacticCard(
                          icon: Icons.chat_bubble_rounded,
                          iconColor: const Color(0xFFFF6B9D),
                          title: "Mesajlaşma Taktikleri",
                          subtitle: "Yazışmalarda fark yarat",
                          tips: [
                            "Hemen cevap verme, biraz beklet.",
                            "Soru sor ama sorgu haline getirme.",
                            "Emoji kullan ama abartma.",
                            "Gizemini koru, her şeyi anlatma.",
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTacticCard(
                          icon: Icons.local_cafe_rounded,
                          iconColor: const Color(0xFFFFD54F),
                          title: "Buluşma Stratejileri",
                          subtitle: "Yüz yüze anı değerlendir",
                          tips: [
                            "Aktivite bazlı buluşmalar planla.",
                            "İlk buluşmayı kısa tut.",
                            "Telefonuna bakma, ona odaklan.",
                            "Buluşma sonrası aynı gün yaz.",
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTacticCard(
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFB388FF),
                          title: "İlişki Yönetimi",
                          subtitle: "Dengeli bir ilişki kur",
                          tips: [
                            "Kendi hayatını yaşamaya devam et.",
                            "Sınırlarını net koy.",
                            "Takdir et ama dalkavukluk yapma.",
                            "Sorunları zamanında konuş.",
                          ],
                        ),
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
                        Icons.flash_on_rounded,
                        color: Color(0xFFFFD54F),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Tactical Moves",
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

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                  const Color(0xFF00D4FF).withValues(alpha: 0.3),
                ],
              ),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFFFD54F),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Stratejik Hamle Rehberin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Her aşama için kanıtlanmış taktikler. Oyunu akıllıca oyna.",
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

  Widget _buildTacticCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> tips,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.15),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
