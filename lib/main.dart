import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 📱 DevicePreview
import 'package:device_preview/device_preview.dart';

import 'firebase_options.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/premium_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';

import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🟣 Onboarding kontrolü
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool("seenOnboarding") ?? false;

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // 🔥 Debug: açık | Release: otomatik kapalı
      builder: (context) => FlortIQ(seenOnboarding: seenOnboarding),
    ),
  );
}

class FlortIQ extends StatelessWidget {
  final bool seenOnboarding;

  const FlortIQ({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SYRA',
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      builder: DevicePreview.appBuilder,
      theme: FlortIQTheme.theme,

      // ⭐ İlk açılış yönlendirmesi
      initialRoute: seenOnboarding ? "/auth-gate" : "/onboarding",

      routes: {
        // 🔥 Onboarding
        '/onboarding': (_) => const OnboardingScreen(),

        // 🔐 Auth giriş kontrol ekranı
        '/auth-gate': (_) => const _AuthGate(),

        // 🔑 Login / Signup
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),

        // 🏠 Ana ekran + Chat
        '/home': (_) => const HomeScreen(),
        '/chat': (_) => const ChatScreen(),

        // ⭐ Premium
        '/premium': (_) => const PremiumScreen(),
        '/premium-management': (_) => const PremiumManagementScreen(),

        // ⚙ Ayarlar
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ İlk yükleme
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        // ❌ Hata
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                "Bir hata oluştu.",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // 🔐 Giriş yapılmış kullanıcı → HOME
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 🚪 Giriş yoksa → LOGIN
        return const LoginScreen();
      },
    );
  }
}
