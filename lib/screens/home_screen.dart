import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPremium = false;
  String _email = "";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      _email = user?.email ?? "kullanıcı";

      final premium = await FirestoreUser.isPremium();
      if (!mounted) return;

      setState(() {
        _isPremium = premium;
      });
    } catch (e) {
      debugPrint('HomeScreen _loadUser Firestore hatası: $e');
      if (!mounted) return;

      setState(() {
        _isPremium = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF00E5FF);
    const pink = Color(0xFFFF3B6F);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SYRA 💘',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            // ⭐ Premium Rozeti
            if (_isPremium)
              Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [cyan, pink],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "P R E M I U M 💎",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      // 🌈 Gövde
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: pink.withOpacity(0.20),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: cyan.withOpacity(0.10),
                blurRadius: 40,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, size: 50, color: pink),
              const SizedBox(height: 12),

              // Kullanıcı Adı
              Text(
                "Hoş geldin, $_email",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),
              Text(
                _isPremium
                    ? "Premium avantajların aktif 💎\nSınırsız mesajın tadını çıkar!"
                    : "SYRA deneyimine hazırsın 🧠\nDilersen Premium’a geçebilirsin 💎",
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 🚀 Devam Et — HER ZAMAN CHAT'E GÖNDERİR
              SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/chat'); // 🔥 FİX EDİLEN KISIM
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cyan, pink],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: const Center(
                      child: Text(
                        "Devam Et",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (!_isPremium) ...[
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/premium'),
                  child: const Text(
                    "SYRA Plus’a Geç 💎",
                    style: TextStyle(color: pink, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
