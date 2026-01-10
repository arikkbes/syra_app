import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP JOB MONITORING SERVICE
/// ═══════════════════════════════════════════════════════════════
/// MODULE 1: Service for monitoring async relationship upload jobs
/// Provides real-time updates on job status and progress
/// ═══════════════════════════════════════════════════════════════

class RelationshipJobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream job status updates
  /// Returns a stream of job status documents that updates in real-time
  Stream<RelationshipJobStatus> watchJob(String jobId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('relationship_jobs')
        .doc(jobId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return RelationshipJobStatus(
          jobId: jobId,
          status: JobStatus.notFound,
          progress: JobProgress(step: 'not_found', percent: 0),
        );
      }

      return RelationshipJobStatus.fromFirestore(snapshot.data()!, jobId);
    });
  }

  /// Get job status once (without streaming)
  Future<RelationshipJobStatus?> getJobStatus(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('relationship_jobs')
        .doc(jobId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return RelationshipJobStatus.fromFirestore(snapshot.data()!, jobId);
  }

  /// Delete a job document (cleanup)
  Future<void> deleteJob(String jobId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('relationship_jobs')
        .doc(jobId)
        .delete();
  }

  /// Get the most recent active job (MODULE 2)
  /// Returns the most recent job ordered by createdAt desc, limit 1
  /// Used to restore job status when panel reopens
  Future<RelationshipJobStatus?> getMostRecentActiveJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('relationship_jobs')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return RelationshipJobStatus.fromFirestore(doc.data(), doc.id);
  }

  /// Stream the most recent active job (MODULE 2)
  /// Returns a stream that updates when the most recent job changes
  Stream<RelationshipJobStatus?> watchMostRecentActiveJob() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('relationship_jobs')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return RelationshipJobStatus.fromFirestore(doc.data(), doc.id);
    });
  }
}

/// Job status enum
enum JobStatus {
  queued,
  processing,
  complete,
  failed,
  notFound,
}

/// Job status data class
class RelationshipJobStatus {
  final String jobId;
  final JobStatus status;
  final JobProgress progress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Result fields (available when status is complete)
  final String? relationshipId;
  final String? summaryShort;
  final Map<String, dynamic>? stats;

  // Mismatch detection (MODULE 3)
  final bool? mismatchDetected;
  final String? mismatchReason;
  final String? suggestedAction;

  // Error fields (available when status is failed)
  final String? errorMessage;
  final String? errorStack;

  RelationshipJobStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    this.createdAt,
    this.updatedAt,
    this.relationshipId,
    this.summaryShort,
    this.stats,
    this.mismatchDetected,
    this.mismatchReason,
    this.suggestedAction,
    this.errorMessage,
    this.errorStack,
  });

  factory RelationshipJobStatus.fromFirestore(
    Map<String, dynamic> data,
    String jobId,
  ) {
    try {
      // Parse status
      final statusString = data['status'] as String? ?? 'queued';
      JobStatus status;
      switch (statusString) {
        case 'queued':
          status = JobStatus.queued;
          break;
        case 'processing':
          status = JobStatus.processing;
          break;
        case 'complete':
          status = JobStatus.complete;
          break;
        case 'failed':
          status = JobStatus.failed;
          break;
        default:
          status = JobStatus.queued;
      }

      // Parse progress
      final progressData = data['progress'] as Map<String, dynamic>?;
      final progress = progressData != null
          ? JobProgress.fromMap(progressData)
          : JobProgress(step: 'queued', percent: 0);

      // Parse timestamps
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

      // Parse result - handle both old and new formats
      final resultData = data['result'];
      String? relationshipId;
      String? summaryShort;
      Map<String, dynamic>? stats;

      if (resultData is Map<String, dynamic>) {
        relationshipId = resultData['relationshipId'] as String?;

        // summaryShort can be either String or Map
        final summaryShortData = resultData['summaryShort'];
        if (summaryShortData is String) {
          summaryShort = summaryShortData;
        } else if (summaryShortData is Map<String, dynamic>) {
          // Extract the actual summary text from the structured data
          summaryShort = summaryShortData['shortSummary'] as String? ??
              summaryShortData['summary'] as String? ??
              'İlişki analizi tamamlandı';
        }

        stats = resultData['stats'] as Map<String, dynamic>?;
      }

      // Parse error - handle both old and new formats
      final errorData = data['error'];
      String? errorMessage;
      String? errorStack;

      if (errorData is Map<String, dynamic>) {
        errorMessage = errorData['message'] as String?;
        errorStack = errorData['stack'] as String?;
      } else if (errorData is String) {
        errorMessage = errorData;
      }

      // Parse mismatch detection - be defensive about types
      final mismatchDetected = data['mismatchDetected'] as bool?;

      // Handle mismatchReason - can be String or Map
      String? mismatchReason;
      final mismatchReasonData = data['mismatchReason'];
      if (mismatchReasonData is String) {
        mismatchReason = mismatchReasonData;
      } else if (mismatchReasonData is Map) {
        // If it's a map, try to extract a message
        mismatchReason = (mismatchReasonData as Map<String, dynamic>)['message']
                as String? ??
            (mismatchReasonData as Map<String, dynamic>)['reason'] as String? ??
            'Mismatch detected';
      }

      // Handle suggestedAction - can be String or Map
      String? suggestedAction;
      final suggestedActionData = data['suggestedAction'];
      if (suggestedActionData is String) {
        suggestedAction = suggestedActionData;
      } else if (suggestedActionData is Map) {
        suggestedAction = (suggestedActionData
                as Map<String, dynamic>)['action'] as String? ??
            'create_new';
      }

      return RelationshipJobStatus(
        jobId: jobId,
        status: status,
        progress: progress,
        createdAt: createdAt,
        updatedAt: updatedAt,
        relationshipId: relationshipId,
        summaryShort: summaryShort,
        stats: stats,
        mismatchDetected: mismatchDetected,
        mismatchReason: mismatchReason,
        suggestedAction: suggestedAction,
        errorMessage: errorMessage,
        errorStack: errorStack,
      );
    } catch (e) {
      print('Error parsing job status: $e');
      print('Job data: $data');

      // Return a safe fallback
      return RelationshipJobStatus(
        jobId: jobId,
        status: JobStatus.queued,
        progress: JobProgress(step: 'error', percent: 0),
        errorMessage: 'Failed to parse job status: ${e.toString()}',
      );
    }
  }

  /// Check if job is still in progress
  bool get isInProgress =>
      status == JobStatus.queued || status == JobStatus.processing;

  /// Check if job is complete
  bool get isComplete => status == JobStatus.complete;

  /// Check if job failed
  bool get isFailed => status == JobStatus.failed;

  /// Get user-friendly status message
  String get statusMessage {
    switch (status) {
      case JobStatus.queued:
        return 'Sırada bekliyor...';
      case JobStatus.processing:
        return progress.stepMessage;
      case JobStatus.complete:
        if (mismatchDetected == true) {
          return 'Farklı bir ilişki tespit edildi';
        }
        return 'Analiz tamamlandı';
      case JobStatus.failed:
        return 'Hata: ${errorMessage ?? "Bilinmeyen hata"}';
      case JobStatus.notFound:
        return 'İş bulunamadı';
    }
  }
}

/// Job progress data class
class JobProgress {
  final String step;
  final int percent;
  final int? processedChunks;
  final int? totalChunks;

  JobProgress({
    required this.step,
    required this.percent,
    this.processedChunks,
    this.totalChunks,
  });

  factory JobProgress.fromMap(Map<String, dynamic> data) {
    return JobProgress(
      step: data['step'] as String? ?? 'unknown',
      percent: data['percent'] as int? ?? 0,
      processedChunks: data['processedChunks'] as int?,
      totalChunks: data['totalChunks'] as int?,
    );
  }

  /// Get user-friendly progress message
  String get stepMessage {
    switch (step) {
      case 'downloading':
        return 'Dosya indiriliyor...';
      case 'extracting':
        return 'Dosya çıkarılıyor...';
      case 'processing':
        if (processedChunks != null && totalChunks != null) {
          return 'İşleniyor... ($processedChunks/$totalChunks)';
        }
        return 'Analiz ediliyor...';
      case 'complete':
        return 'Tamamlandı';
      case 'failed':
        return 'Başarısız oldu';
      default:
        return 'Hazırlanıyor...';
    }
  }
}
