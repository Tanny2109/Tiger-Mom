import SwiftUI

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chat View

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isSending = false
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let suggestedPrompts = [
        "How was my morning?",
        "Am I on track today?",
        "What should I focus on next?",
        "Give me my weekly report"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chat")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    messages.removeAll()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.bubble")
                            .font(.system(size: 12, weight: .medium))
                        Text("New Chat")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Messages area
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        if messages.isEmpty && !isSending {
                            emptyState
                                .padding(.top, 60)
                        }

                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if isSending {
                            TypingIndicator()
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .onAppear { scrollProxy = proxy }
                .onChange(of: messages.count) {
                    scrollToBottom()
                }
                .onChange(of: isSending) {
                    scrollToBottom()
                }
            }

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Input bar
            inputBar
        }
        .background(Color(hex: 0x07070A))
        .task {
            await loadHistory()
        }
    }

    // MARK: - Empty State with Suggested Prompts

    private var emptyState: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("🐯")
                    .font(.system(size: 44))
                Text("Ask Tiger Mom anything")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                Text("Get coaching, check your progress, or just chat.")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.25))
            }

            // Suggested prompts
            VStack(spacing: 8) {
                ForEach(suggestedPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        Task { await sendMessage() }
                    } label: {
                        HStack {
                            Text(prompt)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: 0xF59E0B).opacity(0.4))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 340)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Tiger Mom...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                )
                .onSubmit {
                    Task { await sendMessage() }
                }

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 15))
                    .foregroundColor(canSend ? Color(hex: 0x07070A) : .white.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(canSend ? Color(hex: 0xF59E0B) : Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(hex: 0x0E0E14))
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isSending
    }

    // MARK: - Send & Load

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isSending else { return }

        let userMsg = ChatMessage(
            id: UUID().uuidString,
            content: text,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMsg)
        inputText = ""
        isSending = true

        do {
            let response = try await APIClient.shared.chat(message: text)
            let reply = response["reply"] as? String ?? "..."
            let momMsg = ChatMessage(
                id: UUID().uuidString,
                content: reply,
                isUser: false,
                timestamp: Date()
            )
            messages.append(momMsg)
        } catch {
            let errorMsg = ChatMessage(
                id: UUID().uuidString,
                content: "Tiger Mom is unavailable right now. Make sure the backend is running.",
                isUser: false,
                timestamp: Date()
            )
            messages.append(errorMsg)
        }

        isSending = false
    }

    private func loadHistory() async {
        do {
            let response = try await APIClient.shared.chatHistory()
            guard let history = response["messages"] as? [[String: Any]] else { return }

            let loaded = history.compactMap { msg -> ChatMessage? in
                guard let id = msg["id"] as? String,
                      let content = msg["content"] as? String,
                      let isUser = msg["is_user"] as? Bool else { return nil }
                let ts = (msg["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
                return ChatMessage(id: id, content: content, isUser: isUser, timestamp: ts)
            }
            if !loaded.isEmpty {
                messages = loaded
            }
        } catch {
            // No history available — start fresh
        }
    }

    private func scrollToBottom() {
        guard let proxy = scrollProxy else { return }
        let target = isSending ? "typing" : messages.last?.id
        if let target {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(target, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isUser {
                // Tiger Mom avatar
                Text("🐯")
                    .font(.system(size: 18))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(message.isUser ? Color(hex: 0x07070A) : .white.opacity(0.85))
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isUser ? Color(hex: 0xF59E0B) : Color(hex: 0x1A1A24))
                    )

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.2))
            }
            .frame(maxWidth: 400, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                // Spacer for right alignment is handled by the frame
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("🐯")
                .font(.system(size: 18))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.06)))

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 7, height: 7)
                        .offset(y: dotOffset(for: i))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: 0x1A1A24))
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }

    private func dotOffset(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.15
        let progress = max(0, min(1, phase - delay))
        return -4 * sin(progress * .pi)
    }
}
