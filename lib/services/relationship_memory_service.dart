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
import 'package:shared_preferences/shared_preferences.dart';
import '../models/relationship_memory.dart';
import 'package:syra/core/syra_log.dart';

class RelationshipMemoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// If a relationship has been "forgotten" or "deleted", we should not show it in UI.
  static bool _isHiddenRelationship(Map<String, dynamic> data) {
    return data['deletedAt'] != null || data['lastForgottenAt'] != null;
  }

  // ═══════════════════════════════════════════════════════════════
  // SELECTED SELF PARTICIPANT (Synced between Chat and Radar)
  // ═══════════════════════════════════════════════════════════════

  /// Get selected self participant ID (name from speakers list)
  static Future<String?> getSelectedSelfParticipant() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selectedSelfParticipantId');
    } catch (e) {
      syraLog('❌ Error getting selectedSelfParticipantId: $e');
      return null;
    }
  }

  /// Set selected self participant ID (name from speakers list)
  static Future<bool> setSelectedSelfParticipant(String? participantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (participantId == null) {
        await prefs.remove('selectedSelfParticipantId');
      } else {
        await prefs.setString('selectedSelfParticipantId', participantId);
      }
      return true;
    } catch (e) {
      syraLog('❌ Error setting selectedSelfParticipantId: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RELATIONSHIP MEMORY CRUD
  // ═══════════════════════════════════════════════════════════════

  /// Get current user's relationship memory
  /// If forceIncludeInactive = true, returns even if isActive = false (for panel UI)
  /// BUT: If relationship has lastForgottenAt/deletedAt, treat as null.
  static Future<RelationshipMemory?> getMemory(
      {bool forceIncludeInactive = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      syraLog(
          '🔍 getMemory called (forceIncludeInactive: $forceIncludeInactive)');

      // Get active relationship ID from user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final activeRelationshipId =
          userDoc.data()?['activeRelationshipId'] as String?;

      syraLog('🔍 activeRelationshipId from user doc: $activeRelationshipId');

      // If no activeRelationshipId, try to find the most recent relationship
      String? relId = activeRelationshipId;
      if (relId == null && forceIncludeInactive) {
        syraLog('🔍 No activeRelationshipId, searching for most recent...');

        // Find most recent relationship (even if inactive)
        // IMPORTANT: Get from server to avoid cache issues after delete
        final relationsSnapshot = await _firestore
            .collection('relationships')
            .doc(user.uid)
            .collection('relations')
            .orderBy('updatedAt', descending: true)
            .limit(10)
            .get(const GetOptions(source: Source.server)); // ← FORCE SERVER

        if (relationsSnapshot.docs.isNotEmpty) {
          // pick first non-hidden relationship
          for (final d in relationsSnapshot.docs) {
            final data = d.data();
            if (!_isHiddenRelationship(data)) {
              relId = d.id;
              break;
            }
          }

          if (relId != null) {
            syraLog('🔍 Found most recent non-hidden relationship: $relId');
          } else {
            syraLog('🔍 Only hidden (forgotten/deleted) relationships exist');
          }
        } else {
          syraLog('🔍 No relationships found at all');
        }
      }

      if (relId == null) {
        // No relationship found at all
        syraLog('🔍 No relationship ID, returning null');
        return null;
      }

      // Get relationship document from new path
      // IMPORTANT: Get from server to avoid cache issues after delete
      final relationshipDoc = await _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(relId)
          .get(const GetOptions(source: Source.server)); // ← FORCE SERVER

      if (!relationshipDoc.exists) {
        syraLog('🔍 Relationship doc does not exist: $relId');
        return null;
      }

      final data = relationshipDoc.data()!;

      syraLog('🔍 Relationship found: $relId, isActive: ${data['isActive']}');

      // If it was forgotten/deleted, treat as no relationship (even for panel UI)
      if (_isHiddenRelationship(data)) {
        syraLog('🔍 Relationship is hidden (forgotten/deleted) → returning null');
        return null;
      }

      // Check isActive flag - if false and not forcing, treat as no relationship
      if (!forceIncludeInactive && data['isActive'] == false) return null;

      return RelationshipMemory.fromFirestore(
        data,
        docId: relationshipDoc.id,
      );
    } catch (e) {
      syraLog('RelationshipMemoryService.getMemory error: $e');
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
          .map((doc) =>
              RelationshipMemory.fromFirestore(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      syraLog('RelationshipMemoryService.getAllRelationships error: $e');
      return [];
    }
  }

  /// Get a specific relationship by ID without changing activeRelationshipId
  /// Fetches from server to avoid cache issues
  static Future<RelationshipMemory?> getMemoryById(
      String relationshipId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      syraLog('🔍 getMemoryById called for: $relationshipId');

      // Get relationship document from server
      final relationshipDoc = await _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(relationshipId)
          .get(const GetOptions(source: Source.server));

      if (!relationshipDoc.exists) {
        syraLog('🔍 Relationship doc does not exist: $relationshipId');
        return null;
      }

      final data = relationshipDoc.data()!;

      // If it was forgotten/deleted, return null
      if (_isHiddenRelationship(data)) {
        syraLog('🔍 Relationship is hidden (forgotten/deleted) → returning null');
        return null;
      }

      return RelationshipMemory.fromFirestore(
        data,
        docId: relationshipDoc.id,
      );
    } catch (e) {
      syraLog('❌ RelationshipMemoryService.getMemoryById error: $e');
      return null;
    }
  }

  /// Persist participant mapping (best-effort, does not crash UI if denied)
  static Future<void> persistParticipantMapping({
    required String relationshipId,
    required String selfParticipant,
    required String partnerParticipant,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        syraLog('❌ persistParticipantMapping: No current user');
        return;
      }

      syraLog('🔍 persistParticipantMapping called:');
      syraLog('   - relationshipId: $relationshipId');
      syraLog('   - selfParticipant: $selfParticipant');
      syraLog('   - partnerParticipant: $partnerParticipant');

      final updateData = <String, dynamic>{
        'selfParticipant': selfParticipant,
        'partnerParticipant': partnerParticipant,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(relationshipId)
          .update(updateData);

      syraLog('✅ Participant mapping persisted successfully');

      // Save selected self participant (sync state)
      await setSelectedSelfParticipant(selfParticipant);
      syraLog('✅ selectedSelfParticipant saved: $selfParticipant');
    } catch (e) {
      // Best-effort: do not crash UI if this fails
      syraLog('⚠️ persistParticipantMapping failed (best-effort): $e');
    }
  }

  /// Update isActive flag for a relationship
  static Future<bool> updateIsActive(bool isActive,
      {String? relationshipId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get relationship ID
      String? relId = relationshipId;
      if (relId == null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
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
      syraLog('RelationshipMemoryService.updateIsActive error: $e');
      return false;
    }
  }

  /// Delete relationship memory
  /// If permanentDelete=true, "Forget" button behavior:
  ///   - First mark relationship as hidden (lastForgottenAt/deletedAt) so UI stops showing it immediately
  ///   - Then best-effort delete chunks and doc (rules may block these deletes)
  /// If permanentDelete=false, just sets isActive=false (for deactivation)
  static Future<bool> deleteMemory({
    String? relationshipId,
    bool permanentDelete = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      syraLog(
          '🗑️ deleteMemory called (relationshipId: $relationshipId, permanentDelete: $permanentDelete)');

      // Get relationship ID
      String? relId = relationshipId;
      if (relId == null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        relId = userDoc.data()?['activeRelationshipId'] as String?;
        syraLog('🗑️ Got relationshipId from user doc: $relId');
      }

      if (relId == null) {
        syraLog('🗑️ No relationshipId found, trying legacy path');
        // Try legacy path
        await _firestore
            .collection('relationship_memory')
            .doc(user.uid)
            .delete();

        // Also clear user activeRelationshipId just in case
        await _firestore.collection('users').doc(user.uid).update({
          'activeRelationshipId': null,
        });

        await setSelectedSelfParticipant(null);
        return true;
      }

      final relationshipRef = _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(relId);

      if (permanentDelete) {
        syraLog('🗑️ FORGET (permanentDelete): hiding relationship $relId first');

        // 0) FIRST mark as hidden so UI stops showing it even if deletes fail
        try {
          await relationshipRef.set({
            'isActive': false,
            'lastForgottenAt': FieldValue.serverTimestamp(),
            'deletedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          syraLog(
              '🗑️ Relationship marked hidden (lastForgottenAt/deletedAt set)');
        } catch (e) {
          syraLog('⚠️ Could not mark relationship as hidden: $e');
          // Even if this fails, continue trying to clear active id below.
        }

        // 1) Best-effort: delete chunks subcollection (may be blocked by rules)
        try {
          final chunksSnapshot =
              await relationshipRef.collection('chunks').get();
          syraLog('🗑️ Found ${chunksSnapshot.docs.length} chunks to delete');

          WriteBatch batch = _firestore.batch();
          int batchCount = 0;

          for (final doc in chunksSnapshot.docs) {
            batch.delete(doc.reference);
            batchCount++;

            if (batchCount >= 500) {
              await batch.commit();
              batch = _firestore.batch();
              batchCount = 0;
            }
          }

          if (batchCount > 0) {
            await batch.commit();
          }

          syraLog('🗑️ All chunks deleted (best-effort success)');
        } catch (e) {
          syraLog('⚠️ Chunk delete failed (rules?) continuing anyway: $e');
        }

        // 2) Best-effort: delete relationship doc itself (may be blocked by rules)
        try {
          await relationshipRef.delete();
          syraLog('🗑️ Relationship doc deleted (best-effort success)');
        } catch (e) {
          syraLog('⚠️ Relationship doc delete blocked (rules?) kept hidden: $e');
        }
      } else {
        syraLog('🗑️ SOFT DELETE: Setting isActive=false for $relId');
        try {
          await relationshipRef.update({
            'isActive': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          syraLog('🗑️ Relationship marked as inactive (soft delete)');
        } catch (e) {
          syraLog('⚠️ Could not update relationship doc (might not exist): $e');
        }
      }

      // Clear activeRelationshipId
      syraLog('🗑️ Clearing activeRelationshipId from user doc');
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'activeRelationshipId': null,
        });
      } catch (e) {
        // If user doc update fails due to rules, log it.
        syraLog('⚠️ Could not clear activeRelationshipId: $e');
      }

      // Clear selected self participant (sync state)
      await setSelectedSelfParticipant(null);

      syraLog(
          '🗑️ Delete/Forget completed successfully (UI should stop showing it)');
      return true;
    } catch (e, stackTrace) {
      syraLog('❌ RelationshipMemoryService.deleteMemory error: $e');
      syraLog('Stack trace: $stackTrace');
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
      syraLog('RelationshipMemoryService.setActiveRelationship error: $e');
      return false;
    }
  }

  /// Update selfParticipant and partnerParticipant
  static Future<bool> updateParticipants({
    required String selfParticipant,
    String? partnerParticipant,
    String? relationshipId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        syraLog('❌ updateParticipants: No current user');
        return false;
      }

      syraLog('🔍 updateParticipants called:');
      syraLog('   - selfParticipant: $selfParticipant');
      syraLog('   - partnerParticipant: $partnerParticipant');
      syraLog('   - relationshipId: $relationshipId');
      syraLog('   - uid: ${user.uid}');

      // Get relationship ID
      String? relId = relationshipId;
      if (relId == null) {
        syraLog('🔍 No relationshipId provided, fetching from user doc...');
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        relId = userDoc.data()?['activeRelationshipId'] as String?;
        syraLog('🔍 Active relationship ID from user doc: $relId');
      }

      if (relId == null) {
        syraLog('❌ updateParticipants: No relationship ID found');
        return false;
      }

      final updateData = <String, dynamic>{
        'selfParticipant': selfParticipant,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (partnerParticipant != null) {
        updateData['partnerParticipant'] = partnerParticipant;
      }

      syraLog(
          '🔍 Updating relationship doc: relationships/${user.uid}/relations/$relId');
      syraLog('🔍 Update data: $updateData');

      await _firestore
          .collection('relationships')
          .doc(user.uid)
          .collection('relations')
          .doc(relId)
          .update(updateData);

      syraLog('✅ Relationship doc updated successfully');

      // Save selected self participant (sync state between Chat and Radar)
      await setSelectedSelfParticipant(selfParticipant);
      syraLog('✅ selectedSelfParticipant saved: $selfParticipant');

      // If activeRelationshipId not set, set it now
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.data()?['activeRelationshipId'] == null) {
        syraLog('🔍 Setting activeRelationshipId in user doc...');
        await _firestore.collection('users').doc(user.uid).set({
          'activeRelationshipId': relId,
        }, SetOptions(merge: true));
        syraLog('✅ activeRelationshipId set');
      }

      return true;
    } catch (e) {
      syraLog('❌ updateParticipants error: $e');
      return false;
    }
  }
}
