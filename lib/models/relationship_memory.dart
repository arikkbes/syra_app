/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP MEMORY MODEL
/// ═══════════════════════════════════════════════════════════════
/// Model for stored relationship memory data
/// ═══════════════════════════════════════════════════════════════

class RelationshipMemory {
  final int? totalMessages;
  final String? startDate;
  final String? endDate;
  final String? shortSummary;
  final List<dynamic>? energyTimeline;
  final List<dynamic>? keyMoments;
  final Map<String, dynamic>? stats;
  final String? lastUploadAt;
  final String? source;
  final String? lastAnalysisId;
  final bool isActive;

  RelationshipMemory({
    this.totalMessages,
    this.startDate,
    this.endDate,
    this.shortSummary,
    this.energyTimeline,
    this.keyMoments,
    this.stats,
    this.lastUploadAt,
    this.source,
    this.lastAnalysisId,
    this.isActive = true,
  });

  factory RelationshipMemory.fromFirestore(Map<String, dynamic> data) {
    return RelationshipMemory(
      totalMessages: data['totalMessages'] as int?,
      startDate: data['startDate'] as String?,
      endDate: data['endDate'] as String?,
      shortSummary: data['shortSummary'] as String?,
      energyTimeline: data['energyTimeline'] as List<dynamic>?,
      keyMoments: data['keyMoments'] as List<dynamic>?,
      stats: data['stats'] as Map<String, dynamic>?,
      lastUploadAt: data['lastUploadAt'] as String?,
      source: data['source'] as String?,
      lastAnalysisId: data['lastAnalysisId'] as String?,
      isActive: data['isActive'] ?? true, // Default to true if missing
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (totalMessages != null) 'totalMessages': totalMessages,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (shortSummary != null) 'shortSummary': shortSummary,
      if (energyTimeline != null) 'energyTimeline': energyTimeline,
      if (keyMoments != null) 'keyMoments': keyMoments,
      if (stats != null) 'stats': stats,
      if (lastUploadAt != null) 'lastUploadAt': lastUploadAt,
      if (source != null) 'source': source,
      if (lastAnalysisId != null) 'lastAnalysisId': lastAnalysisId,
      'isActive': isActive,
    };
  }
}
