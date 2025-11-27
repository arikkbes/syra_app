import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/purchase_service.dart';
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
/// SYRA MAIN - CRASH-PROOF VERSION
/// ═══════════════════════════════════════════════════════════════
/// CRITICAL: Do NOT initialize ANYTHING except Firebase in main()
/// iOS crashes if SharedPreferences or RevenueCat init before first frame
/// ═══════════════════════════════════════════════════════════════

Future<void> main() async {
  // ═══════════════════════════════════════════════════════════════
  // STEP 1: Flutter bindings ONLY
  // ═══════════════════════════════════════════════════════════════
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════
  // STEP 2: Firebase ONLY (required for auth)
  // ═══════════════════════════════════════════════════════════════
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase error: $e');
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 3: Launch app immediately
  // ═══════════════════════════════════════════════════════════════
  // DO NOT INITIALIZE:
  // ❌ SharedPreferences
  // ❌ RevenueCat
  // ❌ Any plugin that touches native code
  //
  // These will be initialized AFTER first frame in AuthGate
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
/// AUTH GATE - CRASH-PROOF INITIALIZATION
/// ═══════════════════════════════════════════════════════════════
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
    // DO NOT call _initializeServices() here!
    // It will be called after first frame
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize services AFTER first frame is built
    if (!_servicesInitialized) {
      _initializeServices();
    }
  }

  /// Initialize plugins AFTER first frame is rendered
  /// This is the ONLY safe way to init SharedPreferences on iOS
  Future<void> _initializeServices() async {
    if (_servicesInitialized) return;

    // Wait for frame to be rendered
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Initialize SharedPreferences
      await SyraPrefs.initialize();
      debugPrint('✅ SyraPrefs initialized');
    } catch (e) {
      debugPrint('⚠️ SyraPrefs error: $e');
    }

    try {
      // Initialize RevenueCat
      await PurchaseService.initialize();
      debugPrint('✅ RevenueCat initialized');
    } catch (e) {
      debugPrint('⚠️ RevenueCat error: $e');
    }

    if (mounted) {
      setState(() => _servicesInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ───────────────────────────────────────────────────────────
        // LOADING STATE
        // ───────────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting ||
            !_servicesInitialized) {
          return _buildLoadingScreen();
        }

        // ───────────────────────────────────────────────────────────
        // ERROR STATE
        // ───────────────────────────────────────────────────────────
        if (snapshot.hasError) {
          return _buildErrorScreen();
        }

        // ───────────────────────────────────────────────────────────
        // LOGGED IN → CHAT SCREEN
        // ───────────────────────────────────────────────────────────
        if (snapshot.hasData && snapshot.data != null) {
          return const ChatScreen();
        }

        // ───────────────────────────────────────────────────────────
        // NOT LOGGED IN → LOGIN SCREEN
        // ───────────────────────────────────────────────────────────
        return const LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
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
