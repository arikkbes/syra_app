/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP ANALYSIS RESULT MODEL
/// ═══════════════════════════════════════════════════════════════
/// Model for WhatsApp chat analysis results
/// ═══════════════════════════════════════════════════════════════

class RelationshipAnalysisResult {
  final int totalMessages;
  final DateTime? startDate;
  final DateTime? endDate;
  final String shortSummary;
  final List<EnergyPoint> energyTimeline;
  final List<KeyMoment> keyMoments;

  RelationshipAnalysisResult({
    required this.totalMessages,
    this.startDate,
    this.endDate,
    required this.shortSummary,
    required this.energyTimeline,
    required this.keyMoments,
  });

  factory RelationshipAnalysisResult.fromJson(Map<String, dynamic> json) {
    return RelationshipAnalysisResult(
      totalMessages: json['totalMessages'] as int? ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      shortSummary: json['shortSummary'] as String? ?? '',
      energyTimeline: (json['energyTimeline'] as List<dynamic>?)
              ?.map((e) => EnergyPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keyMoments: (json['keyMoments'] as List<dynamic>?)
              ?.map((e) => KeyMoment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMessages': totalMessages,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'shortSummary': shortSummary,
      'energyTimeline': energyTimeline.map((e) => e.toJson()).toList(),
      'keyMoments': keyMoments.map((e) => e.toJson()).toList(),
    };
  }
}

class EnergyPoint {
  final String label;
  final String level; // "low", "medium", "high"
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
