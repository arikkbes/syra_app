import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'services/purchase_service.dart';

// Theme
import 'theme/syra_theme.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/premium_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  // ═══════════════════════════════════════════════════════════════
  // CRASH GUARD: Ensure Flutter is initialized before anything
  // ═══════════════════════════════════════════════════════════════
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════
  // IAP INITIALIZATION - CRITICAL FOR iOS LAUNCH STABILITY
  // Initialize IAP BEFORE anything else to prevent StoreKit crash
  // This MUST happen early to set up purchase stream observer
  // ═══════════════════════════════════════════════════════════════
  try {
    await PurchaseService.initialize();
    debugPrint('✅ IAP initialized successfully');
  } catch (e) {
    debugPrint('⚠️ IAP init error (non-fatal): $e');
    // Continue - app will work without IAP
  }

  // ═══════════════════════════════════════════════════════════════
  // FIREBASE INITIALIZATION with error handling
  // ═══════════════════════════════════════════════════════════════
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue app even if Firebase fails to initialize
    // This prevents crash on launch if network is unavailable
  }

  // ═══════════════════════════════════════════════════════════════
  // ONBOARDING CHECK with error handling
  // ═══════════════════════════════════════════════════════════════
  bool seenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    seenOnboarding = prefs.getBool("seenOnboarding") ?? false;
  } catch (e) {
    debugPrint('SharedPreferences error: $e');
    // Default to not seen if prefs fail
    seenOnboarding = false;
  }

  // ═══════════════════════════════════════════════════════════════
  // RUN APP
  // ═══════════════════════════════════════════════════════════════
  runApp(SyraApp(seenOnboarding: seenOnboarding));
}

class SyraApp extends StatelessWidget {
  final bool seenOnboarding;

  const SyraApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SYRA',
      debugShowCheckedModeBanner: false,

      // SYRA Classic Dark Theme v1.0
      theme: SyraTheme.theme,

      // Initial route based on onboarding status
      initialRoute: seenOnboarding ? "/auth-gate" : "/onboarding",

      routes: {
        // Onboarding
        '/onboarding': (_) => const OnboardingScreen(),

        // Auth gate
        '/auth-gate': (_) => const _AuthGate(),

        // Login / Signup
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),

        // Main screens
        '/home': (_) => const HomeScreen(),
        '/chat': (_) => const ChatScreen(),

        // Premium
        '/premium': (_) => const PremiumScreen(),
        '/premium-management': (_) => const PremiumManagementScreen(),

        // Settings
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// AUTH GATE - Handles authentication state
/// ═══════════════════════════════════════════════════════════════
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ───────────────────────────────────────────────────────────
        // LOADING STATE
        // ───────────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: SyraColors.background,
            body: Center(
              child: Container(
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
            ),
          );
        }

        // ───────────────────────────────────────────────────────────
        // ERROR STATE - Show friendly message, don't crash
        // ───────────────────────────────────────────────────────────
        if (snapshot.hasError) {
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
                          // Navigate to login to allow retry
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

        // ───────────────────────────────────────────────────────────
        // AUTHENTICATED → HOME
        // ───────────────────────────────────────────────────────────
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // ───────────────────────────────────────────────────────────
        // NOT AUTHENTICATED → LOGIN
        // ───────────────────────────────────────────────────────────
        return const LoginScreen();
      },
    );
  }
}
