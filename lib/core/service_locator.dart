/// ═══════════════════════════════════════════════════════════════
/// SERVICE LOCATOR - Dependency Injection
/// ═══════════════════════════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Global Service Locator
/// Tüm servisler buradan erişilebilir
class ServiceLocator {
  ServiceLocator._();
  
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    
    _isInitialized = true;
  }

  void dispose() {
    _isInitialized = false;
  }
}

ServiceLocator get services => ServiceLocator.instance;
