import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/purchase_service.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA SIGNUP SCREEN v2.0 - ChatGPT 2025 Style
/// ═══════════════════════════════════════════════════════════════
/// Clean, minimal signup screen matching login
/// ═══════════════════════════════════════════════════════════════

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

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
    _pass2.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  Future<void> _signUp() async {
    final email = _email.text.trim();
    final p1 = _pass.text.trim();
    final p2 = _pass2.text.trim();

    if (email.isEmpty || p1.isEmpty || p2.isEmpty) {
      _showError("Lütfen tüm alanları doldur.");
      return;
    }
    if (p1.length < 6) {
      _showError("Şifre en az 6 karakter olmalı.");
      return;
    }
    if (p1 != p2) {
      _showError("Şifreler uyuşmuyor.");
      return;
    }

    if (_loading) return;
    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: p1);

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "email": email,
        "createdAt": DateTime.now().toIso8601String(),
        "dailyMessageLimit": 10,
        "dailyMessageCount": 0,
        "lastMessageDate": DateTime.now().toIso8601String(),
        "usedToday": 0,
        "profile_memory": [],
        "traits": [],
      });
      await PurchaseService.identifyUser(uid);

      if (mounted) Navigator.pushReplacementNamed(context, "/chat");
    } on FirebaseAuthException catch (e) {
      String msg;

      if (e.code == "email-already-in-use") {
        msg = "Bu e-posta zaten kayıtlı.";
      } else if (e.code == "invalid-email") {
        msg = "E-posta geçersiz.";
      } else if (e.code == "weak-password") {
        msg = "Şifre zayıf.";
      } else {
        msg = "Kayıt başarısız: ${e.code}";
      }

      _showError(msg);
    } catch (e) {
      _showError("Bir hata oluştu. Lütfen tekrar dene.");
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
                        "Yeni Hesap Oluştur",
                        style: TextStyle(
                          color: SyraColors.textMuted,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 48),

                      _buildSignupCard(),

                      const SizedBox(height: 24),

                      _buildLoginLink(),

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
  Widget _buildSignupCard() {
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
            "Hesabını oluştur 🚀",
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
            obscure: _obscure1,
            trailing: IconButton(
              onPressed: () => setState(() => _obscure1 = !_obscure1),
              icon: Icon(
                _obscure1
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: SyraColors.textHint,
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _pass2,
            hint: "Şifre (tekrar)",
            icon: Icons.lock_reset_rounded,
            obscure: _obscure2,
            trailing: IconButton(
              onPressed: () => setState(() => _obscure2 = !_obscure2),
              icon: Icon(
                _obscure2
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: SyraColors.textHint,
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildPrimaryButton(
            text: "Hesap Oluştur",
            onPressed: _signUp,
          ),

          const SizedBox(height: 16),

          Text(
            "Kayıt olarak, Kullanım Şartları ve\nGizlilik Politikası'nı kabul etmiş olursun.",
            style: TextStyle(
              color: SyraColors.textHint,
              fontSize: 11,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
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
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Zaten hesabın var mı? ",
          style: TextStyle(
            color: SyraColors.textMuted,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            "Giriş yap",
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
