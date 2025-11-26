// ═══════════════════════════════════════════════════════════════
// CHAT SESSION MODEL
// ═══════════════════════════════════════════════════════════════
// Multi-chat özelliği için sohbet oturumu modeli
// ═══════════════════════════════════════════════════════════════

class ChatSession {
  final String id;
  final String title;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.title,
    this.lastMessage,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.messageCount = 0,
  });

  // Firestore'dan gelen Map'i ChatSession nesnesine çevir
  factory ChatSession.fromMap(Map<String, dynamic> map, String docId) {
    return ChatSession(
      id: docId,
      title: map['title'] ?? 'Yeni Sohbet',
      lastMessage: map['lastMessage'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      lastUpdatedAt: map['lastUpdatedAt']?.toDate() ?? DateTime.now(),
      messageCount: map['messageCount'] ?? 0,
    );
  }

  // ChatSession nesnesini Firestore Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'lastMessage': lastMessage,
      'createdAt': createdAt,
      'lastUpdatedAt': lastUpdatedAt,
      'messageCount': messageCount,
    };
  }

  // Copy with method
  ChatSession copyWith({
    String? id,
    String? title,
    String? lastMessage,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    int? messageCount,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}
