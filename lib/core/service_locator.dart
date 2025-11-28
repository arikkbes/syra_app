/// ═══════════════════════════════════════════════════════════════
/// SERVICE LOCATOR - Dependency Injection
/// ═══════════════════════════════════════════════════════════════

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mevcut servisleri import et (geriye uyumluluk için)
import '../services/firestore_user.dart';
import '../services/chat_service.dart';
import '../services/purchase_service.dart';

/// Global Service Locator
/// Tüm servisler buradan erişilebilir
class ServiceLocator {
  ServiceLocator._();
  
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  // Firebase instances
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Burada gelecekte yeni repository'leri initialize edeceğiz
    // Şimdilik mevcut servisler çalışmaya devam ediyor
    
    _isInitialized = true;
  }

  void dispose() {
    _isInitialized = false;
  }
}

// Global accessor
ServiceLocator get services => ServiceLocator.instance;
