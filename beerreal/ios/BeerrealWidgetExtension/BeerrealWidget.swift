import SwiftUI
import WidgetKit

private let widgetAppGroup = "group.de.maxengl.zapfen.mobile"
private let widgetSnapshotKey = "widgetSnapshot"

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Snapshot model (mirrors WidgetSnapshot pushed from the Flutter app)
// ─────────────────────────────────────────────────────────────────────────

struct WAvatar: Codable {
    let initial: String
    let colorHex: String
}

struct WPodiumEntry: Codable {
    let rank: Int
    let value: Int
    let isYou: Bool
}

struct WidgetSnapshot: Codable {
    var totalPints: Int
    var pintsToday: Int
    var last24hCount: Int
    var last24hHours: [Double]
    var streakDays: Int
    var streakGrid: [Int]
    var friendsTodayCount: Int
    var friendsTotal: Int
    var friendAvatars: [WAvatar]
    var circleRank: Int
    var circleTotal: Int
    var circleTrend: Int
    var circlePodium: [WPodiumEntry]
    var updatedAt: Double

    static let empty = WidgetSnapshot(
        totalPints: 0, pintsToday: 0,
        last24hCount: 0, last24hHours: [],
        streakDays: 0, streakGrid: [],
        friendsTodayCount: 0, friendsTotal: 0, friendAvatars: [],
        circleRank: 0, circleTotal: 0, circleTrend: 0, circlePodium: [],
        updatedAt: 0
    )

    enum CodingKeys: String, CodingKey {
        case totalPints, pintsToday, last24hCount, last24hHours, streakDays, streakGrid,
             friendsTodayCount, friendsTotal, friendAvatars, circleRank, circleTotal,
             circleTrend, circlePodium, updatedAt
    }

    init(
        totalPints: Int, pintsToday: Int, last24hCount: Int, last24hHours: [Double],
        streakDays: Int, streakGrid: [Int], friendsTodayCount: Int, friendsTotal: Int,
        friendAvatars: [WAvatar], circleRank: Int, circleTotal: Int, circleTrend: Int,
        circlePodium: [WPodiumEntry], updatedAt: Double
    ) {
        self.totalPints = totalPints
        self.pintsToday = pintsToday
        self.last24hCount = last24hCount
        self.last24hHours = last24hHours
        self.streakDays = streakDays
        self.streakGrid = streakGrid
        self.friendsTodayCount = friendsTodayCount
        self.friendsTotal = friendsTotal
        self.friendAvatars = friendAvatars
        self.circleRank = circleRank
        self.circleTotal = circleTotal
        self.circleTrend = circleTrend
        self.circlePodium = circlePodium
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalPints = try c.decodeIfPresent(Int.self, forKey: .totalPints) ?? 0
        pintsToday = try c.decodeIfPresent(Int.self, forKey: .pintsToday) ?? 0
        last24hCount = try c.decodeIfPresent(Int.self, forKey: .last24hCount) ?? 0
        last24hHours = try c.decodeIfPresent([Double].self, forKey: .last24hHours) ?? []
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        streakGrid = try c.decodeIfPresent([Int].self, forKey: .streakGrid) ?? []
        friendsTodayCount = try c.decodeIfPresent(Int.self, forKey: .friendsTodayCount) ?? 0
        friendsTotal = try c.decodeIfPresent(Int.self, forKey: .friendsTotal) ?? 0
        friendAvatars = try c.decodeIfPresent([WAvatar].self, forKey: .friendAvatars) ?? []
        circleRank = try c.decodeIfPresent(Int.self, forKey: .circleRank) ?? 0
        circleTotal = try c.decodeIfPresent(Int.self, forKey: .circleTotal) ?? 0
        circleTrend = try c.decodeIfPresent(Int.self, forKey: .circleTrend) ?? 0
        circlePodium = try c.decodeIfPresent([WPodiumEntry].self, forKey: .circlePodium) ?? []
        updatedAt = try c.decodeIfPresent(Double.self, forKey: .updatedAt) ?? 0
    }

