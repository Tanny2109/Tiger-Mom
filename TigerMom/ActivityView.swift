import SwiftUI

// MARK: - Activity Models

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
    @State private var selectedFilter: ActivityType? = nil
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var expandedId: String? = nil

    private let pageSize = 50

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Activity")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(filteredActivities.count) entries")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)

            // Filter bar
            filterBar
                .padding(.horizontal, 28)
                .padding(.bottom, 12)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Activity list
            if activities.isEmpty && !isLoading {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredActivities) { entry in
                            ActivityRow(
                                entry: entry,
                                isExpanded: expandedId == entry.id,
                                onTap: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        expandedId = expandedId == entry.id ? nil : entry.id
                                    }
                                }
                            )
                        }

                        if hasMore && !isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .onAppear {
                                    Task { await loadMore() }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(hex: 0x07070A))
        .task {
            await loadInitial()
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 10) {
            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterPill(label: "All", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }
                    ForEach(ActivityType.allCases, id: \.rawValue) { type in
                        FilterPill(label: type.rawValue, color: type.color, isSelected: selectedFilter == type) {
                            selectedFilter = type
                        }
                    }
                }
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
                TextField("Search apps, titles, details...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
        }
    }

    // MARK: - Filtered

    private var filteredActivities: [ActivityEntry] {
        activities.filter { entry in
            let matchesCategory = selectedFilter == nil || entry.category == selectedFilter
            let matchesSearch = searchText.isEmpty ||
                entry.appName.localizedCaseInsensitiveContains(searchText) ||
                entry.windowTitle.localizedCaseInsensitiveContains(searchText) ||
                entry.detail.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "eye.fill")
                .font(.system(size: 36))
                .foregroundColor(Color(hex: 0xF59E0B).opacity(0.2))
            Text("Tiger Mom is watching...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            Text("Activities will appear here once tracking starts.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.2))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            var path = "/activities?page=\(currentPage)&limit=\(pageSize)"
            if let filter = selectedFilter {
                path += "&category=\(filter.rawValue)"
            }
            let response = try await APIClient.shared.getActivities(page: currentPage, limit: pageSize, category: selectedFilter?.rawValue)

            guard let items = response["activities"] as? [[String: Any]] else {
                hasMore = false
                isLoading = false
                return
            }

            let newEntries = items.compactMap { parseActivity($0) }
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

        let ts = (dict["timestamp"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
        let typeStr = dict["category"] as? String ?? "Break"
        let type = ActivityType(rawValue: typeStr) ?? .breakTime

        return ActivityEntry(
            id: id,
            timestamp: ts,
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
    var color: Color = Color(hex: 0xF59E0B)
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.45))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.25) : Color.white.opacity(0.04))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
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
            VStack(alignment: .leading, spacing: 0) {
                // Main row
                HStack(spacing: 12) {
                    // App icon
                    Image(systemName: iconForApp(entry.appName))
                        .font(.system(size: 14))
                        .foregroundColor(entry.category.color.opacity(0.7))
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(entry.category.color.opacity(0.1))
                        )

                    // App + title
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(entry.appName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                            if !entry.windowTitle.isEmpty {
                                Text("— \(entry.windowTitle)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.35))
                                    .lineLimit(1)
                            }
                        }

                        if !entry.detail.isEmpty {
                            Text(entry.detail)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.3))
                                .lineLimit(isExpanded ? nil : 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Category badge
                    Text(entry.category.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(entry.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(entry.category.color.opacity(0.12))
                        )

                    // Timestamp
                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.25))
                        .frame(width: 60, alignment: .trailing)
                }

                // Expanded details
                if isExpanded {
                    expandedDetails
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? Color.white.opacity(0.04) : Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(isExpanded ? 0.06 : 0.03), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.04))
                .frame(height: 1)
                .padding(.top, 8)

            if !entry.detail.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detail")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                    Text(entry.detail)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineSpacing(3)
                }
            }

            if !entry.classificationReason.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Classification Reason")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                    Text(entry.classificationReason)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                        .lineSpacing(3)
                }
            }

            HStack(spacing: 16) {
                if !entry.subcategory.isEmpty {
                    Label(entry.subcategory, systemImage: "tag")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                Label("\(Int(entry.confidence * 100))% confidence", systemImage: "checkmark.seal")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.top, 2)
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
