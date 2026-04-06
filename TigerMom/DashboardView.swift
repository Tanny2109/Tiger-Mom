import SwiftUI
import Charts

// MARK: - Data Models

struct DailyAnalytics {
    var focusScore: Int = 0
    var deepWorkMinutes: Int = 0
    var distractionMinutes: Int = 0
    var shallowWorkMinutes: Int = 0
    var categories: [CategoryData] = []
    var topDistractors: [String] = []
    var momGrade: String = ""
    var momCommentary: String = ""
    var hasReport: Bool = false
}

struct CategoryData: Identifiable {
    let id = UUID()
    let name: String
    let minutes: Int
    let type: ActivityType
}

struct TimelineBlock: Identifiable {
    let id = UUID()
    let startMinute: Int
    let endMinute: Int
    let type: ActivityType
}

struct WeeklyDay: Identifiable {
    let id = UUID()
    let label: String
    let focusHours: Double
    let distractionPercent: Double
}

enum ActivityType: String, CaseIterable {
    case deepWork = "Deep Work"
    case communication = "Communication"
    case shallowWork = "Shallow Work"
    case distraction = "Distraction"
    case breakTime = "Break"

    var color: Color {
        switch self {
        case .deepWork: return TigerPalette.jade
        case .communication: return TigerPalette.mist
        case .shallowWork: return TigerPalette.gold
        case .distraction: return TigerPalette.coral
        case .breakTime: return TigerPalette.textMuted
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Bindable var appState: AppState
    let screenCapture: ScreenCapture

    @State private var daily = DailyAnalytics()
    @State private var timeline: [TimelineBlock] = []
    @State private var weekly: [WeeklyDay] = []
    @State private var isLoading = true
    @State private var focusRingProgress: Double = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: TigerSpacing.xl) {
                // Header Section
                headerSection
                
                // Permission Banner (if needed)
                if !appState.hasScreenRecordingPermission {
                    PermissionBanner {
                        screenCapture.requestPermission()
                    }
                }
                
                // Metrics Row
                metricsRow
                
                // Main Content: Timeline + Breakdown
                HStack(alignment: .top, spacing: TigerSpacing.lg) {
                    timelineSection
                    breakdownSection
                }
                
                // Secondary Content: Report + Trends
                HStack(alignment: .top, spacing: TigerSpacing.lg) {
                    reportCard
                    weeklyTrends
                }
            }
            .padding(TigerSpacing.xxl)
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: TigerSpacing.xxl) {
            // Left: Greeting and Status
            VStack(alignment: .leading, spacing: TigerSpacing.lg) {
                VStack(alignment: .leading, spacing: TigerSpacing.sm) {
                    Text(greeting)
                        .font(TigerTypography.displayMedium)
                        .foregroundColor(TigerPalette.textPrimary)
                    
                    Text("\(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))")
                        .font(TigerTypography.body)
                        .foregroundColor(TigerPalette.textSecondary)
                }
                
                HStack(spacing: TigerSpacing.sm) {
                    TigerCapsuleBadge(
                        title: appState.isTracking ? "Live" : "Paused",
                        symbol: appState.isTracking ? "waveform.path.ecg" : "pause.fill",
                        tint: appState.isTracking ? TigerPalette.jade : TigerPalette.textMuted
                    )
                    
                    TigerCapsuleBadge(
                        title: appState.isIdle ? "Idle" : "Active",
                        symbol: appState.isIdle ? "moon.zzz.fill" : "cursorarrow.motionlines",
                        tint: appState.isIdle ? TigerPalette.amber : TigerPalette.mist
                    )
                }
                
                HStack(spacing: TigerSpacing.sm) {
                    TigerSecondaryButton(
                        title: appState.isTracking ? "Pause" : "Start",
                        icon: appState.isTracking ? "pause.fill" : "play.fill"
                    ) {
                        withAnimation(.tigerSpring) {
                            appState.isTracking.toggle()
                            if appState.isTracking {
                                screenCapture.start(appState: appState)
                            } else {
                                screenCapture.stop()
                            }
                        } label: {
                            Label(appState.isTracking ? "Pause Tracking" : "Start Tracking",
                                  systemImage: appState.isTracking ? "pause.fill" : "record.circle.fill")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                    }
                    
                    TigerSecondaryButton(title: "Refresh", icon: "arrow.clockwise") {
                        Task { await loadData() }
                    }
                }
            }
            
            Spacer()
            
            // Right: Focus Score Orb (smaller)
            scoreOrb
        }
        .padding(TigerSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TigerPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(TigerPalette.border, lineWidth: 1)
                )
        )
    }

    // MARK: - Score Orb (Smaller)
    
    private var scoreOrb: some View {
        ZStack {
            // Subtle glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            TigerPalette.gold.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Track
            Circle()
                .stroke(TigerPalette.border, lineWidth: 12)
                .frame(width: 130, height: 130)

            // Progress ring
            Circle()
                .trim(from: 0, to: focusRingProgress)
                .stroke(
                    LinearGradient(
                        colors: [TigerPalette.mist, TigerPalette.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 130, height: 130)

            // Score display
            VStack(spacing: TigerSpacing.xs) {
                Text("\(daily.focusScore)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text("Focus")
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
        .frame(width: 160, height: 160)
    }

    // MARK: - Metrics Row
    
    private var metricsRow: some View {
        HStack(spacing: TigerSpacing.lg) {
            TigerMetricTile(
                label: "Deep Work",
                value: daily.deepWorkMinutes.tigerClock,
                symbol: "bolt.fill",
                tint: TigerPalette.jade
            )
            TigerMetricTile(
                label: "Distraction",
                value: daily.distractionMinutes.tigerClock,
                symbol: "flame.fill",
                tint: TigerPalette.coral
            )
            TigerMetricTile(
                label: "Shallow Work",
                value: daily.shallowWorkMinutes.tigerClock,
                symbol: "tray.full.fill",
                tint: TigerPalette.gold
            )
            TigerMetricTile(
                label: "Communication",
                value: (daily.categories.first { $0.type == .communication }?.minutes ?? 0).tigerClock,
                symbol: "bubble.left.and.bubble.right.fill",
                tint: TigerPalette.mist
            )
        }
    }

    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        TigerPanel(padding: TigerSpacing.xl, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: TigerSpacing.lg) {
                VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                    Text("DAY TIMELINE")
                        .font(TigerTypography.overline)
                        .tracking(1.2)
                        .foregroundColor(TigerPalette.textMuted)
                    
                    Text("Today's rhythm")
                        .font(TigerTypography.title)
                        .foregroundColor(TigerPalette.textPrimary)
                }

                if timeline.isEmpty && !isLoading {
                    emptyState(message: "Tracking will paint today's rhythm once screenshots begin.")
                } else {
                    TimelineBar(blocks: timeline)
                        .frame(height: 64)

                    HStack {
                        Text("Start")
                        Spacer()
                        Text("Midday")
                        Spacer()
                        Text("Now")
                    }
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Breakdown Section
    
    private var breakdownSection: some View {
        TigerPanel(padding: TigerSpacing.xl, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: TigerSpacing.lg) {
                VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                    Text("BREAKDOWN")
                        .font(TigerTypography.overline)
                        .tracking(1.2)
                        .foregroundColor(TigerPalette.textMuted)
                    
                    Text("Attention split")
                        .font(TigerTypography.title)
                        .foregroundColor(TigerPalette.textPrimary)
                }

                if daily.categories.isEmpty && !isLoading {
                    emptyState(message: "No captured activity yet.")
                } else {
                    HStack(spacing: TigerSpacing.xl) {
                        Chart(daily.categories) { cat in
                            SectorMark(
                                angle: .value("Minutes", cat.minutes),
                                innerRadius: .ratio(0.65),
                                angularInset: 2
                            )
                            .foregroundStyle(cat.type.color)
                            .cornerRadius(6)
                        }
                        .frame(width: 140, height: 140)

                        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
                            ForEach(daily.categories) { cat in
                                HStack(spacing: TigerSpacing.sm) {
                                    Circle()
                                        .fill(cat.type.color)
                                        .frame(width: 8, height: 8)

                                    Text(cat.name)
                                        .font(TigerTypography.bodySmall)
                                        .foregroundColor(TigerPalette.textPrimary)

                                    Spacer()

                                    Text(cat.minutes.tigerDuration)
                                        .font(TigerTypography.caption)
                                        .foregroundColor(TigerPalette.textMuted)
                                }
                            }

                            if !daily.topDistractors.isEmpty {
                                TigerDivider()
                                    .padding(.vertical, TigerSpacing.xs)

                                Text("TOP DISTRACTORS")
                                    .font(TigerTypography.overline)
                                    .tracking(1)
                                    .foregroundColor(TigerPalette.textMuted)

                                Text(daily.topDistractors.joined(separator: " / "))
                                    .font(TigerTypography.bodySmall)
                                    .foregroundColor(TigerPalette.textSecondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 380)
    }

    // MARK: - Report Card
    
    private var reportCard: some View {
        TigerPanel(padding: TigerSpacing.xl, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: TigerSpacing.lg) {
                VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                    Text("REPORT CARD")
                        .font(TigerTypography.overline)
                        .tracking(1.2)
                        .foregroundColor(TigerPalette.textMuted)
                    
                    Text("Mom's verdict")
                        .font(TigerTypography.title)
                        .foregroundColor(TigerPalette.textPrimary)
                }

                if daily.hasReport {
                    HStack(alignment: .top, spacing: TigerSpacing.lg) {
                        Text(daily.momGrade)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(gradeColor(daily.momGrade))
                            .frame(width: 70)

                        Text(daily.momCommentary)
                            .font(TigerTypography.body)
                            .foregroundColor(TigerPalette.textPrimary)
                            .lineSpacing(4)
                    }
                } else {
                    emptyState(message: "Report appears after 6 PM with enough data.")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weekly Trends
    
    private var weeklyTrends: some View {
        TigerPanel(padding: TigerSpacing.xl, cornerRadius: 16) {
            VStack(alignment: .leading, spacing: TigerSpacing.lg) {
                VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                    Text("TRENDS")
                        .font(TigerTypography.overline)
                        .tracking(1.2)
                        .foregroundColor(TigerPalette.textMuted)
                    
                    Text("Weekly momentum")
                        .font(TigerTypography.title)
                        .foregroundColor(TigerPalette.textPrimary)
                }

                if weekly.isEmpty && !isLoading {
                    emptyState(message: "A week of tracked behavior will surface trends here.")
                } else {
                    Chart {
                        ForEach(weekly) { day in
                            BarMark(
                                x: .value("Day", day.label),
                                y: .value("Focus Hours", day.focusHours)
                            )
                            .foregroundStyle(TigerPalette.gold.gradient)
                            .cornerRadius(4)

                            LineMark(
                                x: .value("Day", day.label),
                                y: .value("Distraction", day.distractionPercent / 10)
                            )
                            .foregroundStyle(TigerPalette.coral)
                            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                            .symbol(.circle)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(TigerPalette.border)
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))h")
                                        .font(TigerTypography.caption)
                                        .foregroundColor(TigerPalette.textMuted)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisValueLabel()
                                .font(TigerTypography.caption)
                                .foregroundStyle(TigerPalette.textMuted)
                        }
                    }
                    .frame(height: 200)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 380)
    }

    // MARK: - Helpers
    
    private func emptyState(message: String) -> some View {
        VStack(alignment: .leading, spacing: TigerSpacing.sm) {
            TigerInlineGlyph(size: 24)
            Text(message)
                .font(TigerTypography.bodySmall)
                .foregroundColor(TigerPalette.textSecondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<23: return "Good evening"
        default: return "Still awake"
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade.prefix(1) {
        case "A": return TigerPalette.jade
        case "B": return TigerPalette.gold
        case "C": return Color.yellow
        default: return TigerPalette.coral
        }
    }

    private func loadData() async {
        isLoading = true
        focusRingProgress = 0

        async let dailyReq = APIClient.shared.analyticsDaily()
        async let weeklyReq = APIClient.shared.analyticsWeekly()
        async let timelineReq = APIClient.shared.analyticsTimeline()

        if let d = try? await dailyReq {
            daily.focusScore = d["focus_score"] as? Int ?? 0
            daily.deepWorkMinutes = d["deep_work_minutes"] as? Int ?? 0
            daily.distractionMinutes = d["distraction_minutes"] as? Int ?? 0
            daily.shallowWorkMinutes = d["shallow_work_minutes"] as? Int ?? 0

            if let cats = d["categories"] as? [[String: Any]] {
                daily.categories = cats.compactMap { cat in
                    guard let name = cat["name"] as? String,
                          let mins = cat["minutes"] as? Int,
                          let typeStr = cat["type"] as? String else { return nil }
                    let type = ActivityType(rawValue: typeStr) ?? .shallowWork
                    return CategoryData(name: name, minutes: mins, type: type)
                }
            }

            daily.topDistractors = d["top_distractors"] as? [String] ?? []

            if let report = d["mom_report"] as? [String: Any] {
                daily.momGrade = report["grade"] as? String ?? ""
                daily.momCommentary = report["commentary"] as? String ?? ""
                daily.hasReport = true
            } else {
                daily.momGrade = ""
                daily.momCommentary = ""
                daily.hasReport = false
            }

            appState.focusScore = daily.focusScore
        }

        if let w = try? await weeklyReq,
           let days = w["days"] as? [[String: Any]] {
            weekly = days.compactMap { day in
                guard let label = day["label"] as? String,
                      let hours = day["focus_hours"] as? Double,
                      let distPct = day["distraction_percent"] as? Double else { return nil }
                return WeeklyDay(label: label, focusHours: hours, distractionPercent: distPct)
            }
        }

        if let t = try? await timelineReq,
           let blocks = t["blocks"] as? [[String: Any]] {
            timeline = blocks.compactMap { block in
                guard let start = block["start_minute"] as? Int,
                      let end = block["end_minute"] as? Int,
                      let typeStr = block["type"] as? String else { return nil }
                let type = ActivityType(rawValue: typeStr) ?? .breakTime
                return TimelineBlock(startMinute: start, endMinute: end, type: type)
            }
        }

        isLoading = false

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            focusRingProgress = Double(daily.focusScore) / 100.0
        }
    }
}

// MARK: - Timeline Bar

struct TimelineBar: View {
    let blocks: [TimelineBlock]

    var body: some View {
        GeometryReader { geo in
            let totalMinutes = max(totalSpan, 1)

            HStack(spacing: 2) {
                ForEach(blocks) { block in
                    let fraction = CGFloat(block.endMinute - block.startMinute) / CGFloat(totalMinutes)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(block.type.color)
                        .frame(width: max((fraction * geo.size.width) - 2, 6))
                }
            }
            .padding(TigerSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TigerPalette.backgroundTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(TigerPalette.border, lineWidth: 1)
                    )
            )
        }
    }

    private var totalSpan: Int {
        guard let first = blocks.first, let last = blocks.last else { return 1 }
        return max(last.endMinute - first.startMinute, 1)
    }
}

// MARK: - Permission Banner

struct PermissionBanner: View {
    let onGrantAccess: () -> Void

    var body: some View {
        HStack(spacing: TigerSpacing.lg) {
            ZStack {
                Circle()
                    .fill(TigerPalette.gold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(TigerPalette.gold)
            }

            VStack(alignment: .leading, spacing: TigerSpacing.xs) {
                Text("Screen Recording Permission Required")
                    .font(TigerTypography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(TigerPalette.textPrimary)
                Text("Tiger Mom needs screen access to track your activity.")
                    .font(TigerTypography.caption)
                    .foregroundColor(TigerPalette.textSecondary)
            }

            Spacer()

            TigerPrimaryButton(title: "Grant Access") {
                onGrantAccess()
            }
        }
        .padding(TigerSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TigerPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(TigerPalette.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
