import 'package:flutter/material.dart';

/// SYRA Chat Behavior Screen – iskelet
/// Buradaki ayarlar sadece UI tarafında tutuluyor.
/// İleride Firestore + backend ile kalıcı hale getirilecek.

class ChatBehaviorScreen extends StatefulWidget {
  const ChatBehaviorScreen({super.key});

  @override
  State<ChatBehaviorScreen> createState() => _ChatBehaviorScreenState();
}

class _ChatBehaviorScreenState extends State<ChatBehaviorScreen> {
  String _tone = "Otomatik";
  String _replyLength = "Dengeli";
  bool _streetMode = true;
  bool _emotionalHints = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sohbet Davranışı"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Buradaki ayarlar SYRA'nın sana nasıl konuşacağını etkiler.\n"
              "Şu an sadece bu cihazda geçerli, ileride hesap bazlı saklanacak.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // TON SEÇİMİ
            _buildSectionTitle("Konuşma tonu"),
            const SizedBox(height: 8),
            _buildDropdownTile(
              value: _tone,
              items: const [
                "Otomatik",
                "Kanka modu",
                "Sakin analizci",
                "Maskülen mentor",
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _tone = v);
              },
              subtitle:
                  "SYRA'nın sana yaklaşım tarzını seç. Otomatikte mesajına göre karar verir.",
            ),

            const SizedBox(height: 20),

            // MESAJ UZUNLUĞU
            _buildSectionTitle("Mesaj uzunluğu"),
            const SizedBox(height: 8),
            _buildDropdownTile(
              value: _replyLength,
              items: const [
                "Kısa & net",
                "Dengeli",
                "Detaylı açıklama",
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _replyLength = v);
              },
              subtitle: "Cevapların ne kadar uzun olmasını istediğini seç.",
            ),

            const SizedBox(height: 20),

            // STREET MODE
            _buildSectionTitle("Sokak modu"),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _streetMode,
              onChanged: (v) {
                setState(() => _streetMode = v);
              },
              title: const Text(
                "Street / kanka dili",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Ağzı daha kanka, daha sokak, daha samimi olsun.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              activeThumbColor: Colors.blueAccent,
            ),

            const SizedBox(height: 12),

            // EMOTIONAL HINTS
            SwitchListTile(
              value: _emotionalHints,
              onChanged: (v) {
                setState(() => _emotionalHints = v);
              },
              title: const Text(
                "Duygusal analiz cümleleri",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Mesajlara yorum yaparken araya 'bence burada kız trip atmış' gibi "
                "duygusal yorumlar serpiştirsin.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              activeThumbColor: Colors.blueAccent,
            ),

            const SizedBox(height: 24),
            const Text(
              "Not: Bu ekran şu an sadece iskelet. Değerler henüz Firestore'a "
              "yazılmıyor, backend ile bağlayınca gerçek etkiyi kazanacak.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white38,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: Colors.white70,
              ),
              dropdownColor: Colors.grey.shade900,
              style: const TextStyle(color: Colors.white),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
