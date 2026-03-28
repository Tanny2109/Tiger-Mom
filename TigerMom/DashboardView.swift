import SwiftUI
import Charts

// MARK: - Dashboard Data Models

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
        case .deepWork: return .green
        case .communication: return .blue
        case .shallowWork: return .yellow
        case .distraction: return .red
        case .breakTime: return .gray
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    let appState: AppState
    let screenCapture: ScreenCapture

    @State private var daily = DailyAnalytics()
    @State private var timeline: [TimelineBlock] = []
    @State private var weekly: [WeeklyDay] = []
    @State private var isLoading = true
    @State private var focusRingProgress: Double = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerRow
                permissionBanner
                focusRing
                statsRow
                timelineSection
                categoryBreakdown
                momReportCard
                weeklyTrends
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(hex: 0x07070A))
        .task {
            await loadData()
        }
    }

    // MARK: - 1. Header Row

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            HStack(spacing: 12) {
                // Refresh
                Button {
                    Task { await loadData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)

                // Tracking toggle
                Button {
                    appState.isTracking.toggle()
                    if appState.isTracking {
                        screenCapture.start(appState: appState)
                    } else {
                        screenCapture.stop()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.isTracking ? Color.green : Color.red.opacity(0.5))
                            .frame(width: 8, height: 8)
                        Text(appState.isTracking ? "Tracking" : "Paused")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = "Tanmay"
        switch hour {
        case 5..<12: return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        case 17..<22: return "Good evening, \(name)"
        default: return "Late night, \(name)"
        }
    }

    // MARK: - Permission Banner

    @ViewBuilder
    private var permissionBanner: some View {
        if !appState.hasScreenRecordingPermission {
            PermissionBanner {
                screenCapture.requestPermission()
            }
        }
    }

    // MARK: - 2. Focus Ring

    private var focusRing: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 14)
                    .frame(width: 200, height: 200)

                // Progress ring
                Circle()
                    .trim(from: 0, to: focusRingProgress)
                    .stroke(
                        AngularGradient(
                            colors: [Color(hex: 0xF59E0B).opacity(0.4), Color(hex: 0xF59E0B)],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * focusRingProgress)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: 2) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("\(daily.focusScore)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Focus Score")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - 3. Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(
                icon: "bolt.fill",
                value: formatMinutes(daily.deepWorkMinutes),
                label: "Deep Work",
                accent: .green
            )
            StatCard(
                icon: "exclamationmark.triangle.fill",
                value: formatMinutes(daily.distractionMinutes),
                label: "Distractions",
                accent: .red
            )
            StatCard(
                icon: "tray.fill",
                value: formatMinutes(daily.shallowWorkMinutes),
                label: "Shallow Work",
                accent: .yellow
            )
        }
    }

    // MARK: - 4. Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Timeline")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            if timeline.isEmpty && !isLoading {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 40)
                    .overlay(
                        Text("No activity data yet")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.2))
                    )
            } else {
                TimelineBar(blocks: timeline)
                    .frame(height: 40)

                // Time labels
                HStack {
                    Text("9:00 AM")
                    Spacer()
                    Text("12:30 PM")
                    Spacer()
                    Text("Now")
                }
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.25))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
    }

    // MARK: - 5. Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            if daily.categories.isEmpty && !isLoading {
                HStack {
                    Spacer()
                    Text("No data yet")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.2))
                    Spacer()
                }
                .frame(height: 120)
            } else {
                HStack(spacing: 24) {
                    // Donut chart
                    Chart(daily.categories) { cat in
                        SectorMark(
                            angle: .value("Minutes", cat.minutes),
                            innerRadius: .ratio(0.6),
                            angularInset: 1
                        )
                        .foregroundStyle(cat.type.color)
                        .cornerRadius(3)
                    }
                    .frame(width: 140, height: 140)

                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(daily.categories) { cat in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(cat.type.color)
                                    .frame(width: 8, height: 8)
                                Text(cat.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text(formatMinutes(cat.minutes))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
    }

    // MARK: - 6. Mom's Report Card

    private var momReportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("🐯")
                    .font(.system(size: 20))
                Text("Mom's Report Card")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            if daily.hasReport {
                HStack(alignment: .top, spacing: 16) {
                    // Grade
                    Text(daily.momGrade)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(gradeColor(daily.momGrade))
                        .frame(width: 70)

                    // Commentary
                    Text(daily.momCommentary)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineSpacing(4)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(Color(hex: 0xF59E0B).opacity(0.4))
                    Text("Tiger Mom is watching... report card at 6 PM")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(hex: 0xF59E0B).opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - 7. Weekly Trends

    private var weeklyTrends: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Trends")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            if weekly.isEmpty && !isLoading {
                HStack {
                    Spacer()
                    Text("Not enough data for weekly trends")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.2))
                    Spacer()
                }
                .frame(height: 160)
            } else {
                Chart {
                    ForEach(weekly) { day in
                        BarMark(
                            x: .value("Day", day.label),
                            y: .value("Focus Hours", day.focusHours)
                        )
                        .foregroundStyle(Color(hex: 0xF59E0B).opacity(0.7))
                        .cornerRadius(4)

                        LineMark(
                            x: .value("Day", day.label),
                            y: .value("Distraction %", day.distractionPercent / 10)
                        )
                        .foregroundStyle(Color.red.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .symbol {
                            Circle()
                                .fill(Color.red.opacity(0.6))
                                .frame(width: 5, height: 5)
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))h")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.05))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(String.self) {
                                Text(v)
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
    }

    // MARK: - Helpers

    private func gradeColor(_ grade: String) -> Color {
        switch grade.prefix(1) {
        case "A": return .green
        case "B": return Color(hex: 0xF59E0B)
        case "C": return .yellow
        default: return .red
        }
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return "\(h):\(String(format: "%02d", m))"
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        focusRingProgress = 0

        async let dailyReq = APIClient.shared.analyticsDaily()
        async let weeklyReq = APIClient.shared.analyticsWeekly()
        async let timelineReq = APIClient.shared.analyticsTimeline()

        // Daily
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

            if let report = d["mom_report"] as? [String: Any] {
                daily.momGrade = report["grade"] as? String ?? ""
                daily.momCommentary = report["commentary"] as? String ?? ""
                daily.hasReport = true
            }

            appState.focusScore = daily.focusScore
        }

        // Weekly
        if let w = try? await weeklyReq,
           let days = w["days"] as? [[String: Any]] {
            weekly = days.compactMap { day in
                guard let label = day["label"] as? String,
                      let hours = day["focus_hours"] as? Double,
                      let distPct = day["distraction_percent"] as? Double else { return nil }
                return WeeklyDay(label: label, focusHours: hours, distractionPercent: distPct)
            }
        }

        // Timeline
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

        // Animate focus ring
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
            focusRingProgress = Double(daily.focusScore) / 100.0
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let accent: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accent.opacity(0.7))

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
    }
}

// MARK: - Timeline Bar

struct TimelineBar: View {
    let blocks: [TimelineBlock]

    var body: some View {
        GeometryReader { geo in
            let totalMinutes = max(totalSpan, 1)

            HStack(spacing: 1) {
                ForEach(blocks) { block in
                    let fraction = CGFloat(block.endMinute - block.startMinute) / CGFloat(totalMinutes)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(block.type.color)
                        .frame(width: max(fraction * geo.size.width - 1, 2))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var totalSpan: Int {
        guard let first = blocks.first, let last = blocks.last else { return 1 }
        return last.endMinute - first.startMinute
    }
}

// MARK: - Permission Banner

struct PermissionBanner: View {
    let onGrantAccess: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0xF59E0B))

            VStack(alignment: .leading, spacing: 2) {
                Text("Screen Recording Permission Required")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text("Tiger Mom needs screen access to track your activity.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button("Grant Access") {
                onGrantAccess()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0xF59E0B))
            .controlSize(.small)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: 0xF59E0B).opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(hex: 0xF59E0B).opacity(0.2), lineWidth: 1)
                )
        )
    }
}
