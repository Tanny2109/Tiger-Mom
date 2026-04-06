import SwiftUI

// MARK: - Data Models

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

// MARK: - Chat View

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

    private let suggestedPrompts = [
        "How am I doing today?",
        "What should I focus on next?",
        "Be brutally honest with me.",
        "What keeps distracting me?"
    ]

    var body: some View {
        HStack(alignment: .top, spacing: TigerSpacing.lg) {
            // Main conversation area
            conversationStage
            
            // Context sidebar
            contextRail
                .frame(width: 280)
        }
        .padding(TigerSpacing.xxl)
        .task {
            await refreshAll()
        }
    }

    // MARK: - Conversation Stage
    
    private var conversationStage: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            Spacer().frame(height: TigerSpacing.lg)
            
            // Chat content
            TigerPanel(padding: 0, cornerRadius: 16) {
                VStack(spacing: 0) {
                    // Quick prompts
                    promptRail
                        .padding(TigerSpacing.lg)
                    
                    TigerDivider()
                    
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: TigerSpacing.lg) {
                                if isLoading {
                                    loadingState
                                        .padding(.top, 60)
                                } else if messages.isEmpty && !isSending {
                                    emptyState
                                        .padding(.top, 40)
                                }

                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: message.isUser ? .trailing : .leading).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }

                                if isSending {
                                    TypingIndicator()
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, TigerSpacing.xl)
                            .padding(.vertical, TigerSpacing.lg)
                        }
                        .onAppear { scrollProxy = proxy }
                        .onChange(of: messages.count) { scrollToBottom() }
                        .onChange(of: isSending) { scrollToBottom() }
                    }
                    
                    TigerDivider()
                    
                    // Composer
                    composer
                        .padding(TigerSpacing.lg)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 600)
    }

    // MARK: - Chat Header
    
    private var chatHeader: some View {
        HStack(alignment: .center, spacing: TigerSpacing.lg) {
            VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                Text("Chat")
                    .font(TigerTypography.headline)
                    .foregroundColor(TigerPalette.textPrimary)
                
                Text("Talk to Tiger Mom about your day")
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: TigerSpacing.sm) {
                ConnectionBadge(status: connectionStatus)
                
                TigerSecondaryButton(title: "Refresh", icon: "arrow.clockwise") {
                    Task { await refreshAll() }
                }
                
                TigerSecondaryButton(title: "New Thread", icon: "plus") {
                    startFreshChat()
                }
            }
        }
    }

    // MARK: - Prompt Rail
    
    private var promptRail: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            Text("QUICK PROMPTS")
                .font(TigerTypography.overline)
                .tracking(1)
                .foregroundColor(TigerPalette.textMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TigerSpacing.sm) {
                    ForEach(suggestedPrompts, id: \.self) { prompt in
                        PromptPill(text: prompt) {
                            inputText = prompt
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: TigerSpacing.xl) {
            ZStack {
                Circle()
                    .fill(TigerPalette.gold.opacity(0.1))
                    .frame(width: 80, height: 80)

                TigerMark(size: 50, framed: false)
            }

            VStack(spacing: TigerSpacing.sm) {
                Text("Ask for the truth")
                    .font(TigerTypography.title)
                    .foregroundColor(TigerPalette.textPrimary)

                Text("Tiger Mom reads your activity history and responds with actual context, not generic advice.")
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: TigerSpacing.md) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Connecting to Tiger Mom...")
                .font(TigerTypography.bodySmall)
                .foregroundColor(TigerPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Composer
    
    private var composer: some View {
        HStack(alignment: .bottom, spacing: TigerSpacing.md) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .scrollContentBackground(.hidden)
                    .font(TigerTypography.body)
                    .foregroundColor(TigerPalette.textPrimary)
                    .frame(minHeight: 56, maxHeight: 100)
                    .padding(.horizontal, TigerSpacing.lg)
                    .padding(.vertical, TigerSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(TigerPalette.backgroundTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(TigerPalette.border, lineWidth: 1)
                            )
                    )

                if inputText.isEmpty {
                    Text("Ask Tiger Mom anything...")
                        .font(TigerTypography.body)
                        .foregroundColor(TigerPalette.textMuted)
                        .padding(.horizontal, TigerSpacing.xl)
                        .padding(.vertical, TigerSpacing.lg)
                        .allowsHitTesting(false)
                }
            }

            VStack(spacing: TigerSpacing.xs) {
                Button {
                    Task { await sendMessage() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(canSend ? TigerPalette.background : TigerPalette.textMuted)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(canSend ? TigerPalette.gold : TigerPalette.surfaceHover)
                        )
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
                .animation(.tigerQuick, value: canSend)

                Text("Cmd+Enter")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(TigerPalette.textMuted)
            }
        }
    }

    // MARK: - Context Rail
    
    private var contextRail: some View {
        VStack(spacing: TigerSpacing.lg) {
            // Today's stats
            TigerPanel(padding: TigerSpacing.lg, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: TigerSpacing.md) {
                    HStack {
                        Text("TODAY")
                            .font(TigerTypography.overline)
                            .tracking(1)
                            .foregroundColor(TigerPalette.textMuted)
                        
                        Spacer()
                        
                        Text("\(stats.focusScore)")
                            .font(TigerTypography.title)
                            .foregroundColor(TigerPalette.gold)
                    }

                    chatStatRow(label: "Deep work", value: stats.deepWorkMinutes.tigerDuration, tint: TigerPalette.jade)
                    chatStatRow(label: "Distraction", value: stats.distractionMinutes.tigerDuration, tint: TigerPalette.coral)
                    chatStatRow(label: "Shallow work", value: stats.shallowWorkMinutes.tigerDuration, tint: TigerPalette.gold)
                    chatStatRow(label: "Communication", value: stats.communicationMinutes.tigerDuration, tint: TigerPalette.mist)
                }
            }

            // Session info
            TigerPanel(padding: TigerSpacing.lg, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: TigerSpacing.md) {
                    Text("SESSION")
                        .font(TigerTypography.overline)
                        .tracking(1)
                        .foregroundColor(TigerPalette.textMuted)

                    sessionLine(label: "Tracking", value: appState.isTracking ? "Active" : "Paused")
                    sessionLine(label: "Idle", value: appState.isIdle ? "Yes" : "No")
                    sessionLine(label: "Captures", value: "\(appState.captureCountToday)")
                    sessionLine(
                        label: "Last capture",
                        value: appState.lastCaptureTime?.formatted(date: .omitted, time: .shortened) ?? "None"
                    )
                }
            }

            // Notes
            TigerPanel(padding: TigerSpacing.lg, cornerRadius: 14) {
                VStack(alignment: .leading, spacing: TigerSpacing.sm) {
                    Text("NOTES")
                        .font(TigerTypography.overline)
                        .tracking(1)
                        .foregroundColor(TigerPalette.textMuted)

                    Text(connectionStatus == .online
                         ? "Tiger Mom can read your tracked activity to respond with specifics."
                         : "Start the backend to restore history and live replies.")
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.textSecondary)
                        .lineSpacing(3)
                }
            }

            Spacer()
            
            // Last updated
            if let lastUpdatedAt {
                Text("Updated \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textMuted)
            }
        }
    }

    // MARK: - Helpers
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        let userMsg = ChatMessage(id: UUID().uuidString, content: text, isUser: true, timestamp: Date())
        withAnimation(.tigerSpring) {
            messages.append(userMsg)
        }
        inputText = ""
        isSending = true

        do {
            let response = try await APIClient.shared.chat(message: text)
            let reply = response["reply"] as? String ?? "..."
            withAnimation(.tigerSpring) {
                messages.append(ChatMessage(id: UUID().uuidString, content: reply, isUser: false, timestamp: Date()))
            }
            connectionStatus = .online
            lastUpdatedAt = Date()
            await loadStats()
        } catch {
            connectionStatus = .offline
            withAnimation(.tigerSpring) {
                messages.append(
                    ChatMessage(
                        id: UUID().uuidString,
                        content: "Tiger Mom is unavailable. Make sure the backend is running.",
                        isUser: false,
                        timestamp: Date()
                    )
                )
            }
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
        } catch {
            connectionStatus = .offline
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
        withAnimation(.tigerSpring) {
            messages = []
        }
        inputText = ""
    }

    private func scrollToBottom() {
        guard let proxy = scrollProxy else { return }
        let target = isSending ? "typing" : messages.last?.id
        if let target {
            withAnimation(.tigerSmooth) {
                proxy.scrollTo(target, anchor: .bottom)
            }
        }
    }

    private func chatStatRow(label: String, value: String, tint: Color) -> some View {
        HStack {
            HStack(spacing: TigerSpacing.sm) {
                Circle()
                    .fill(tint)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textSecondary)
            }

            Spacer()

            Text(value)
                .font(TigerTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(TigerPalette.textPrimary)
        }
    }

    private func sessionLine(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(TigerTypography.caption)
                .foregroundColor(TigerPalette.textSecondary)
            Spacer()
            Text(value)
                .font(TigerTypography.caption)
                .fontWeight(.semibold)
                .foregroundColor(TigerPalette.textPrimary)
        }
    }
}

