// ChatSession.swift
// iOS-FULL-2: Chat session model

import Foundation

struct ChatSession: Identifiable, Equatable {
    let id: String
    var title: String
    var lastMessage: String
    var timestamp: Date
    var messages: [Message]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        lastMessage: String = "",
        timestamp: Date = Date(),
        messages: [Message] = []
    ) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.timestamp = timestamp
        self.messages = messages
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Mock Data
extension ChatSession {
    static let mockSessions: [ChatSession] = [
        ChatSession(
            title: "İlişki Tavsiyesi",
            lastMessage: "Tabii ki! Durumu daha iyi anlayabilmem için...",
            timestamp: Date().addingTimeInterval(-3400),
            messages: Message.mockMessages
        ),
        ChatSession(
            title: "Sevgilim ile sorunum var",
            lastMessage: "Bana yardımcı olabilir misin?",
            timestamp: Date().addingTimeInterval(-86400),
            messages: [
                Message(
                    text: "Merhaba, sevgilim ile aramda soğukluk var",
                    isUser: true
                ),
                Message(
                    text: "Anlıyorum. Ne zamandan beri bu soğukluğu hissediyorsun?",
                    isUser: false
                )
            ]
        ),
        ChatSession(
            title: "Yeni tanıştım",
            lastMessage: "İlk buluşma için tavsiyelerin neler?",
            timestamp: Date().addingTimeInterval(-259200),
            messages: []
        ),
    ]
}
