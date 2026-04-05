import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

struct ChatStatsSnapshot {
    var focusScore: Int = 0
    var deepWorkMinutes: Int = 0
    var distractionMinutes: Int = 0
    var shallowWorkMinutes: Int = 0
    var communicationMinutes: Int = 0
}

enum ChatConnectionStatus {
    case checking
    case online
    case offline

    var label: String {
        switch self {
        case .checking: return "Checking"
        case .online: return "Connected"
        case .offline: return "Offline"
        }
    }

    var symbol: String {
        switch self {
        case .checking: return "bolt.horizontal.circle"
        case .online: return "checkmark.seal.fill"
        case .offline: return "wifi.slash"
        }
    }

    var tint: Color {
        switch self {
        case .checking: return TigerPalette.gold
        case .online: return TigerPalette.jade
        case .offline: return TigerPalette.coral
        }
    }
}

struct ChatView: View {
    @Bindable var appState: AppState

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isSending = false
    @State private var isLoading = true
    @State private var scrollProxy: ScrollViewProxy?
    @State private var connectionStatus: ChatConnectionStatus = .checking
    @State private var stats = ChatStatsSnapshot()
    @State private var lastUpdatedAt: Date?
    @State private var statusMessage = "Tiger Mom is waiting."

    private let suggestedPrompts = [
        "How am I doing today?",
        "What should I focus on next?",
        "Be brutally honest with me.",
        "What keeps distracting me?"
    ]

    var body: some View {
        VStack(spacing: 18) {
            header

            HStack(alignment: .top, spacing: 20) {
                conversationStage
                contextRail
                    .frame(width: 320)
            }
        }
        .padding(22)
        .task {
            await refreshAll()
        }
    }

