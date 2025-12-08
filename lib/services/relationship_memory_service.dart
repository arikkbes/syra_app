/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP MEMORY SERVICE
/// ═══════════════════════════════════════════════════════════════
/// Service for reading/updating relationship memory from Firestore
/// ═══════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/relationship_memory.dart';

class RelationshipMemoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's relationship memory
  static Future<RelationshipMemory?> getMemory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('relationship_memory')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return RelationshipMemory.fromFirestore(doc.data()!);
    } catch (e) {
      print('RelationshipMemoryService.getMemory error: $e');
      return null;
    }
  }

  /// Update isActive flag
  static Future<bool> updateIsActive(bool isActive) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('relationship_memory')
          .doc(user.uid)
          .update({'isActive': isActive});

      return true;
    } catch (e) {
      print('RelationshipMemoryService.updateIsActive error: $e');
      return false;
    }
  }

  /// Delete relationship memory
  static Future<bool> deleteMemory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('relationship_memory')
          .doc(user.uid)
          .delete();

      return true;
    } catch (e) {
      print('RelationshipMemoryService.deleteMemory error: $e');
      return false;
    }
  }
}
