import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

class SocialAuth {
  static final _auth = FirebaseAuth.instance;

  /// WEB: Google Sign-In (popup). Mobil için sonra ayrı dosyada ekleyeceğiz.
  static Future<UserCredential> signInWithGoogle() async {
    if (!kIsWeb) {
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message:
            'Şimdilik Google girişi sadece WEB için aktif. Android/iOS birazdan ekleyeceğiz.',
      );
    }
    final provider =
        GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
    return _auth.signInWithPopup(provider);
  }

  /// WEB: Apple Sign-In (popup). iOS için native akışı sonra ekleyeceğiz.
  static Future<UserCredential> signInWithApple() async {
    if (!kIsWeb) {
      throw FirebaseAuthException(
        code: 'unsupported-platform',
        message:
            'Şimdilik Apple girişi sadece WEB için aktif. iOS ayarlarını sonra ekleyeceğiz.',
      );
    }
    final provider =
        AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
    return _auth.signInWithPopup(provider);
  }
}