    static func load() -> WidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: widgetAppGroup),
            let data = defaults.data(forKey: widgetSnapshotKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Color / theme helpers
// ─────────────────────────────────────────────────────────────────────────

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

/// Mirrors avatar_color_util.dart's `shouldUseWhiteText` so the friend
/// avatar initials read clearly against any saved avatar color.
private func widgetTextIsWhite(onHex hex: String) -> Bool {
    let sanitized = hex.replacingOccurrences(of: "#", with: "")
    var rgb: UInt64 = 0
    Scanner(string: sanitized).scanHexInt64(&rgb)
    func linearize(_ v: Double) -> Double {
        v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
    }
    let r = linearize(Double((rgb & 0xFF0000) >> 16) / 255)
    let g = linearize(Double((rgb & 0x00FF00) >> 8) / 255)
    let b = linearize(Double(rgb & 0x0000FF) / 255)
    let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance < 0.5
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// Widget-surface tokens mirroring `PintTheme` (lib/theme.dart) plus the
/// `widgetBg/widgetBorder/widgetTrack` tokens added for widgets specifically.
struct WTheme {
    let widgetBg: Color
    let widgetBorder: Color
    let widgetTrack: Color
    let text: Color
    let textMuted: Color
    let textFaint: Color
    let gold: Color
    let goldInk: Color
    let goldText: Color
    let streakCell: [Color]

    static let dark = WTheme(
        widgetBg: Color(hex: "#171411"),
        widgetBorder: Color.white.opacity(0.07),
        widgetTrack: Color.white.opacity(0.12),
        text: .white,
        textMuted: Color.white.opacity(0.55),
        textFaint: Color.white.opacity(0.4),
        gold: Color(hex: "#F6B733"),
        goldInk: Color(hex: "#3A1F02"),
        goldText: Color(hex: "#F6B733"),
        streakCell: [
            Color.white.opacity(0.04),
            Color(hex: "#F6B733").opacity(0.25),
            Color(hex: "#F6B733").opacity(0.55),
            Color(hex: "#F6B733").opacity(0.95),
        ]
    )

    static let light = WTheme(
        widgetBg: .white,
        widgetBorder: Color.black.opacity(0.07),
        widgetTrack: Color.black.opacity(0.12),
        text: Color(hex: "#0A0A0A"),
        textMuted: Color.black.opacity(0.55),
        textFaint: Color.black.opacity(0.4),
        gold: Color(hex: "#F6B733"),
        goldInk: Color(hex: "#3A1F02"),
        goldText: Color(hex: "#9C6610"),
        streakCell: [
            Color.black.opacity(0.05),
            Color(hex: "#F6B733").opacity(0.3),
            Color(hex: "#F6B733").opacity(0.6),
            Color(hex: "#D98A14").opacity(0.95),
        ]
    )

    static func current(_ scheme: ColorScheme) -> WTheme {
        scheme == .dark ? .dark : .light
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Glyphs (simple stroke style, matches the in-app icon set)
// ─────────────────────────────────────────────────────────────────────────

private struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 7 * s, y: 3 * s))
        p.addLine(to: CGPoint(x: 15 * s, y: 3 * s))
        p.addLine(to: CGPoint(x: 14.4 * s, y: 19 * s))
        p.addQuadCurve(to: CGPoint(x: 12.4 * s, y: 20.9 * s), control: CGPoint(x: 14.4 * s, y: 20.4 * s))
        p.addLine(to: CGPoint(x: 9.6 * s, y: 20.9 * s))
        p.addQuadCurve(to: CGPoint(x: 7.6 * s, y: 19 * s), control: CGPoint(x: 9.6 * s, y: 20.4 * s))
        p.closeSubpath()
        p.move(to: CGPoint(x: 15 * s, y: 7 * s))
        p.addLine(to: CGPoint(x: 17 * s, y: 7 * s))
        p.addQuadCurve(to: CGPoint(x: 17 * s, y: 12 * s), control: CGPoint(x: 19.5 * s, y: 9.5 * s))
        p.addLine(to: CGPoint(x: 14.8 * s, y: 12 * s))
        p.move(to: CGPoint(x: 7 * s, y: 8 * s))
        p.addLine(to: CGPoint(x: 15 * s, y: 8 * s))
        return p
    }
}

private struct ClockShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.addEllipse(in: CGRect(x: 3 * s, y: 3 * s, width: 18 * s, height: 18 * s))
        p.move(to: CGPoint(x: 12 * s, y: 7 * s))
        p.addLine(to: CGPoint(x: 12 * s, y: 12 * s))
        p.addLine(to: CGPoint(x: 15 * s, y: 14 * s))
        return p
    }
}

