import 'package:flutter/material.dart';

/// SYRA Chat Sessions – multi-chat iskeleti
/// Şu an:
/// • Dummy chat listesi
/// • Yeni sohbet başlat butonu
/// • Seçimlerde sadece SnackBar gösteriyor
/// Sonraki partlarda:
/// • Gerçek chat ID'leri
/// • Firestore'dan chat listesi
/// • Seçilen odaya geçiş
/// eklenecek.

class ChatSessionsSheet extends StatelessWidget {
  const ChatSessionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyChats = [
      "Ayşe (3 gün önce)",
      "Sıla (2 saat önce)",
      "Genel flört taktikleri",
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Sohbet Odaların",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Dummy chat listesi
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: dummyChats.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final title = dummyChats[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.blueAccent,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      "Multi-chat iskeleti, backend sonra bağlanacak.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "\"$title\" odası seçildi (iskelet). Gerçek odalar sonraki partta.",
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.black.withValues(alpha: 0.9),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Yeni sohbet butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Yeni sohbet iskeleti hazır. Gerçek oda oluşturma sonraki partta.",
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFF00D4FF)],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Yeni Sohbet Başlat",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
