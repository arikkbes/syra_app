import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  // 🔥 Kayıt Fonksiyonu
  Future<void> _signUp() async {
    final email = _email.text.trim();
    final p1 = _pass.text.trim();
    final p2 = _pass2.text.trim();

    // VALIDATION
    if (email.isEmpty || p1.isEmpty || p2.isEmpty) {
      _toast("Lütfen tüm alanları doldur.");
      return;
    }
    if (p1.length < 6) {
      _toast("Şifre en az 6 karakter olmalı.");
      return;
    }
    if (p1 != p2) {
      _toast("Şifreler uyuşmuyor.");
      return;
    }

    if (_loading) return;
    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: p1);

      final uid = cred.user!.uid;

      // 🔥 Firestore profil kaydı
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "email": email,
        "createdAt": DateTime.now().toIso8601String(),
        "isPremium": false,

        // 🔥 Mesaj limit sistemi
        "dailyMessageLimit": 10,
        "dailyMessageCount": 0,
        "lastMessageDate": DateTime.now().toIso8601String(),
        "usedToday": 0,

        // 🔥 AI Memory / Profil
        "profile_memory": [],
        "traits": [],
      });

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

      _toast(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF7AB8);
    const cyan = Color(0xFF66E0FF);

    final bool isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Ana arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF121212)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🧊 Blur + Overlay
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isWindows ? 6 : 26,
              sigmaY: isWindows ? 6 : 26,
            ),
            child: Container(
              color: Colors.black.withOpacity(isWindows ? 0.10 : 0.18),
            ),
          ),

          // 🪟 Signup Kartı
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.16),
                    Colors.white.withOpacity(0.06)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: pink.withOpacity(0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [cyan, pink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      "SYRA",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    "Yeni hesap oluştur ✨",
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 26),

                  // 📧 Email
                  _Input(
                    controller: _email,
                    hint: "E-posta",
                    prefix: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // 🔒 Şifre
                  _Input(
                    controller: _pass,
                    hint: "Şifre",
                    prefix: Icons.lock_outline,
                    obscure: _obscure1,
                    trailing: IconButton(
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      icon: Icon(
                        _obscure1 ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 🔒 Şifre tekrar
                  _Input(
                    controller: _pass2,
                    hint: "Şifre (tekrar)",
                    prefix: Icons.lock_reset_outlined,
                    obscure: _obscure2,
                    trailing: IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(
                        _obscure2 ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 🌈 Kayıt butonu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [pink, cyan],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  "Hesap Oluştur",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Zaten hesabın var mı?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Giriş yap",
                          style: TextStyle(
                            color: pink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// 🔥 PREMIUM INPUT WIDGET
// ------------------------------------------------------------
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefix;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;

  const _Input({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefix,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(prefix, color: Colors.white54),
        suffixIcon: trailing,
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