private struct BoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 13 * s, y: 2 * s))
        p.addLine(to: CGPoint(x: 4 * s, y: 14 * s))
        p.addLine(to: CGPoint(x: 11 * s, y: 14 * s))
        p.addLine(to: CGPoint(x: 10 * s, y: 22 * s))
        p.addLine(to: CGPoint(x: 19 * s, y: 10 * s))
        p.addLine(to: CGPoint(x: 12 * s, y: 10 * s))
        p.closeSubpath()
        return p
    }
}

private struct FriendsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.addEllipse(in: CGRect(x: 5.5 * s, y: 4.5 * s, width: 7 * s, height: 7 * s))
        p.addEllipse(in: CGRect(x: 14.5 * s, y: 6.5 * s, width: 5 * s, height: 5 * s))
        p.move(to: CGPoint(x: 3 * s, y: 20 * s))
        p.addCurve(
            to: CGPoint(x: 15 * s, y: 20 * s),
            control1: CGPoint(x: 3 * s, y: 17 * s),
            control2: CGPoint(x: 15 * s, y: 17 * s)
        )
        p.move(to: CGPoint(x: 15 * s, y: 20 * s))
        p.addQuadCurve(to: CGPoint(x: 19 * s, y: 16 * s), control: CGPoint(x: 15 * s, y: 16 * s))
        return p
    }
}

private struct TrophyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 7 * s, y: 4 * s))
        p.addLine(to: CGPoint(x: 17 * s, y: 4 * s))
        p.addLine(to: CGPoint(x: 17 * s, y: 8 * s))
        p.addArc(center: CGPoint(x: 12 * s, y: 8 * s), radius: 5 * s, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: 7 * s, y: 4 * s))
        p.move(to: CGPoint(x: 7 * s, y: 6 * s))
        p.addLine(to: CGPoint(x: 4 * s, y: 6 * s))
        p.addLine(to: CGPoint(x: 4 * s, y: 7 * s))
        p.addQuadCurve(to: CGPoint(x: 7 * s, y: 10 * s), control: CGPoint(x: 4 * s, y: 10 * s))
        p.move(to: CGPoint(x: 17 * s, y: 6 * s))
        p.addLine(to: CGPoint(x: 20 * s, y: 6 * s))
        p.addLine(to: CGPoint(x: 20 * s, y: 7 * s))
        p.addQuadCurve(to: CGPoint(x: 17 * s, y: 10 * s), control: CGPoint(x: 20 * s, y: 10 * s))
        p.move(to: CGPoint(x: 12 * s, y: 13 * s))
        p.addLine(to: CGPoint(x: 12 * s, y: 16 * s))
        p.move(to: CGPoint(x: 9 * s, y: 20 * s))
        p.addLine(to: CGPoint(x: 15 * s, y: 20 * s))
        p.move(to: CGPoint(x: 10 * s, y: 20 * s))
        p.addQuadCurve(to: CGPoint(x: 14 * s, y: 20 * s), control: CGPoint(x: 12 * s, y: 18 * s))
        return p
    }
}

private struct UpChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 6 * s, y: 14 * s))
        p.addLine(to: CGPoint(x: 12 * s, y: 8 * s))
        p.addLine(to: CGPoint(x: 18 * s, y: 14 * s))
        return p
    }
}

private struct DownChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = rect.width / 24
        var p = Path()
        p.move(to: CGPoint(x: 6 * s, y: 10 * s))
        p.addLine(to: CGPoint(x: 12 * s, y: 16 * s))
        p.addLine(to: CGPoint(x: 18 * s, y: 10 * s))
        return p
    }
}

/// The golden "Z" monogram on black with foam-bubble dots — same mark used
/// throughout the app (see widgets/brand_mark.dart), shown in each widget's
/// header.
private struct ZBrandMark: View {
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#FFE89A"), Color(hex: "#F6B733"),
                    Color(hex: "#D98A14"), Color(hex: "#7A3F06"),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .mask(
                Text("Z").font(.system(size: size * 0.92, weight: .black))
            )
            GeometryReader { geo in
                Circle().fill(Color.white)
                    .frame(width: size * 0.11, height: size * 0.11)
                    .position(x: geo.size.width * 0.40, y: geo.size.height * 0.12)
                Circle().fill(Color.white)
                    .frame(width: size * 0.075, height: size * 0.075)
                    .position(x: geo.size.width * 0.58, y: geo.size.height * 0.08)
                Circle().fill(Color(hex: "#F0EBDE"))
                    .frame(width: size * 0.056, height: size * 0.056)
                    .position(x: geo.size.width * 0.68, y: geo.size.height * 0.15)
            }
        }
        .frame(width: size, height: size)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Shared widget chrome
