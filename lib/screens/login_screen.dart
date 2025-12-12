import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_providers.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA LOGIN SCREEN v2.0 - ChatGPT 2025 Style
/// ═══════════════════════════════════════════════════════════════
/// Clean, minimal login screen
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
      duration: const Duration(milliseconds: 600),
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
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
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
                      Text(
                        "SYRA",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                          color: SyraColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "İlişki Danışmanın",
                        style: TextStyle(
                          color: SyraColors.textMuted,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 48),

                      _buildLoginCard(),

                      const SizedBox(height: 24),

                      _buildSignUpLink(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_loading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SyraColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Tekrar hoş geldin 👋",
            style: TextStyle(
              color: SyraColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _email,
            hint: "E-posta",
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

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
                color: SyraColors.textHint,
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildPrimaryButton(
            text: "Giriş Yap",
            onPressed: _signIn,
          ),

          const SizedBox(height: 16),

          _buildDivider(),

          const SizedBox(height: 16),

          _buildSocialButtons(),

          const SizedBox(height: 16),

          _buildSecondaryButton(
            text: "Misafir Olarak Devam Et",
            onPressed: _guest,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
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
        color: SyraColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraColors.border,
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: SyraColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: SyraColors.textHint,
          ),
          prefixIcon: Icon(
            icon,
            color: SyraColors.textMuted,
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
          color: SyraColors.textPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: SyraColors.background,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SyraColors.border,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: SyraColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: SyraColors.divider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "veya",
            style: TextStyle(
              color: SyraColors.textHint,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: SyraColors.divider,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
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
          color: SyraColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SyraColors.border,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: SyraColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: SyraColors.textSecondary,
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
  // ─────────────────────────────────────────────────────────────
  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Hesabın yok mu? ",
          style: TextStyle(
            color: SyraColors.textMuted,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/signup'),
          child: Text(
            "Kayıt ol",
            style: TextStyle(
              color: SyraColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(SyraColors.accent),
        ),
      ),
    );
  }
}