    private var header: some View {
        TigerPanel(padding: 24, cornerRadius: 26, emphasis: 1.0) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    TigerSectionHeader(
                        eyebrow: "Conversation",
                        title: "Talk to Tiger Mom",
                        detail: statusMessage
                    )

                    HStack(spacing: 10) {
                        ConnectionBadge(status: connectionStatus)

                        if let lastUpdatedAt {
                            TigerCapsuleBadge(
                                title: "Updated \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))",
                                symbol: "clock.fill",
                                tint: TigerPalette.textSecondary
                            )
                        }
                    }
                }

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        Task { await refreshAll() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(TigerButtonStyle(tint: TigerPalette.gold, prominence: .quiet))

                    Button {
                        startFreshChat()
                    } label: {
                        Label("New Thread", systemImage: "plus.bubble.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .buttonStyle(TigerButtonStyle(tint: TigerPalette.jade, prominence: .secondary))
                }
            }
        }
    }

    private var conversationStage: some View {
        TigerPanel(padding: 0, cornerRadius: 28, emphasis: 1.0) {
            VStack(spacing: 0) {
                promptRail
                    .padding(20)

                TigerDivider()

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            if isLoading {
                                loadingState
                                    .padding(.top, 80)
                            } else if messages.isEmpty && !isSending {
                                emptyState
                                    .padding(.top, 48)
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
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                    }
                    .onAppear { scrollProxy = proxy }
                    .onChange(of: messages.count) { scrollToBottom() }
                    .onChange(of: isSending) { scrollToBottom() }
                }

                TigerDivider()

                composer
                    .padding(20)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 700)
    }

    private var promptRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick prompts")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(TigerPalette.textMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestedPrompts, id: \.self) { prompt in
                        Button {
                            inputText = prompt
                        } label: {
                            Text(prompt)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(TigerPillButtonStyle())
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.08), TigerPalette.amber.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)

                TigerMark(size: 68, framed: false)
            }

            VStack(spacing: 10) {
                Text("Ask for the truth.")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text("Tiger Mom can read your local activity history and respond with actual context, not generic advice.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(TigerPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Checking in with Tiger Mom...")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(TigerPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 14) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15))
                    .foregroundColor(TigerPalette.textPrimary)
                    .frame(minHeight: 68, maxHeight: 120)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                            )
                    )

                if inputText.isEmpty {
                    Text("Ask Tiger Mom anything about your day...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TigerPalette.textMuted)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                }
            }

            VStack(spacing: 10) {
                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(
                    TigerButtonStyle(
                        tint: canSend ? TigerPalette.gold : TigerPalette.textSecondary,
                        prominence: canSend ? .primary : .quiet,
                        cornerRadius: 21
                    )
                )
                .disabled(!canSend)
                .keyboardShortcut(.return, modifiers: [.command])

                Text("Cmd↩")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(TigerPalette.textMuted)
            }
        }
    }

    private var contextRail: some View {
        VStack(spacing: 18) {
            TigerPanel(padding: 20, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    TigerSectionHeader(
                        eyebrow: "Today",
                        title: "\(stats.focusScore) focus",
                        detail: "A live snapshot behind the conversation."
                    )

                    chatStatRow(label: "Deep work", value: stats.deepWorkMinutes.tigerDuration, tint: TigerPalette.jade)
                    chatStatRow(label: "Distraction", value: stats.distractionMinutes.tigerDuration, tint: TigerPalette.coral)
                    chatStatRow(label: "Shallow work", value: stats.shallowWorkMinutes.tigerDuration, tint: TigerPalette.gold)
                    chatStatRow(label: "Communication", value: stats.communicationMinutes.tigerDuration, tint: TigerPalette.mist)
                }
            }

            TigerPanel(padding: 20, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    TigerSectionHeader(
                        eyebrow: "Presence",
                        title: appState.isTracking ? "Tiger Mom is watching." : "Tracking is paused.",
                        detail: "The interface reflects the app’s live local state."
                    )

                    sessionLine(label: "Tracking", value: appState.isTracking ? "On" : "Paused")
                    sessionLine(label: "Idle", value: appState.isIdle ? "Yes" : "No")
                    sessionLine(label: "Captures today", value: "\(appState.captureCountToday)")
                    sessionLine(
                        label: "Last capture",
                        value: appState.lastCaptureTime?.formatted(date: .omitted, time: .shortened) ?? "None"
                    )
                }
            }

            TigerPanel(padding: 20, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    TigerSectionHeader(
                        eyebrow: "Notes",
                        title: "Conversation rules",
                        detail: "Designed to feel natural while staying rooted in your local data."
                    )

                    Text(connectionStatus == .online
                         ? "Tiger Mom can read recent tracked activity and saved history to respond with specifics."
                         : "The sidecar looks offline. Start the backend to restore history, analytics, and live replies.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(TigerPalette.textSecondary)
                        .lineSpacing(4)

                    Text("Send with Command-Return.")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(TigerPalette.textMuted)
                }
            }

            Spacer()
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        let userMsg = ChatMessage(id: UUID().uuidString, content: text, isUser: true, timestamp: Date())
        messages.append(userMsg)
        inputText = ""
        isSending = true
        statusMessage = "Tiger Mom is typing..."

        do {
            let response = try await APIClient.shared.chat(message: text)
            let reply = response["reply"] as? String ?? "..."
            messages.append(ChatMessage(id: UUID().uuidString, content: reply, isUser: false, timestamp: Date()))
            connectionStatus = .online
            lastUpdatedAt = Date()
            statusMessage = "A direct line into your local accountability layer."
            await loadStats()
        } catch {
            connectionStatus = .offline
            statusMessage = "Backend unavailable. Start the sidecar to chat."
            messages.append(
                ChatMessage(
                    id: UUID().uuidString,
                    content: "Tiger Mom is unavailable right now. Make sure the backend is running.",
                    isUser: false,
                    timestamp: Date()
                )
            )
        }

        isSending = false
    }

    private func refreshAll() async {
        isLoading = true
        await loadConnectionState()
        await loadHistory()
        await loadStats()
        isLoading = false
        lastUpdatedAt = Date()
    }

    private func loadConnectionState() async {
        do {
            _ = try await APIClient.shared.health()
            connectionStatus = .online
            statusMessage = messages.isEmpty
                ? "Tiger Mom is online and ready to judge with context."
                : "Conversation synced with the local sidecar."
        } catch {
            connectionStatus = .offline
            statusMessage = "Sidecar offline. Start the backend to load history and send messages."
        }
    }

    private func loadHistory() async {
        do {
            let response = try await APIClient.shared.chatHistory()
            guard let history = response["messages"] as? [[String: Any]] else { return }

            messages = history.compactMap { msg in
                guard let id = msg["id"] as? String,
                      let content = msg["content"] as? String,
                      let isUser = msg["is_user"] as? Bool else { return nil }

                let timestamp = (msg["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
                return ChatMessage(id: id, content: content, isUser: isUser, timestamp: timestamp)
            }
        } catch {
            if messages.isEmpty {
                messages = []
            }
        }
    }

    private func loadStats() async {
        do {
            let response = try await APIClient.shared.analyticsDaily(includeReport: false)
            stats.focusScore = response["focus_score"] as? Int ?? 0
            stats.deepWorkMinutes = response["deep_work_minutes"] as? Int ?? 0
            stats.distractionMinutes = response["distraction_minutes"] as? Int ?? 0
            stats.shallowWorkMinutes = response["shallow_work_minutes"] as? Int ?? 0
            stats.communicationMinutes = response["communication_minutes"] as? Int ?? 0
        } catch {
            stats = ChatStatsSnapshot()
        }
    }

    private func startFreshChat() {
        messages = []
        inputText = ""
        statusMessage = "Fresh local thread. Saved history still exists unless you clear app data."
    }

    private func scrollToBottom() {
        guard let proxy = scrollProxy else { return }
        let target = isSending ? "typing" : messages.last?.id
        if let target {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(target, anchor: .bottom)
            }
        }
    }

    private func chatStatRow(label: String, value: String, tint: Color) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(TigerPalette.textSecondary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(TigerPalette.textPrimary)
        }
    }

    private func sessionLine(label: String, value: String) -> some View {
        TigerLabeledValueRow(label: label, value: value)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if !message.isUser {
                TigerInlineGlyph(size: 34)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(message.isUser ? TigerPalette.background : TigerPalette.textPrimary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(TigerPalette.gold.opacity(0.24))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .strokeBorder(TigerPalette.gold.opacity(0.22), lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white.opacity(0.045))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            }
                        }
                    )

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(TigerPalette.textMuted)
            }
            .frame(maxWidth: 520, alignment: message.isUser ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

struct ConnectionBadge: View {
    let status: ChatConnectionStatus

    var body: some View {
        TigerCapsuleBadge(title: status.label, symbol: status.symbol, tint: status.tint)
    }
}

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 12) {
            TigerInlineGlyph(size: 34)

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(TigerPalette.textSecondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(phase == Double(index) ? 1.2 : 0.7)
                        .opacity(phase == Double(index) ? 1 : 0.35)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.045))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            while true {
                withAnimation(.easeInOut(duration: 0.45)) {
                    phase = (phase + 1).truncatingRemainder(dividingBy: 3)
                }
                try? await Task.sleep(for: .milliseconds(450))
            }
        }
    }
}
