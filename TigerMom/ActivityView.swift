import SwiftUI

struct ActivityEntry: Identifiable {
    let id: String
    let timestamp: Date
    let appName: String
    let windowTitle: String
    let category: ActivityType
    let subcategory: String
    let detail: String
    let confidence: Double
    let classificationReason: String
}

struct ActivityView: View {
    @State private var activities: [ActivityEntry] = []
    @State private var selectedFilter: ActivityType?
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var expandedId: String?

    private let pageSize = 50

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                header
                filterBar
                activityStage
            }
            .padding(24)
        }
        .task {
            await loadInitial()
        }
    }

    private var header: some View {
        TigerPanel(padding: 24, cornerRadius: 28, emphasis: 1.08) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    TigerSectionHeader(
                        eyebrow: "Forensics",
                        title: "Activity Log",
                        detail: "A scrollable record of what the sidecar thinks you were doing."
                    )

                    HStack(spacing: 10) {
                        TigerCapsuleBadge(title: "\(filteredActivities.count) visible", symbol: "line.3.horizontal.decrease.circle.fill", tint: TigerPalette.mist)
                        TigerCapsuleBadge(title: "\(activities.count) loaded", symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90", tint: TigerPalette.gold)
                    }
                }

                Spacer()

                Text(searchText.isEmpty ? "Readable, not raw." : "Filtering for “\(searchText)”")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
    }

    private var filterBar: some View {
        TigerPanel(padding: 20, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(label: "All", color: TigerPalette.mist, isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }

                        ForEach(ActivityType.allCases, id: \.rawValue) { type in
                            FilterPill(label: type.rawValue, color: type.color, isSelected: selectedFilter == type) {
                                selectedFilter = type
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(TigerPalette.textMuted)

                    TextField("Search apps, titles, details, and context…", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TigerPalette.textPrimary)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(TigerPalette.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .tigerInsetField()
            }
        }
    }

    private var activityStage: some View {
        TigerPanel(padding: 0, cornerRadius: 30, emphasis: 1.02) {
            if activities.isEmpty && !isLoading {
                emptyState
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredActivities) { entry in
                        ActivityRow(
                            entry: entry,
                            isExpanded: expandedId == entry.id,
                            onTap: {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    expandedId = expandedId == entry.id ? nil : entry.id
                                }
                            }
                        )
                    }

                    if hasMore && !isLoading {
                        ProgressView()
                            .padding(.vertical, 18)
                            .onAppear {
                                Task { await loadMore() }
                            }
                    }
                }
                .padding(18)
            }
        }
    }

    private var filteredActivities: [ActivityEntry] {
        activities.filter { entry in
            let matchesCategory = selectedFilter == nil || entry.category == selectedFilter
            let matchesSearch = searchText.isEmpty
                || entry.appName.localizedCaseInsensitiveContains(searchText)
                || entry.windowTitle.localizedCaseInsensitiveContains(searchText)
                || entry.detail.localizedCaseInsensitiveContains(searchText)
                || entry.classificationReason.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 80)

            ZStack {
                Circle()
                    .fill(TigerPalette.amber.opacity(0.1))
                    .frame(width: 92, height: 92)
                TigerMark(size: 58, framed: false)
            }

            Text("The log is waiting.")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(TigerPalette.textPrimary)

            Text("Activities will appear here once tracking starts and the sidecar begins classifying screenshots.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(TigerPalette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .lineSpacing(3)

            Spacer(minLength: 80)
        }
        .frame(maxWidth: .infinity, minHeight: 520)
        .padding(24)
    }

    private func loadInitial() async {
        currentPage = 1
        hasMore = true
        activities = []
        await loadMore()
    }

    private func loadMore() async {
        guard !isLoading, hasMore else { return }
        isLoading = true

        do {
            let response = try await APIClient.shared.getActivities(page: currentPage, limit: pageSize, category: selectedFilter?.rawValue)

            guard let items = response["activities"] as? [[String: Any]] else {
                hasMore = false
                isLoading = false
                return
            }

            let newEntries = items.compactMap(parseActivity)
            activities.append(contentsOf: newEntries)
            hasMore = newEntries.count >= pageSize
            currentPage += 1
        } catch {
            hasMore = false
        }

        isLoading = false
    }

    private func parseActivity(_ dict: [String: Any]) -> ActivityEntry? {
        guard let id = dict["id"] as? String,
              let appName = dict["app_name"] as? String else { return nil }

        let timestamp = (dict["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let type = ActivityType(rawValue: dict["category"] as? String ?? "Break") ?? .breakTime

        return ActivityEntry(
            id: id,
            timestamp: timestamp,
            appName: appName,
            windowTitle: dict["window_title"] as? String ?? "",
            category: type,
            subcategory: dict["subcategory"] as? String ?? "",
            detail: dict["detail"] as? String ?? "",
            confidence: dict["confidence"] as? Double ?? 0,
            classificationReason: dict["classification_reason"] as? String ?? ""
        )
    }
}

struct FilterPill: View {
    let label: String
    var color: Color = TigerPalette.gold
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? color : TigerPalette.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? color.opacity(0.14) : Color.white.opacity(0.04))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(isSelected ? color.opacity(0.18) : Color.white.opacity(0.04), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct ActivityRow: View {
    let entry: ActivityEntry
    let isExpanded: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(entry.category.color.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Image(systemName: iconForApp(entry.appName))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(entry.category.color)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(entry.appName)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(TigerPalette.textPrimary)

                            if !entry.windowTitle.isEmpty {
                                Text(entry.windowTitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(TigerPalette.textSecondary)
                                    .lineLimit(1)
                            }
                        }

                        if !entry.detail.isEmpty {
                            Text(entry.detail)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(TigerPalette.textSecondary)
                                .lineLimit(isExpanded ? nil : 1)
                        }
                    }

                    Spacer()

                    Text(entry.category.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(entry.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(entry.category.color.opacity(0.12))
                        )

                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(TigerPalette.textMuted)
                        .frame(width: 72, alignment: .trailing)
                }

                if isExpanded {
                    expandedDetails
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.05) : Color.white.opacity(0.035))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(isExpanded ? 0.08 : 0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            TigerDivider()
                .padding(.top, 14)
                .padding(.bottom, 2)

            if !entry.detail.isEmpty {
                detailBlock(title: "Detail", value: entry.detail)
            }

            if !entry.classificationReason.isEmpty {
                detailBlock(title: "Classification reason", value: entry.classificationReason)
            }

            HStack(spacing: 16) {
                if !entry.subcategory.isEmpty {
                    Label(entry.subcategory, systemImage: "tag.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(TigerPalette.textSecondary)
                }

                Label("\(Int(entry.confidence * 100))% confidence", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(TigerPalette.textSecondary)
            }
            .padding(.top, 2)
        }
    }

    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(TigerPalette.textMuted)

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(TigerPalette.textSecondary)
                .lineSpacing(4)
        }
    }

    private func iconForApp(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("safari") || lower.contains("chrome") || lower.contains("firefox") || lower.contains("arc") {
            return "globe"
        } else if lower.contains("slack") || lower.contains("discord") || lower.contains("teams") || lower.contains("messages") {
            return "bubble.left.and.bubble.right"
        } else if lower.contains("mail") || lower.contains("outlook") {
            return "envelope"
        } else if lower.contains("xcode") || lower.contains("code") || lower.contains("terminal") || lower.contains("iterm") {
            return "chevron.left.forwardslash.chevron.right"
        } else if lower.contains("figma") || lower.contains("sketch") {
            return "paintbrush"
        } else if lower.contains("notion") || lower.contains("notes") || lower.contains("docs") {
            return "doc.text"
        } else if lower.contains("spotify") || lower.contains("music") {
            return "music.note"
        } else if lower.contains("finder") {
            return "folder"
        } else if lower.contains("twitter") || lower.contains("reddit") || lower.contains("youtube") || lower.contains("instagram") || lower.contains("tiktok") {
            return "exclamationmark.triangle"
        }
        return "app"
    }
}
