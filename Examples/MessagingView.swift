import Foundation

// MARK: - Message Model

struct Message: Identifiable, Sendable {
    let id: String
    let text: String
    let sender: String
    let timestamp: Date
    let isFromCurrentUser: Bool

    init(id: String = UUID().uuidString, text: String, sender: String, isFromCurrentUser: Bool = false) {
        self.id = id
        self.text = text
        self.sender = sender
        self.timestamp = Date()
        self.isFromCurrentUser = isFromCurrentUser
    }
}

// MARK: - Messaging State (using Phase 9 @Observable)

@Observable
@MainActor
class MessagingState {
    var messages: [Message] = [
        Message(text: "Hey! How's it going?", sender: "Alice"),
        Message(text: "Pretty good! Just working on some SwiftUI stuff", sender: "You", isFromCurrentUser: true),
        Message(text: "Nice! What are you building?", sender: "Alice"),
        Message(text: "A messaging app with Raven - SwiftUI to DOM!", sender: "You", isFromCurrentUser: true),
        Message(text: "That sounds awesome! 🎉", sender: "Alice"),
    ]

    var newMessageText: String = ""
    var isTyping: Bool = false

    func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let message = Message(
            text: newMessageText,
            sender: "You",
            isFromCurrentUser: true
        )
        messages.append(message)
        newMessageText = ""

        // Simulate response after 1.5 seconds
        // In real app, this would be async
        simulateResponse()
    }

    func simulateResponse() {
        isTyping = true
        // In real app: DispatchQueue.main.asyncAfter or Task.sleep
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(message.isFromCurrentUser ? Color.blue : Color(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
                    .foregroundColor(message.isFromCurrentUser ? .white : .black)
                    .cornerRadius(16)
                    .lineLimit(nil)
                    .multilineTextAlignment(message.isFromCurrentUser ? .trailing : .leading)

                Text(message.sender)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
            }
            .frame(maxWidth: 250, alignment: message.isFromCurrentUser ? .trailing : .leading)

            if !message.isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Message Input View

struct MessageInputView: View {
    @Bindable var state: MessagingState

    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $state.newMessageText)
                .padding(12)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0))
                .cornerRadius(20)
                .onChange(of: state.newMessageText) { _ in
                    // Could trigger typing indicator
                }

            Button("Send") {
                state.sendMessage()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(state.newMessageText.trimmingCharacters(in: .whitespaces).isEmpty ?
                       Color(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
            .disabled(state.newMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Main Messaging View

struct MessagingView: View {
    @Bindable var state: MessagingState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Messages")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Text("\(state.messages.count) messages")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
            }
            .padding(16)
            .background(Color(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0))

            Divider()

            // Messages List
            if state.messages.isEmpty {
                ContentUnavailableView(
                    "No Messages",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Start a conversation by sending a message below.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(state.messages) { message in
                            MessageBubbleView(message: message)
                                .onAppear {
                                    // Could mark as read
                                }
                        }

                        if state.isTyping {
                            HStack {
                                Text("Alice is typing...")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
                                    .padding(.horizontal, 16)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
            }

            Divider()

            // Message Input
            MessageInputView(state: state)
        }
        .background(Color.white)
    }
}

// MARK: - App Entry Point

struct MessagingApp: View {
    @State private var messagingState = MessagingState()

    var body: some View {
        MessagingView(state: messagingState)
            .frame(maxWidth: 600)
            .onAppear {
                // Could load messages from storage
            }
    }
}

// MARK: - Preview

#if DEBUG
struct MessagingView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingApp()
    }
}
#endif
