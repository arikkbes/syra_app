// Message.swift
// iOS-FULL-2: Message model for chat

import Foundation

struct Message: Identifiable, Equatable {
    let id: String
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(
        id: String = UUID().uuidString,
        text: String,
        isUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - Mock Data
extension Message {
    static let mockMessages: [Message] = [
        Message(
            text: "Merhaba! SYRA ile tanışmana sevindim. İlişkilerinde sana nasıl yardımcı olabilirim?",
            isUser: false,
            timestamp: Date().addingTimeInterval(-3600)
        ),
        Message(
            text: "Sevgilimle bir sorunum var, tavsiye alabilir miyim?",
            isUser: true,
            timestamp: Date().addingTimeInterval(-3500)
        ),
        Message(
            text: "Tabii ki! Durumu daha iyi anlayabilmem için biraz daha detay verebilir misin? Ne tür bir sorun yaşıyorsunuz?",
            isUser: false,
            timestamp: Date().addingTimeInterval(-3400)
        ),
    ]
}
