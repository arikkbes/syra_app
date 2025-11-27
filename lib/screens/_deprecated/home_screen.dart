import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_user.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/syra_orb.dart'; // 🔥 Resmi orb buradan geliyor
import 'premium_screen.dart';
import 'premium_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isPremium = false;
  String _email = "";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUser();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      _email = user?.email ?? "Kanka";

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
    return Scaffold(
      body: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🔥 SYRA ORB (Login & Signup ile aynı)
                      const SyraOrb(
                        state: OrbState.idle,
                        size: 160,
                      ),

                      const SizedBox(height: 28),

                      // SYRA Logo
                      const SyraLogo(fontSize: 36),

                      const SizedBox(height: 12),

                      Text(
                        "İlişki Danışmanın",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      _buildWelcomeCard(),

                      const SizedBox(height: 24),

                      _buildContinueButton(),

                      const SizedBox(height: 16),

                      if (!_isPremium) _buildPremiumButton(),

                      const SizedBox(height: 32),

                      _buildLogoutButton(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Hoş geldin, ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _email.split('@').first,
                style: const TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: _isPremium
                  ? const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFF00D4FF)],
                    )
                  : null,
              color: _isPremium ? null : Colors.white.withValues(alpha: 0.08),
              border: _isPremium
                  ? null
                  : Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Text(
              _isPremium ? "✨ Premium Aktif" : "Free Plan",
              style: TextStyle(
                color: _isPremium
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isPremium
                ? "Sınırsız mesaj ve derin analiz özelliklerin aktif.\nSYRA seninle birlikte!"
                : "SYRA deneyimine hazırsın 🧠\nGünlük 10 mesaj hakkın var.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/chat'),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 300),
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFF00D4FF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.35),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Sohbete Başla",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumButton() {
    return GestureDetector(
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
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 300),
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFD54F).withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: const Color(0xFFFFD54F).withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "SYRA Plus'a Geç",
                style: TextStyle(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      },
      child: Text(
        "Çıkış Yap",
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 13,
        ),
      ),
    );
  }
}
