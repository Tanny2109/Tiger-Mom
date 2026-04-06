import SwiftUI

// MARK: - Data Model

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

// MARK: - Activity View

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
        VStack(spacing: 0) {
            // Header
            activityHeader
                .padding(.horizontal, TigerSpacing.xxl)
                .padding(.top, TigerSpacing.xxl)
                .padding(.bottom, TigerSpacing.lg)
            
            // Filter bar (sticky)
            filterBar
                .padding(.horizontal, TigerSpacing.xxl)
                .padding(.bottom, TigerSpacing.lg)
                .background(TigerPalette.background.opacity(0.8))
            
            // Activity list
            ScrollView(.vertical, showsIndicators: false) {
                activityList
                    .padding(.horizontal, TigerSpacing.xxl)
                    .padding(.bottom, TigerSpacing.xxl)
            }
        }
        .task {
            await loadInitial()
        }
    }

    // MARK: - Header
    
    private var activityHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                Text("Activity")
                    .font(TigerTypography.headline)
                    .foregroundColor(TigerPalette.textPrimary)
                
                Text("A scrollable record of your behavior")
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: TigerSpacing.sm) {
                TigerCapsuleBadge(
                    title: "\(filteredActivities.count) visible",
                    symbol: "line.3.horizontal.decrease.circle.fill",
                    tint: TigerPalette.mist
                )
                
                TigerCapsuleBadge(
                    title: "\(activities.count) loaded",
                    symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    tint: TigerPalette.gold
                )
            }
        }
    }

    // MARK: - Filter Bar
    
    private var filterBar: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.md) {
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TigerSpacing.sm) {
                    FilterPill(label: "All", color: TigerPalette.mist, isSelected: selectedFilter == nil) {
                        withAnimation(.tigerSpring) {
                            selectedFilter = nil
                        }
                    }

                    ForEach(ActivityType.allCases, id: \.rawValue) { type in
                        FilterPill(label: type.rawValue, color: type.color, isSelected: selectedFilter == type) {
                            withAnimation(.tigerSpring) {
                                selectedFilter = type
                            }
                        }
                    }
                }
            }

            // Search field
            HStack(spacing: TigerSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(TigerPalette.textMuted)

                TextField("Search apps, titles, details...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textPrimary)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(TigerPalette.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, TigerSpacing.lg)
            .padding(.vertical, TigerSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(TigerPalette.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                    )
            )
        }
        .padding(TigerSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TigerPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(TigerPalette.border, lineWidth: 1)
                )
        )
    }

    // MARK: - Activity List
    
    private var activityList: some View {
        Group {
            if activities.isEmpty && !isLoading {
                emptyState
            } else {
                LazyVStack(spacing: TigerSpacing.sm) {
                    ForEach(filteredActivities) { entry in
                        ActivityRow(
                            entry: entry,
                            isExpanded: expandedId == entry.id,
                            onTap: {
                                withAnimation(.tigerSpring) {
                                    expandedId = expandedId == entry.id ? nil : entry.id
                                }
                            }
                        )
                    }

                    if hasMore && !isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.vertical, TigerSpacing.lg)
                            .onAppear {
                                Task { await loadMore() }
                            }
                    }
                }
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

    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: TigerSpacing.xl) {
            Spacer(minLength: 60)

            ZStack {
                Circle()
                    .fill(TigerPalette.gold.opacity(0.1))
                    .frame(width: 80, height: 80)
                TigerMark(size: 50, framed: false)
            }

            VStack(spacing: TigerSpacing.sm) {
                Text("The log is waiting")
                    .font(TigerTypography.title)
                    .foregroundColor(TigerPalette.textPrimary)

                Text("Activities will appear here once tracking starts and screenshots are classified.")
                    .font(TigerTypography.bodySmall)
                    .foregroundColor(TigerPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
                    .lineSpacing(3)
            }

            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    // MARK: - Data Loading
    
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

// MARK: - Filter Pill

struct FilterPill: View {
    let label: String
    var color: Color = TigerPalette.gold
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(TigerTypography.caption)
                .foregroundColor(isSelected ? color : TigerPalette.textSecondary)
                .padding(.horizontal, TigerSpacing.md)
                .padding(.vertical, TigerSpacing.sm)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? color.opacity(0.12) : (isHovered ? TigerPalette.surfaceHover : .clear))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(isSelected ? color.opacity(0.15) : TigerPalette.border, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.tigerQuick, value: isHovered)
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let entry: ActivityEntry
    let isExpanded: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left accent border
                Rectangle()
                    .fill(entry.category.color)
                    .frame(width: 3)
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: TigerSpacing.md) {
                        // App icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(entry.category.color.opacity(0.1))
                                .frame(width: 36, height: 36)

                            Image(systemName: iconForApp(entry.appName))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(entry.category.color)
                        }

                        // Details
                        VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                            HStack(spacing: TigerSpacing.sm) {
                                Text(entry.appName)
                                    .font(TigerTypography.bodySmall)
                                    .fontWeight(.semibold)
                                    .foregroundColor(TigerPalette.textPrimary)

                                if !entry.windowTitle.isEmpty {
                                    Text(entry.windowTitle)
                                        .font(TigerTypography.caption)
                                        .foregroundColor(TigerPalette.textSecondary)
                                        .lineLimit(1)
                                }
                            }

                            if !entry.detail.isEmpty {
                                Text(entry.detail)
                                    .font(TigerTypography.caption)
                                    .foregroundColor(TigerPalette.textMuted)
                                    .lineLimit(isExpanded ? nil : 1)
                            }
                        }

                        Spacer()

                        // Category badge
                        Text(entry.category.rawValue)
                            .font(TigerTypography.overline)
                            .foregroundColor(entry.category.color)
                            .padding(.horizontal, TigerSpacing.sm)
                            .padding(.vertical, TigerSpacing.xs)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(entry.category.color.opacity(0.1))
                            )

                        // Timestamp
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(TigerTypography.caption)
                            .foregroundColor(TigerPalette.textMuted)
                            .frame(width: 60, alignment: .trailing)
                    }

                    // Expanded details
                    if isExpanded {
                        expandedDetails
                    }
                }
                .padding(.horizontal, TigerSpacing.lg)
                .padding(.vertical, TigerSpacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? TigerPalette.surfaceElevated : TigerPalette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isExpanded ? TigerPalette.borderStrong : TigerPalette.border, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.tigerQuick, value: isHovered)
    }

    // MARK: - Expanded Details
    
    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: TigerSpacing.md) {
            TigerDivider()
                .padding(.top, TigerSpacing.md)

            if !entry.detail.isEmpty {
                detailBlock(title: "Detail", value: entry.detail)
            }

            if !entry.classificationReason.isEmpty {
                detailBlock(title: "Classification reason", value: entry.classificationReason)
            }

            HStack(spacing: TigerSpacing.lg) {
                if !entry.subcategory.isEmpty {
                    Label(entry.subcategory, systemImage: "tag.fill")
                        .font(TigerTypography.caption)
                        .foregroundColor(TigerPalette.textSecondary)
                }

                Label("\(Int(entry.confidence * 100))% confidence", systemImage: "checkmark.seal.fill")
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
    }

    private func detailBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: TigerSpacing.xs) {
            Text(title.uppercased())
                .font(TigerTypography.overline)
                .tracking(1)
                .foregroundColor(TigerPalette.textMuted)

            Text(value)
                .font(TigerTypography.caption)
                .foregroundColor(TigerPalette.textSecondary)
                .lineSpacing(3)
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
