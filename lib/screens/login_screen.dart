import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_providers.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/syra_orb.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA LOGIN SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Premium glassmorphism login ekranı.
/// - SYRA ORB header
/// - Glass card login form
/// - Animated transitions
/// ═══════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

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
    _email.dispose();
    _pass.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // EMAIL LOGIN
  // ─────────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    if (_loading) return;

    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError("E-posta ve şifre gerekli.");
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'user-not-found') {
        msg = "Kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        msg = "Şifre yanlış.";
      } else if (e.code == 'invalid-email') {
        msg = "Geçersiz e-posta adresi.";
      } else {
        msg = "Giriş yapılamadı: ${e.code}";
      }
      _showError(msg);
    } catch (e) {
      _showError("Bir hata oluştu. Lütfen tekrar dene.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GUEST LOGIN
  // ─────────────────────────────────────────────────────────────
  Future<void> _guest() async {
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
      }
    } catch (e) {
      _showError("Guest giriş mümkün değil: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: SyraColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          const SyraBackground(),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // SYRA ORB Logo
                      const SyraOrb(
                        state: OrbState.idle,
                        size: 140,
                      ),

                      const SizedBox(height: 24),

                      // SYRA Logo
                      const SyraLogo(fontSize: 32),

                      const SizedBox(height: 8),

                      Text(
                        "İlişki Danışmanın",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Login Card
                      _buildLoginCard(),

                      const SizedBox(height: 24),

                      // Sign up link
                      _buildSignUpLink(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_loading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LOGIN CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Welcome text
              Text(
                "Tekrar hoş geldin 👋",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Email input
              _buildTextField(
                controller: _email,
                hint: "E-posta",
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              // Password input
              _buildTextField(
                controller: _pass,
                hint: "Şifre",
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                trailing: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sign in button
              _buildPrimaryButton(
                text: "Giriş Yap",
                onPressed: _signIn,
              ),

              const SizedBox(height: 12),

              // Guest button
              _buildSecondaryButton(
                text: "Misafir olarak devam et",
                onPressed: _guest,
              ),

              // Social login (Web only)
              if (kIsWeb) ...[
                const SizedBox(height: 20),
                _buildDivider(),
                const SizedBox(height: 16),
                _buildSocialButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TEXT FIELD
  // ─────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
          suffixIcon: trailing,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PRIMARY BUTTON
  // ─────────────────────────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFF00D4FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Giriş Yap",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECONDARY BUTTON
  // ─────────────────────────────────────────────────────────────
  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DIVIDER
  // ─────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "veya",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SOCIAL BUTTONS
  // ─────────────────────────────────────────────────────────────
  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: "Google",
            onTap: () async {
              try {
                await SocialAuth.signInWithGoogle();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/chat');
                }
              } catch (e) {
                _showError("Google hatası: $e");
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple_rounded,
            label: "Apple",
            onTap: () async {
              try {
                await SocialAuth.signInWithApple();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/chat');
                }
              } catch (e) {
                _showError("Apple hatası: $e");
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SIGN UP LINK
  // ─────────────────────────────────────────────────────────────
  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Hesabın yok mu? ",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/signup'),
          child: const Text(
            "Kayıt ol",
            style: TextStyle(
              color: Color(0xFFFF6B9D),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LOADING OVERLAY
  // ─────────────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: const Center(
        child: SyraOrb(
          state: OrbState.thinking,
          size: 90,
        ),
      ),
    );
  }
}
