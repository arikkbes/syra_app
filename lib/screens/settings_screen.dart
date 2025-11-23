import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_user.dart';
import 'chat_screen.dart';
import 'premium_management_screen.dart';
import 'premium_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPremium = false;
  String _email = "";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _email = user.email ?? "";
      _isPremium = await FirestoreUser.isPremium();
      if (mounted) setState(() {});
    }
  }

  // -----------------------------------------------------------
  // MESAJ SİL – DÜZELTİLMİŞ VERSİYON ✅
  // -----------------------------------------------------------
  Future<void> _clearChatHistory() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text("Emin misin?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Tüm mesaj geçmişini silmek istediğine emin misin?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Sil", style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ DOĞRU COLLECTION - Backend'deki conversation_history
        await FirebaseFirestore.instance
            .collection("conversation_history")
            .doc(user.uid)
            .delete();

        // ✅ User messages subcollection'ını da temizle (varsa)
        final messagesCollection = FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("messages");

        final docs = await messagesCollection.get();
        for (var d in docs.docs) {
          await d.reference.delete();
        }
      }

      if (!mounted) return;

      // ✅ ChatScreen'i sıfırdan açıyoruz - State tamamen temizlenecek
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }

    if (mounted) setState(() => _loading = false);
  }

  // -----------------------------------------------------------
  // HESABI SİL
  // -----------------------------------------------------------
  Future<void> _deleteAccount() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text("Hesabı Sil", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Hesabın tamamen silinecek. Bu işlem geri alınamaz.\n\nDevam etmek istediğinden emin misin?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Evet, Sil",
                style: TextStyle(color: Colors.redAccent)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Firestore belgesi
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .delete();

      // Auth hesabı
      await user.delete();

      if (!mounted) return;

      // Login'e dön
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    }

    if (mounted) setState(() => _loading = false);
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                _profileCard(),
                const SizedBox(height: 20),
                _premiumSection(),
                const SizedBox(height: 20),
                _privacySection(),
                const SizedBox(height: 28),
                _logout(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PROFİL KARTI
  // -------------------------------------------------------------------------
  Widget _profileCard() {
    return _PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _item(
            icon: Icons.person_rounded,
            title: "Hesap",
            subtitle: _email,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // PREMIUM
  // -------------------------------------------------------------------------
  Widget _premiumSection() {
    return _PremiumGlassCard(
      child: Column(
        children: [
          _item(
            icon: Icons.workspace_premium_rounded,
            title: _isPremium ? "Premium aktif 🎉" : "Premium yakında geliyor",
            subtitle: _isPremium
                ? "Sınırsız sohbet ve analiz aktif."
                : "Şu anda tüm özellikler ücretsiz beta modunda.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _isPremium
                      ? const PremiumManagementScreen()
                      : const PremiumScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // GİZLİLİK + MESAJ SİL + HESAP SİL
  // -------------------------------------------------------------------------
  Widget _privacySection() {
    return _PremiumGlassCard(
      child: Column(
        children: [
          _item(
            icon: Icons.privacy_tip_rounded,
            title: "Gizlilik Politikası",
            subtitle: "Politikayı görüntüle",
            onTap: () async {
              final url =
                  Uri.parse("https://ariksoftware.com.tr/privacy-policy.html");
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
          const SizedBox(height: 18),
          _item(
            icon: Icons.delete_outline,
            title: "Mesaj geçmişini sil",
            subtitle: "Konuşmaların tamamı temizlenir",
            onTap: _clearChatHistory,
          ),
          const SizedBox(height: 18),
          _item(
            icon: Icons.delete_forever_rounded,
            title: "Hesabı sil",
            subtitle: "Geri alınamaz işlem",
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // ÇIKIŞ YAP
  // -------------------------------------------------------------------------
  Widget _logout() {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            "Çıkış Yap",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // ITEM
  // -------------------------------------------------------------------------
  Widget _item({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 18),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------
// GLASS CARD
// -------------------------------------------------------------------------
class _PremiumGlassCard extends StatelessWidget {
  final Widget child;
  const _PremiumGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
