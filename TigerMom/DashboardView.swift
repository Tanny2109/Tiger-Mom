import SwiftUI
import Charts

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
        case .breakTime: return Color.white.opacity(0.35)
        }
    }
}

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
            VStack(spacing: 18) {
                heroSection
                if !appState.hasScreenRecordingPermission {
                    PermissionBanner {
                        screenCapture.requestPermission()
                    }
                }
                metricsRow
                HStack(alignment: .top, spacing: 20) {
                    timelineSection
                    breakdownSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 20) {
                    reportCard
                    weeklyTrends
                }
            }
            .padding(22)
        }
        .task {
            await loadData()
        }
    }

    private var heroSection: some View {
        TigerPanel(padding: 24, cornerRadius: 26, emphasis: 1.05) {
            HStack(alignment: .center, spacing: 22) {
                VStack(alignment: .leading, spacing: 14) {
                    TigerSectionHeader(
                        eyebrow: "Today",
                        title: greeting,
                        detail: "\(Date().formatted(.dateTime.weekday(.wide).month(.wide).day())) • \(dashboardSummary)"
                    )

                    HStack(spacing: 10) {
                        TigerCapsuleBadge(
                            title: appState.isTracking ? "Live Capture" : "Paused",
                            symbol: appState.isTracking ? "waveform.path.ecg.rectangle.fill" : "pause.fill",
                            tint: appState.isTracking ? TigerPalette.jade : TigerPalette.textSecondary
                        )

                        TigerCapsuleBadge(
                            title: appState.isIdle ? "Idle detected" : "Present",
                            symbol: appState.isIdle ? "moon.zzz.fill" : "cursorarrow.motionlines",
                            tint: appState.isIdle ? TigerPalette.gold : TigerPalette.mist
                        )
                    }

                    HStack(spacing: 12) {
                        Button {
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
                        .buttonStyle(
                            TigerButtonStyle(
                                tint: appState.isTracking ? TigerPalette.coral : TigerPalette.jade,
                                prominence: .secondary
                            )
                        )

                        Button {
                            Task { await loadData() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(TigerButtonStyle(tint: TigerPalette.gold, prominence: .quiet))
                    }
                }

                Spacer(minLength: 8)

                scoreOrb
            }
        }
    }

    private var scoreOrb: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            TigerPalette.amber.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 92
                    )
                )
                .frame(width: 188, height: 188)

            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 12)
                .frame(width: 164, height: 164)

            Circle()
                .trim(from: 0, to: focusRingProgress)
                .stroke(
                    AngularGradient(
                        colors: [TigerPalette.jade, TigerPalette.gold, TigerPalette.coral],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 164, height: 164)
                .shadow(color: TigerPalette.gold.opacity(0.16), radius: 10, x: 0, y: 6)

            VStack(spacing: 6) {
                Text("\(daily.focusScore)")
                    .font(.system(size: 50, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textPrimary)

                Text("Focus score")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(TigerPalette.textSecondary)
            }
        }
        .frame(width: 198, height: 198)
    }

    private var metricsRow: some View {
        HStack(spacing: 14) {
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

    private var timelineSection: some View {
        TigerPanel(padding: 20, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 18) {
                TigerSectionHeader(
                    eyebrow: "Rhythm",
                    title: "Day Timeline",
                    detail: "A clean read on how the day has been segmented."
                )

                if timeline.isEmpty && !isLoading {
                    emptyState(message: "Tracking will paint today’s rhythm once screenshots begin.")
                } else {
                    TimelineBar(blocks: timeline)
                        .frame(height: 54)

                    HStack {
                        Text("Start")
                        Spacer()
                        Text("Midday")
                        Spacer()
                        Text("Now")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(TigerPalette.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private var breakdownSection: some View {
        TigerPanel(padding: 20, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 18) {
                TigerSectionHeader(
                    eyebrow: "Composition",
                    title: "Attention Breakdown",
                    detail: "Where the day is actually going."
                )

                if daily.categories.isEmpty && !isLoading {
                    emptyState(message: "No captured activity yet.")
                } else {
                    HStack(spacing: 22) {
                        Chart(daily.categories) { cat in
                            SectorMark(
                                angle: .value("Minutes", cat.minutes),
                                innerRadius: .ratio(0.62),
                                angularInset: 2
                            )
                            .foregroundStyle(cat.type.color)
                            .cornerRadius(8)
                        }
                        .frame(width: 180, height: 180)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(daily.categories) { cat in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(cat.type.color)
                                        .frame(width: 10, height: 10)

                                    Text(cat.name)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(TigerPalette.textPrimary)

                                    Spacer()

                                    Text(cat.minutes.tigerDuration)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(TigerPalette.textSecondary)
                                }
                            }

                            if !daily.topDistractors.isEmpty {
                                TigerDivider()
                                    .padding(.vertical, 2)

                                Text("Top distractors")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(1.2)
                                    .foregroundColor(TigerPalette.textMuted)

                                Text(daily.topDistractors.joined(separator: " • "))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(TigerPalette.textSecondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 400)
    }

    private var reportCard: some View {
        TigerPanel(padding: 20, cornerRadius: 24, emphasis: 1.0) {
            VStack(alignment: .leading, spacing: 18) {
                TigerSectionHeader(
                    eyebrow: "Verdict",
                    title: "Mom’s Report Card",
                    detail: daily.hasReport ? "Generated from today’s real behavior." : "This appears after 6 PM when enough data exists."
                )

                if daily.hasReport {
                    HStack(alignment: .top, spacing: 18) {
                        Text(daily.momGrade)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(gradeColor(daily.momGrade))
                            .frame(width: 84)

                        Text(daily.momCommentary)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(TigerPalette.textPrimary)
                            .lineSpacing(5)
                    }
                } else {
                    emptyState(message: "Tiger Mom is still collecting evidence before issuing judgment.")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }

    private var weeklyTrends: some View {
        TigerPanel(padding: 20, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 18) {
                TigerSectionHeader(
                    eyebrow: "Momentum",
                    title: "Weekly Trendline",
                    detail: "The shape of your consistency across the week."
                )

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
                            .cornerRadius(6)

                            LineMark(
                                x: .value("Day", day.label),
                                y: .value("Distraction", day.distractionPercent / 10)
                            )
                            .foregroundStyle(TigerPalette.coral)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .symbol(.circle)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.06))
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))h")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(TigerPalette.textMuted)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks {
                            AxisValueLabel()
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(TigerPalette.textMuted)
                        }
                    }
                    .frame(height: 240)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 400)
    }

    private func emptyState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TigerInlineGlyph(size: 28)
            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(TigerPalette.textSecondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
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

    private var dashboardSummary: String {
        if isLoading { return "Refreshing your local summary." }
        if appState.isTracking { return "Tracking is active and the day is unfolding in real time." }
        return "Tracking is paused. Resume when you want a live picture of the day."
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

        withAnimation(.spring(response: 1.0, dampingFraction: 0.75)) {
            focusRingProgress = Double(daily.focusScore) / 100.0
        }
    }
}

struct TimelineBar: View {
    let blocks: [TimelineBlock]

    var body: some View {
        GeometryReader { geo in
            let totalMinutes = max(totalSpan, 1)

            HStack(spacing: 3) {
                ForEach(blocks) { block in
                    let fraction = CGFloat(block.endMinute - block.startMinute) / CGFloat(totalMinutes)
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(block.type.color.gradient)
                        .frame(width: max((fraction * geo.size.width) - 3, 8))
                }
            }
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }

    private var totalSpan: Int {
        guard let first = blocks.first, let last = blocks.last else { return 1 }
        return max(last.endMinute - first.startMinute, 1)
    }
}

struct PermissionBanner: View {
    let onGrantAccess: () -> Void

    var body: some View {
        TigerPanel(padding: 18, cornerRadius: 22) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(TigerPalette.gold.opacity(0.1))
                        .frame(width: 42, height: 42)
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(TigerPalette.gold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Recording Permission Required")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(TigerPalette.textPrimary)
                    Text("Tiger Mom needs screen access to render the timeline, activity log, and coaching.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(TigerPalette.textSecondary)
                }

                Spacer()

                Button("Grant Access") {
                    onGrantAccess()
                }
                .buttonStyle(TigerButtonStyle(tint: TigerPalette.gold, prominence: .primary))
            }
        }
    }
}
