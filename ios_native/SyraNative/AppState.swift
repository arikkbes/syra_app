// AppState.swift
// iOS-FULL-2: Simple local state management (no Firebase yet)

import SwiftUI

/// App-wide state management
/// Manages chat sessions and current selection (local mock data only)
class AppState: ObservableObject {
    @Published var chatSessions: [ChatSession]
    @Published var selectedSessionId: String?
    
    init() {
        // Initialize with mock data
        self.chatSessions = ChatSession.mockSessions
        self.selectedSessionId = chatSessions.first?.id
    }
    
    // MARK: - Computed Properties
    
    var selectedSession: ChatSession? {
        guard let id = selectedSessionId else { return nil }
        return chatSessions.first { $0.id == id }
    }
    
    var selectedMessages: [Message] {
        selectedSession?.messages ?? []
    }
    
    // MARK: - Actions
    
    func selectSession(_ session: ChatSession) {
        SyraHaptics.selection()
        selectedSessionId = session.id
    }
    
    func createNewChat() {
        SyraHaptics.light()
        let newSession = ChatSession(
            title: "Yeni Sohbet",
            lastMessage: "",
            timestamp: Date(),
            messages: [
                Message(
                    text: "Merhaba! SYRA ile tanışmana sevindim. İlişkilerinde sana nasıl yardımcı olabilirim?",
                    isUser: false
                )
            ]
        )
        chatSessions.insert(newSession, at: 0)
        selectedSessionId = newSession.id
    }
    
    func renameSession(_ session: ChatSession, newTitle: String) {
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[index].title = newTitle
        }
    }
    
    func deleteSession(_ session: ChatSession) {
        SyraHaptics.light()
        chatSessions.removeAll { $0.id == session.id }
        
        // Select first session if deleted was selected
        if selectedSessionId == session.id {
            selectedSessionId = chatSessions.first?.id
        }
    }
    
    func sendMessage(_ text: String) {
        guard let sessionId = selectedSessionId,
              let index = chatSessions.firstIndex(where: { $0.id == sessionId }) else {
            return
        }
        
        SyraHaptics.success()
        
        // Add user message
        let userMessage = Message(text: text, isUser: true)
        chatSessions[index].messages.append(userMessage)
        chatSessions[index].lastMessage = text
        chatSessions[index].timestamp = Date()
        
        // Simulate assistant response after delay (mock)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self,
                  let index = self.chatSessions.firstIndex(where: { $0.id == sessionId }) else {
                return
            }
            
            let mockResponses = [
                "Anlıyorum. Biraz daha detay verir misin?",
                "Bu konuda sana yardımcı olmak isterim. Daha fazla bilgi alabilir miyim?",
                "İlginç bir durum. Senin için en iyi yaklaşımı birlikte bulalım.",
                "Seni dinliyorum. Devam et lütfen.",
            ]
            
            let response = Message(
                text: mockResponses.randomElement() ?? "Devam et...",
                isUser: false
            )
            
            self.chatSessions[index].messages.append(response)
            self.chatSessions[index].lastMessage = response.text
            self.chatSessions[index].timestamp = Date()
        }
    }
}
