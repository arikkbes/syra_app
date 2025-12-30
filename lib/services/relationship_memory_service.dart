/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP MEMORY SERVICE V2
/// ═══════════════════════════════════════════════════════════════
/// Service for reading/updating relationship memory from Firestore
/// Updated for new chunked pipeline architecture
/// 
/// Firestore structure:
/// - relationships/{uid}/relations/{relationshipId}
/// - relationships/{uid}/relations/{relationshipId}/chunks/{chunkId}
/// - users/{uid}.activeRelationshipId
/// ═══════════════════════════════════════════════════════════════
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/relationship_memory.dart';

class RelationshipMemoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's active relationship memory
  static Future<RelationshipMemory?> getMemory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get active relationship ID from user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final activeRelationshipId = userDoc.data()?['activeRelationshipId'] as String?;

      if (activeRelationshipId == null) {
        // Try legacy path for backward compatibility
        return await _getLegacyMemory(user.uid);
      }

      // Get relationship document from new path
      final relationshipDoc = await _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(activeRelationshipId)
          .get();

      if (!relationshipDoc.exists) return null;

      return RelationshipMemory.fromFirestore(
        relationshipDoc.data()!,
        docId: relationshipDoc.id,
      );
    } catch (e) {
      print('RelationshipMemoryService.getMemory error: $e');
      return null;
    }
  }

  /// Get legacy memory (for backward compatibility)
  static Future<RelationshipMemory?> _getLegacyMemory(String uid) async {
    try {
      final doc = await _firestore
          .collection('relationship_memory')
          .doc(uid)
          .get();

      if (!doc.exists) return null;

      return RelationshipMemory.fromLegacy(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Get all relationships for user
  static Future<List<RelationshipMemory>> getAllRelationships() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RelationshipMemory.fromFirestore(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      print('RelationshipMemoryService.getAllRelationships error: $e');
      return [];
    }
  }

  /// Update isActive flag for a relationship
  static Future<bool> updateIsActive(bool isActive, {String? relationshipId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get relationship ID
      String? relId = relationshipId;
      if (relId == null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        relId = userDoc.data()?['activeRelationshipId'] as String?;
      }

      if (relId == null) {
        // Try legacy path
        await _firestore
            .collection('relationship_memory')
            .doc(user.uid)
            .update({'isActive': isActive});
        return true;
      }

      await _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(relId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('RelationshipMemoryService.updateIsActive error: $e');
      return false;
    }
  }

  /// Delete relationship memory
  static Future<bool> deleteMemory({String? relationshipId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get relationship ID
      String? relId = relationshipId;
      if (relId == null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        relId = userDoc.data()?['activeRelationshipId'] as String?;
      }

      if (relId == null) {
        // Try legacy path
        await _firestore
            .collection('relationship_memory')
            .doc(user.uid)
            .delete();
        return true;
      }

      final relationshipRef = _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(relId);

      // Delete chunks subcollection first
      final chunksSnapshot = await relationshipRef.collection('chunks').get();
      final batch = _firestore.batch();
      for (final doc in chunksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete main document
      await relationshipRef.delete();

      // Clear active relationship pointer
      await _firestore.collection('users').doc(user.uid).update({
        'activeRelationshipId': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      print('RelationshipMemoryService.deleteMemory error: $e');
      return false;
    }
  }

  /// Set active relationship
  static Future<bool> setActiveRelationship(String relationshipId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).set({
        'activeRelationshipId': relationshipId,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('RelationshipMemoryService.setActiveRelationship error: $e');
      return false;
    }
  }
}