// MARK: - Prompt Pill

struct PromptPill: View {
    let text: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(TigerTypography.caption)
                .foregroundColor(TigerPalette.textPrimary)
                .padding(.horizontal, TigerSpacing.md)
                .padding(.vertical, TigerSpacing.sm)
                .background(
                    Capsule(style: .continuous)
                        .fill(isHovered ? TigerPalette.surfaceHover : TigerPalette.backgroundTertiary)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(TigerPalette.border, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.tigerQuick, value: isHovered)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    
    @State private var showTimestamp = false

    var body: some View {
        HStack(alignment: .bottom, spacing: TigerSpacing.md) {
            if !message.isUser {
                TigerInlineGlyph(size: 28)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: TigerSpacing.xs) {
                Text(message.content)
                    .font(TigerTypography.body)
                    .foregroundColor(message.isUser ? TigerPalette.background : TigerPalette.textPrimary)
                    .lineSpacing(3)
                    .padding(.horizontal, TigerSpacing.lg)
                    .padding(.vertical, TigerSpacing.md)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(TigerPalette.gold)
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(TigerPalette.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                                    )
                            }
                        }
                    )

                // Show timestamp on hover
                if showTimestamp {
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(TigerPalette.textMuted)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: 480, alignment: message.isUser ? .trailing : .leading)
            .onHover { hovering in
                withAnimation(.tigerQuick) {
                    showTimestamp = hovering
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - Connection Badge

struct ConnectionBadge: View {
    let status: ChatConnectionStatus

    var body: some View {
        HStack(spacing: TigerSpacing.xs) {
            Image(systemName: status.symbol)
                .font(.system(size: 10, weight: .bold))
            Text(status.label)
                .font(TigerTypography.caption)
        }
        .foregroundColor(status.tint)
        .padding(.horizontal, TigerSpacing.sm + 2)
        .padding(.vertical, TigerSpacing.xs + 2)
        .background(
            Capsule(style: .continuous)
                .fill(status.tint.opacity(0.12))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(status.tint.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: TigerSpacing.md) {
            TigerInlineGlyph(size: 28)

            HStack(spacing: TigerSpacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(TigerPalette.textSecondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(phase == Double(index) ? 1.3 : 0.7)
                        .opacity(phase == Double(index) ? 1 : 0.4)
                }
            }
            .padding(.horizontal, TigerSpacing.lg)
            .padding(.vertical, TigerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TigerPalette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            while true {
                withAnimation(.easeInOut(duration: 0.4)) {
                    phase = (phase + 1).truncatingRemainder(dividingBy: 3)
                }
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }
}
