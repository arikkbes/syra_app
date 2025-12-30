/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP ANALYSIS RESULT MODEL V2
/// ═══════════════════════════════════════════════════════════════
/// Model for WhatsApp chat analysis results
/// Updated for new chunked pipeline architecture
/// ═══════════════════════════════════════════════════════════════
library;

class RelationshipAnalysisResult {
  final String? relationshipId;
  final int totalMessages;
  final int totalChunks;
  final List<String> speakers;
  final String shortSummary;
  final Map<String, PersonalityProfile>? personalities;
  final RelationshipDynamics? dynamics;
  final RelationshipPatterns? patterns;
  final List<RelationshipPhase>? timeline;

  RelationshipAnalysisResult({
    this.relationshipId,
    required this.totalMessages,
    this.totalChunks = 0,
    this.speakers = const [],
    required this.shortSummary,
    this.personalities,
    this.dynamics,
    this.patterns,
    this.timeline,
  });

  /// Parse from new V2 backend response
  factory RelationshipAnalysisResult.fromV2Response({
    String? relationshipId,
    required Map<String, dynamic> summary,
    required Map<String, dynamic> stats,
  }) {
    // Parse personalities
    Map<String, PersonalityProfile>? personalities;
    if (summary['personalities'] != null && summary['personalities'] is Map) {
      personalities = {};
      (summary['personalities'] as Map<String, dynamic>).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          personalities![key] = PersonalityProfile.fromJson(value);
        }
      });
    }

    // Parse dynamics
    RelationshipDynamics? dynamics;
    if (summary['dynamics'] != null && summary['dynamics'] is Map) {
      dynamics = RelationshipDynamics.fromJson(summary['dynamics'] as Map<String, dynamic>);
    }

    // Parse patterns
    RelationshipPatterns? patterns;
    if (summary['patterns'] != null && summary['patterns'] is Map) {
      patterns = RelationshipPatterns.fromJson(summary['patterns'] as Map<String, dynamic>);
    }

    // Parse timeline
    List<RelationshipPhase>? timeline;
    if (summary['timeline'] != null && summary['timeline']['phases'] != null) {
      timeline = (summary['timeline']['phases'] as List<dynamic>)
          .map((e) => RelationshipPhase.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse speakers
    List<String> speakers = [];
    if (stats['speakers'] != null) {
      speakers = (stats['speakers'] as List<dynamic>).map((e) => e.toString()).toList();
    }

    return RelationshipAnalysisResult(
      relationshipId: relationshipId,
      totalMessages: stats['totalMessages'] as int? ?? 0,
      totalChunks: stats['totalChunks'] as int? ?? 0,
      speakers: speakers,
      shortSummary: summary['shortSummary'] as String? ?? 'Analiz tamamlandı.',
      personalities: personalities,
      dynamics: dynamics,
      patterns: patterns,
      timeline: timeline,
    );
  }

  /// Legacy parser for old format (backward compatibility)
  factory RelationshipAnalysisResult.fromJson(Map<String, dynamic> json) {
    return RelationshipAnalysisResult(
      totalMessages: json['totalMessages'] as int? ?? 0,
      shortSummary: json['shortSummary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (relationshipId != null) 'relationshipId': relationshipId,
      'totalMessages': totalMessages,
      'totalChunks': totalChunks,
      'speakers': speakers,
      'shortSummary': shortSummary,
    };
  }
}

class PersonalityProfile {
  final List<String> traits;
  final String? communicationStyle;
  final String? emotionalPattern;

  PersonalityProfile({
    this.traits = const [],
    this.communicationStyle,
    this.emotionalPattern,
  });

  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    return PersonalityProfile(
      traits: (json['traits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      communicationStyle: json['communicationStyle'] as String?,
      emotionalPattern: json['emotionalPattern'] as String?,
    );
  }
}

class RelationshipDynamics {
  final String? powerBalance;
  final String? attachmentPattern;
  final String? conflictStyle;
  final List<String> loveLanguages;

  RelationshipDynamics({
    this.powerBalance,
    this.attachmentPattern,
    this.conflictStyle,
    this.loveLanguages = const [],
  });

  factory RelationshipDynamics.fromJson(Map<String, dynamic> json) {
    return RelationshipDynamics(
      powerBalance: json['powerBalance'] as String?,
      attachmentPattern: json['attachmentPattern'] as String?,
      conflictStyle: json['conflictStyle'] as String?,
      loveLanguages: (json['loveLanguages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class RelationshipPatterns {
  final List<String> recurringIssues;
  final List<String> strengths;
  final List<String> redFlags;
  final List<String> greenFlags;

  RelationshipPatterns({
    this.recurringIssues = const [],
    this.strengths = const [],
    this.redFlags = const [],
    this.greenFlags = const [],
  });

  factory RelationshipPatterns.fromJson(Map<String, dynamic> json) {
    return RelationshipPatterns(
      recurringIssues: (json['recurringIssues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      strengths: (json['strengths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      redFlags: (json['redFlags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      greenFlags: (json['greenFlags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class RelationshipPhase {
  final String name;
  final String? period;
  final String? description;

  RelationshipPhase({
    required this.name,
    this.period,
    this.description,
  });

  factory RelationshipPhase.fromJson(Map<String, dynamic> json) {
    return RelationshipPhase(
      name: json['name'] as String? ?? '',
      period: json['period'] as String?,
      description: json['description'] as String?,
    );
  }
}

// Legacy classes for backward compatibility
class EnergyPoint {
  final String label;
  final String level;
  final String? description;

  EnergyPoint({
    required this.label,
    required this.level,
    this.description,
  });

  factory EnergyPoint.fromJson(Map<String, dynamic> json) {
    return EnergyPoint(
      label: json['label'] as String? ?? '',
      level: json['level'] as String? ?? 'medium',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'level': level,
      if (description != null) 'description': description,
    };
  }
}

class KeyMoment {
  final String title;
  final String description;
  final DateTime? date;

  KeyMoment({
    required this.title,
    required this.description,
    this.date,
  });

  factory KeyMoment.fromJson(Map<String, dynamic> json) {
    return KeyMoment(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (date != null) 'date': date!.toIso8601String(),
    };
  }
}