// ─────────────────────────────────────────────────────────────────────────

private struct WShell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        // The actual surface color + corner rounding comes from
        // `.containerBackground` on the entry view, which paints behind the
        // system's own native widget corner mask — no separate background,
        // clip, or border here, so there's no seam between two
        // slightly-different rounded rects and no double edge inset.
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct WHeadRow<Icon: View>: View {
    let label: String
    let color: Color
    @ViewBuilder var icon: () -> Icon

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                icon()
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.3)
                    .foregroundColor(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            ZBrandMark(size: 16)
        }
    }
}

private struct WAvatarView: View {
    let avatar: WAvatar
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color(hex: avatar.colorHex))
            .frame(width: size, height: size)
            .overlay(
                Text(avatar.initial)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(widgetTextIsWhite(onHex: avatar.colorHex) ? .white : .black.opacity(0.87))
            )
    }
}

private extension View {
    /// Paints the widget's real surface color behind the system's own
    /// native corner mask, filling the entire widget bounds edge-to-edge.
    func widgetContainer(_ background: Color) -> some View {
        self.containerBackground(for: .widget) { background }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - 1 · Total pints (gold hero)
// ─────────────────────────────────────────────────────────────────────────

private struct TotalPintsView: View {
    let theme: WTheme
    let snapshot: WidgetSnapshot

    var body: some View {
        let ink = theme.goldInk
        WShell {
            WHeadRow(label: "Insgesamt", color: ink.opacity(0.75)) {
                GlassShape()
                    .stroke(ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 15, height: 15)
            }
            Spacer(minLength: 0)
            Text("\(snapshot.totalPints)")
                .font(.system(size: 50, weight: .black))
                .tracking(-2.5)
                .foregroundColor(ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.top, 2)
            HStack(spacing: 4) {
                Text("Drinks")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ink.opacity(0.82))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if snapshot.pintsToday > 0 {
                    Text("+\(snapshot.pintsToday) heute")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.16)))
                }
            }
            .padding(.top, 4)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - 2 · Last 24h
// ─────────────────────────────────────────────────────────────────────────

private struct Last24View: View {
    let theme: WTheme
    let snapshot: WidgetSnapshot

    var body: some View {
        WShell {
            WHeadRow(label: "Letzte 24h", color: theme.textMuted) {
                ClockShape()
                    .stroke(theme.goldText, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 15, height: 15)
            }
            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(snapshot.last24hCount)")
                    .font(.system(size: 46, weight: .black))
                    .tracking(-2.3)
                    .foregroundColor(theme.text)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("Drinks")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
            }
            timeline
                .frame(height: 26)
                .padding(.top, 12)
            HStack {
                Text("0").font(.system(size: 8, weight: .bold)).foregroundColor(theme.textFaint)
                Spacer()
                Text("6").font(.system(size: 8, weight: .bold)).foregroundColor(theme.textFaint)
                Spacer()
                Text("12").font(.system(size: 8, weight: .bold)).foregroundColor(theme.textFaint)
                Spacer()
                Text("18").font(.system(size: 8, weight: .bold)).foregroundColor(theme.textFaint)
                Spacer()
                Text("jetzt").font(.system(size: 8, weight: .bold)).foregroundColor(theme.textFaint)
            }
            .padding(.top, 3)
        }
    }

