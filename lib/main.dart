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
/// SYRA MAIN - ChatGPT-Style Launch Architecture
/// ═══════════════════════════════════════════════════════════════
/// Launch Flow:
/// 1. Initialize Flutter bindings
/// 2. Initialize Firebase (critical)
/// 3. Launch app with AuthGate
/// 4. AuthGate routes to:
///    - ChatScreen (if logged in)
///    - LoginScreen (if not logged in)
///
/// NO onboarding, NO SharedPreferences at startup, NO crashes
/// ═══════════════════════════════════════════════════════════════

Future<void> main() async {
  // ═══════════════════════════════════════════════════════════════
  // STEP 1: Ensure Flutter is initialized
  // ═══════════════════════════════════════════════════════════════
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════════════════
  // STEP 2: Initialize Firebase (REQUIRED)
  // ═══════════════════════════════════════════════════════════════
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization error: $e');
    // Continue - AuthGate will handle errors gracefully
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 3: Launch app
  // ═══════════════════════════════════════════════════════════════
  // Note: RevenueCat and SharedPreferences are initialized LATER,
  // after the first frame is built, to prevent iOS startup crashes
  runApp(const SyraApp());
}

class SyraApp extends StatelessWidget {
  const SyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SYRA',
      debugShowCheckedModeBanner: false,

      // SYRA Premium Dark Theme
      theme: SyraTheme.theme,

      // Start directly at AuthGate - no onboarding, no welcome screens
      home: const _AuthGate(),

      // Named routes for navigation
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
/// AUTH GATE - ChatGPT-Style Authentication Routing
/// ═══════════════════════════════════════════════════════════════
/// This is the core of SYRA's launch architecture.
/// It listens to Firebase Auth state and routes accordingly:
/// - Logged in? → ChatScreen (like ChatGPT)
/// - Not logged in? → LoginScreen
///
/// When user logs out, authStateChanges() triggers a rebuild
/// and automatically shows LoginScreen.
/// ═══════════════════════════════════════════════════════════════
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app services AFTER first frame
  /// This prevents iOS crashes from SharedPreferences and RevenueCat
  Future<void> _initializeApp() async {
    // Wait for first frame to be rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize SharedPreferences safely
      await SyraPrefs.initialize();
      debugPrint('✅ SharedPreferences initialized');

      // Initialize RevenueCat safely
      try {
        await PurchaseService.initialize();
        debugPrint('✅ RevenueCat initialized');
      } catch (e) {
        debugPrint('⚠️ RevenueCat init error (non-fatal): $e');
      }

      if (mounted) {
        setState(() => _initialized = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ───────────────────────────────────────────────────────────
        // LOADING STATE - Show while checking auth
        // ───────────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // ───────────────────────────────────────────────────────────
        // ERROR STATE - Show if Firebase auth failed
        // ───────────────────────────────────────────────────────────
        if (snapshot.hasError) {
          return _buildErrorScreen(context);
        }

        // ───────────────────────────────────────────────────────────
        // AUTHENTICATED → CHAT SCREEN (like ChatGPT)
        // ───────────────────────────────────────────────────────────
        if (snapshot.hasData && snapshot.data != null) {
          return const ChatScreen();
        }

        // ───────────────────────────────────────────────────────────
        // NOT AUTHENTICATED → LOGIN SCREEN
        // ───────────────────────────────────────────────────────────
        return const LoginScreen();
      },
    );
  }

  /// Loading screen with SYRA branding
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

  /// Error screen if Firebase fails
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
}

