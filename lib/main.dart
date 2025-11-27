import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
// TEMPORARILY DISABLED - TESTING CRASH FIX
// import 'services/purchase_service.dart';
import 'utils/syra_prefs.dart';

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
/// SYRA MAIN - ULTRA CRASH-PROOF VERSION v1.0.1 Build 23
/// ═══════════════════════════════════════════════════════════════
/// RevenueCat TEMPORARILY DISABLED for crash testing
/// Once stable, we will re-enable with proper delays
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

  debugPrint('🚀 [SYRA] Launching app - Build 23');
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

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔧 [SYRA] AuthGate initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('🔧 [SYRA] AuthGate didChangeDependencies');
    if (!_servicesInitialized) {
      _initializeServices();
    }
  }

  /// ULTRA AGGRESSIVE DELAY - 5 seconds total
  Future<void> _initializeServices() async {
    if (_servicesInitialized) return;

    debugPrint('⏳ [SYRA] Starting service initialization...');

    // STEP 1: Wait for UI to be fully ready
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('⏳ [SYRA] 2 seconds passed...');

    // STEP 2: Initialize SharedPreferences
    try {
      await SyraPrefs.initialize();
      debugPrint('✅ [SYRA] SyraPrefs initialized');
    } catch (e) {
      debugPrint('⚠️ [SYRA] SyraPrefs error: $e');
    }

    // STEP 3: RevenueCat DISABLED for testing
    debugPrint('⚠️ [SYRA] RevenueCat DISABLED - Testing crash fix');
    // Future.delayed(const Duration(seconds: 3), () async {
    //   try {
    //     await PurchaseService.initialize();
    //     debugPrint('✅ [SYRA] RevenueCat initialized');
    //   } catch (e) {
    //     debugPrint('⚠️ [SYRA] RevenueCat error: $e');
    //   }
    // });

    if (mounted) {
      setState(() => _servicesInitialized = true);
      debugPrint('✅ [SYRA] Services initialization complete');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !_servicesInitialized) {
          debugPrint('⏳ [SYRA] Loading state...');
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          debugPrint('❌ [SYRA] Auth error: ${snapshot.error}');
          return _buildErrorScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          debugPrint('✅ [SYRA] User logged in: ${snapshot.data!.uid}');
          return const ChatScreen();
        }

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
            Text(
              'SYRA Başlatılıyor...',
              style: TextStyle(
                color: SyraColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Build 23 - Crash Fix Test',
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

  Widget _buildErrorScreen() {
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