    private var timeline: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(theme.widgetTrack)
                    .frame(width: geo.size.width, height: 2)
                    .position(x: geo.size.width / 2, y: geo.size.height - 4)
                ForEach([0, 6, 12, 18, 24], id: \.self) { h in
                    Rectangle()
                        .fill(theme.widgetTrack)
                        .frame(width: 1, height: 5)
                        .position(x: geo.size.width * CGFloat(h) / 24, y: geo.size.height - 6)
                }
                ForEach(Array(snapshot.last24hHours.prefix(12).enumerated()), id: \.offset) { _, h in
                    Capsule()
                        .fill(theme.gold)
                        .frame(width: 4, height: 16)
                        .position(x: geo.size.width * CGFloat(min(max(h, 0), 24)) / 24, y: geo.size.height - 12)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - 3 · Streak + grid
// ─────────────────────────────────────────────────────────────────────────

private struct StreakView: View {
    let theme: WTheme
    let snapshot: WidgetSnapshot

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

    var body: some View {
        WShell {
            WHeadRow(label: "Serie", color: theme.textMuted) {
                BoltShape().fill(theme.goldText).frame(width: 15, height: 15)
            }
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(snapshot.streakDays)")
                    .font(.system(size: 44, weight: .black))
                    .tracking(-2.2)
                    .foregroundColor(theme.goldText)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("Tage")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
            }
            .padding(.top, 10)
            Spacer(minLength: 0)
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(0..<21, id: \.self) { i in
                    let level = snapshot.streakGrid[safe: i] ?? 0
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(theme.streakCell[safe: level] ?? theme.streakCell[0])
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2.5)
                                .stroke(theme.gold, lineWidth: i == 20 ? 1.5 : 0)
                        )
                }
            }
            Text("3 Wochen · heute \u{2713}")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(theme.textFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 4)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - 4 · Friends poured today
// ─────────────────────────────────────────────────────────────────────────

private struct FriendsTodayView: View {
    let theme: WTheme
    let snapshot: WidgetSnapshot

