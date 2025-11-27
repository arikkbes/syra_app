import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Theme
import 'theme/syra_theme.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/premium_management_screen.dart';
import 'screens/settings_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// SYRA MAIN - iOS 26.1+ CRASH-PROOF VERSION v1.0.1 Build 24
/// ═══════════════════════════════════════════════════════════════
/// ✅ NO early initialization of plugins
/// ✅ NO SharedPreferences on startup
/// ✅ NO RevenueCat on startup
/// ✅ Plugins initialize ONLY when user needs them
/// ═══════════════════════════════════════════════════════════════

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ [SYRA] Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ [SYRA] Firebase error: $e');
  }

  debugPrint('🚀 [SYRA] Launching app - Build 24 - iOS Crash Fix');
  runApp(const SyraApp());
}

class SyraApp extends StatelessWidget {
  const SyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SYRA',
      debugShowCheckedModeBanner: false,
      theme: SyraTheme.theme,
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/chat': (_) => const ChatScreen(),
        '/premium': (_) => const PremiumScreen(),
        '/premium-management': (_) => const PremiumManagementScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// AUTH GATE - Simple and Clean
/// ═══════════════════════════════════════════════════════════════
/// No onboarding, no welcome screen, no first launch checks.
/// Just: Logged in? → ChatScreen, Not logged in? → LoginScreen
/// ═══════════════════════════════════════════════════════════════

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Show error screen if auth fails
        if (snapshot.hasError) {
          debugPrint('❌ [SYRA] Auth error: ${snapshot.error}');
          return _buildErrorScreen(context);
        }

        // User is logged in → ChatScreen
        if (snapshot.hasData && snapshot.data != null) {
          debugPrint('✅ [SYRA] User logged in: ${snapshot.data!.uid}');
          return const ChatScreen();
        }

        // No user → LoginScreen
        debugPrint('ℹ️ [SYRA] No user, showing login');
        return const LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: SyraColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    SyraColors.neonPink,
                    SyraColors.neonViolet,
                    SyraColors.neonCyan,
                    SyraColors.neonPink,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SyraColors.neonPink.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SyraColors.background,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SyraColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SYRA',
              style: TextStyle(
                color: SyraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Başlatılıyor...',
              style: TextStyle(
                color: SyraColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: SyraColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "Bağlantı kurulamadı",
                  style: TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "İnternet bağlantını kontrol edip tekrar dene.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SyraColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: SyraColors.accentGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Tekrar Dene",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
