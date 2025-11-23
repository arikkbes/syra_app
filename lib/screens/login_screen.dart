import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../services/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  // 🔥 Email Login
  Future<void> _signIn() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      if (mounted) Navigator.pushReplacementNamed(context, '/chat');
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'user-not-found') {
        msg = "Kullanıcı bulunamadı.";
      } else if (e.code == 'wrong-password') {
        msg = "Şifre yanlış.";
      } else {
        msg = "Giriş yapılamadı: ${e.code}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 👤 Guest Login
  Future<void> _guest() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Guest giriş mümkün değil: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF66E0FF);
    const pink = Color(0xFFFF7AB8);

    final bool isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Arka plan gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D0D0D), Color(0xFF121212)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🧊 Blur layer
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isWindows ? 6 : 28,
              sigmaY: isWindows ? 6 : 28,
            ),
            child: Container(
              color: Colors.black.withOpacity(isWindows ? 0.10 : 0.18),
            ),
          ),

          // 🪟 Merkezi login kutusu
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(isWindows ? 0.18 : 0.14),
                    Colors.white.withOpacity(isWindows ? 0.06 : 0.09),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
                boxShadow: [
                  BoxShadow(
                    color: pink.withOpacity(0.20),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔥 SYRA Logo
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [cyan, pink],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      "SYRA",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "Welcome back kanka 👋",
                    style: TextStyle(color: Colors.white60),
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
                    obscure: _obscure,
                    trailing: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white54,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🎨 Giriş Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [pink, cyan],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
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
                                  "Sign in",
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

                  const SizedBox(height: 12),

                  // 🎭 Guest Login
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _guest,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.25)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        "Continue as Guest",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 🌐 Sadece Web'de: or + sosyal login
                  if (kIsWeb) ...[
                    // 🔥 “or” separator
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white30)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "or",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white30)),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 🌐 Sosyal Login (Web)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await SocialAuth.signInWithGoogle();
                                if (mounted) {
                                  Navigator.pushReplacementNamed(
                                      context, '/chat');
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Google hatası: $e")),
                                );
                              }
                            },
                            icon: const Icon(Icons.g_mobiledata_outlined,
                                color: Colors.white),
                            label: const Text(
                              "Google",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.25),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                await SocialAuth.signInWithApple();
                                if (mounted) {
                                  Navigator.pushReplacementNamed(
                                      context, '/chat');
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Apple hatası: $e")),
                                );
                              }
                            },
                            icon: const Icon(Icons.apple, color: Colors.white),
                            label: const Text(
                              "Apple",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.25),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],

                  // 🔗 Signup yönlendirme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Hesabın yok mu?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: pink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// 🔥 Input Widget (Premium)
// ------------------------------------------------------------
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefix;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;

  const _Input({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefix,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
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