    var body: some View {
        WShell {
            WHeadRow(label: "Heute gezapft", color: theme.textMuted) {
                FriendsShape()
                    .stroke(theme.goldText, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 16, height: 16)
            }
            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(snapshot.friendsTodayCount)")
                    .font(.system(size: 44, weight: .black))
                    .tracking(-2.2)
                    .foregroundColor(theme.text)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(snapshot.friendsTotal > 0 ? "von \(snapshot.friendsTotal) Freunden" : "Freunde")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            HStack(spacing: 0) {
                HStack(spacing: -10) {
                    ForEach(Array(snapshot.friendAvatars.prefix(5).enumerated()), id: \.offset) { _, a in
                        WAvatarView(avatar: a, size: 28)
                            .overlay(Circle().stroke(theme.widgetBg, lineWidth: 2))
                    }
                }
                let left = snapshot.friendsTotal - snapshot.friendsTodayCount
                if left > 0 {
                    Text("noch \(left)")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(theme.goldText)
                        .lineLimit(1)
                        .padding(.leading, 8)
                }
            }
            .padding(.top, 14)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - 5 · Circle rank
// ─────────────────────────────────────────────────────────────────────────

private struct PodiumBar {
    let rank: Int
    let height: CGFloat
    let isYou: Bool
}

private struct CircleRankView: View {
    let theme: WTheme
    let snapshot: WidgetSnapshot

    var body: some View {
        WShell {
            WHeadRow(label: "Dein Kreis", color: theme.textMuted) {
                TrophyShape()
                    .stroke(theme.goldText, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 15, height: 15)
            }
            Spacer(minLength: 0)
            HStack(alignment: .bottom, spacing: 4) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("#")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(theme.text.opacity(0.5))
                        Text(snapshot.circleTotal > 0 ? "\(snapshot.circleRank)" : "\u{2013}")
                            .font(.system(size: 44, weight: .black))
                            .tracking(-2.2)
                            .foregroundColor(theme.text)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    HStack(spacing: 4) {
                        Text(snapshot.circleTotal > 0 ? "von \(snapshot.circleTotal)" : "noch kein Kreis")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        if snapshot.circleTrend != 0 {
                            let up = snapshot.circleTrend > 0
                            let trendColor = up ? Color(hex: "#22c55e") : Color(hex: "#ef4444")
                            HStack(spacing: 1) {
                                Group {
                                    if up {
                                        UpChevronShape().stroke(trendColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    } else {
                                        DownChevronShape().stroke(trendColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    }
                                }
                                .frame(width: 9, height: 9)
                                Text("\(abs(snapshot.circleTrend))")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundColor(trendColor)
                            }
                        }
                    }
                }
                Spacer(minLength: 4)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(podiumBars, id: \.rank) { p in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(p.isYou ? theme.gold : theme.widgetTrack)
                                .frame(width: 13, height: max(10, p.height))
                            Text("\(p.rank)")
                                .font(.system(size: 7.5, weight: .heavy))
                                .foregroundColor(p.isYou ? theme.goldText : theme.textFaint)
                        }
                    }
                }
                .frame(height: 50)
            }
        }
    }

    /// Visual podium order is 3rd, 1st, 2nd (left to right), matching the
    /// classic medal-stand layout.
    private var podiumBars: [PodiumBar] {
        guard !snapshot.circlePodium.isEmpty else { return [] }
        let maxValue = max(snapshot.circlePodium.map(\.value).max() ?? 1, 1)
        return [3, 1, 2].compactMap { rank -> PodiumBar? in
            guard let entry = snapshot.circlePodium.first(where: { $0.rank == rank }) else { return nil }
            let height = CGFloat(entry.value) / CGFloat(maxValue) * 44
            return PodiumBar(rank: entry.rank, height: height, isYou: entry.isYou)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Timeline plumbing
// ─────────────────────────────────────────────────────────────────────────

struct BeerrealEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct BeerrealProvider: TimelineProvider {
    func placeholder(in context: Context) -> BeerrealEntry {
        BeerrealEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (BeerrealEntry) -> Void) {
        completion(BeerrealEntry(date: Date(), snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BeerrealEntry>) -> Void) {
        let entry = BeerrealEntry(date: Date(), snapshot: WidgetSnapshot.load())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: entry.date)
            ?? entry.date.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Entry views (pick theme from the system color scheme)
// ─────────────────────────────────────────────────────────────────────────

private struct TotalPintsEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: BeerrealEntry

    var body: some View {
        let theme = WTheme.current(colorScheme)
        TotalPintsView(theme: theme, snapshot: entry.snapshot)
            .widgetContainer(theme.gold)
    }
}

private struct Last24EntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: BeerrealEntry

    var body: some View {
        let theme = WTheme.current(colorScheme)
        Last24View(theme: theme, snapshot: entry.snapshot)
            .widgetContainer(theme.widgetBg)
    }
}

private struct StreakEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: BeerrealEntry

    var body: some View {
        let theme = WTheme.current(colorScheme)
        StreakView(theme: theme, snapshot: entry.snapshot)
            .widgetContainer(theme.widgetBg)
    }
}

private struct FriendsTodayEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: BeerrealEntry

    var body: some View {
        let theme = WTheme.current(colorScheme)
        FriendsTodayView(theme: theme, snapshot: entry.snapshot)
            .widgetContainer(theme.widgetBg)
    }
}

private struct CircleRankEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: BeerrealEntry

    var body: some View {
        let theme = WTheme.current(colorScheme)
        CircleRankView(theme: theme, snapshot: entry.snapshot)
            .widgetContainer(theme.widgetBg)
    }
}

// ─────────────────────────────────────────────────────────────────────────
// MARK: - Widget definitions
// ─────────────────────────────────────────────────────────────────────────

struct TotalPintsWidget: Widget {
    let kind = "BeerrealTotalWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeerrealProvider()) { entry in
            TotalPintsEntryView(entry: entry)
        }
        .configurationDisplayName("Insgesamt")
        .description("Deine Gesamtzahl an Drinks, in Zapfen-Gold.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct Last24Widget: Widget {
    let kind = "BeerrealLast24Widget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeerrealProvider()) { entry in
            Last24EntryView(entry: entry)
        }
        .configurationDisplayName("Letzte 24 Stunden")
        .description("Wie viele Drinks du heute gezapft hast, auf einem 24-Stunden-Strahl.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct StreakWidget: Widget {
    let kind = "BeerrealStreakWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeerrealProvider()) { entry in
            StreakEntryView(entry: entry)
        }
        .configurationDisplayName("Serie")
        .description("Deine Tage-Serie plus ein 3-Wochen-Raster.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct FriendsTodayWidget: Widget {
    let kind = "BeerrealFriendsWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeerrealProvider()) { entry in
            FriendsTodayEntryView(entry: entry)
        }
        .configurationDisplayName("Heute gezapft")
        .description("Wer in deinem Kreis heute schon gezapft hat.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct CircleRankWidget: Widget {
    let kind = "BeerrealRankWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeerrealProvider()) { entry in
            CircleRankEntryView(entry: entry)
        }
        .configurationDisplayName("Dein Kreis")
        .description("Dein Platz diese Woche, mit einem Mini-Podium.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

@main
struct BeerrealWidgetBundle: WidgetBundle {
    var body: some Widget {
        TotalPintsWidget()
        Last24Widget()
        StreakWidget()
        FriendsTodayWidget()
        CircleRankWidget()
    }
}
