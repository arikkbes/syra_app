/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP MEMORY MODEL V2
/// ═══════════════════════════════════════════════════════════════
/// Model for stored relationship memory data
/// Updated for new chunked pipeline architecture
/// ═══════════════════════════════════════════════════════════════
library;

class RelationshipMemory {
  final String? id;
  final List<String> speakers;
  final int? totalMessages;
  final int? totalChunks;
  final String? startDate;
  final String? endDate;
  final String? shortSummary;
  final Map<String, dynamic>? personalities;
  final Map<String, dynamic>? dynamics;
  final Map<String, dynamic>? patterns;
  final String? createdAt;
  final String? updatedAt;
  final bool isActive;
  final String? selfParticipant;
  final String? partnerParticipant;

  RelationshipMemory({
    this.id,
    this.speakers = const [],
    this.totalMessages,
    this.totalChunks,
    this.startDate,
    this.endDate,
    this.shortSummary,
    this.personalities,
    this.dynamics,
    this.patterns,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.selfParticipant,
    this.partnerParticipant,
  });

  /// Parse from new V2 Firestore structure
  /// Path: relationships/{uid}/relations/{relationshipId}
  factory RelationshipMemory.fromFirestore(Map<String, dynamic> data,
      {String? docId}) {
    // Extract masterSummary fields - TOLERANT PARSING
    Map<String, dynamic> masterSummary = {};
    String? shortSummaryText;

    final rawMasterSummary = data['masterSummary'];
    if (rawMasterSummary is Map) {
      // masterSummary is an object - use it directly
      masterSummary = Map<String, dynamic>.from(rawMasterSummary);
      shortSummaryText = masterSummary['shortSummary'] as String?;
    } else if (rawMasterSummary is String) {
      // masterSummary is a plain string - treat it as shortSummary
      shortSummaryText = rawMasterSummary;
    }
    // else: null or other type => leave masterSummary as {}

    final dateRange = data['dateRange'] as Map<String, dynamic>? ?? {};

    return RelationshipMemory(
      id: docId ?? data['id'] as String?,
      speakers: (data['speakers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalMessages: data['totalMessages'] as int?,
      totalChunks: data['totalChunks'] as int?,
      startDate: dateRange['start'] as String?,
      endDate: dateRange['end'] as String?,
      shortSummary: shortSummaryText,
      personalities: masterSummary['personalities'] as Map<String, dynamic>?,
      dynamics: masterSummary['dynamics'] as Map<String, dynamic>?,
      patterns: masterSummary['patterns'] as Map<String, dynamic>?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      isActive: data['isActive'] ?? true,
      selfParticipant: data['selfParticipant'] as String?,
      partnerParticipant: data['partnerParticipant'] as String?,
    );
  }

  /// Legacy parser for old format (backward compatibility)
  factory RelationshipMemory.fromLegacy(Map<String, dynamic> data) {
    return RelationshipMemory(
      totalMessages: data['totalMessages'] as int?,
      startDate: data['startDate'] as String?,
      endDate: data['endDate'] as String?,
      shortSummary: data['shortSummary'] as String?,
      isActive: data['isActive'] ?? true,
    );
  }

  static String? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    // Firestore Timestamp
    if (value is Map && value['_seconds'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as int) * 1000,
      ).toIso8601String();
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'speakers': speakers,
      if (totalMessages != null) 'totalMessages': totalMessages,
      if (totalChunks != null) 'totalChunks': totalChunks,
      if (startDate != null || endDate != null)
        'dateRange': {
          if (startDate != null) 'start': startDate,
          if (endDate != null) 'end': endDate,
        },
      'masterSummary': {
        if (shortSummary != null) 'shortSummary': shortSummary,
        if (personalities != null) 'personalities': personalities,
        if (dynamics != null) 'dynamics': dynamics,
        if (patterns != null) 'patterns': patterns,
      },
      'isActive': isActive,
    };
  }

  /// Get formatted date range for display
  String get dateRangeFormatted {
    if (startDate == null && endDate == null) return '';

    String formatDate(String? isoDate) {
      if (isoDate == null) return '?';
      try {
        final date = DateTime.parse(isoDate);
        return '${date.day}.${date.month}.${date.year}';
      } catch (e) {
        return isoDate;
      }
    }

    return '${formatDate(startDate)} — ${formatDate(endDate)}';
  }

  /// Get speaker names as display string
  String get speakersFormatted {
    if (speakers.isEmpty) return 'Bilinmiyor';
    return speakers.join(' & ');
  }
}
