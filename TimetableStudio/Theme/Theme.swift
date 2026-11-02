import SwiftUI

/// All colours and metrics were sampled from reference screenshots taken on a
/// 430 pt wide iPhone (1290 px @3x). Values are in points.
enum Theme {
    // MARK: Base surfaces
    static let background = Color(hex: 0x000000)
    static let surface = Color(hex: 0x1C1C1D)        // cards, grid, list rows
    static let sheet = Color(hex: 0x1C1C1E)          // lesson detail sheet
    static let gridLine = Color(hex: 0x343C44)
    static let listSeparator = Color(hex: 0x3D3D40)
    static let sheetSeparator = Color(hex: 0x323D45)

    // MARK: Text
    static let textPrimary = Color(hex: 0xF3F5F7)
    static let textSecondary = Color(hex: 0xDCDFE4)
    static let textTitle = Color(hex: 0xC0C8CE)      // large titles, headers
    static let textWarm = Color(hex: 0xFDF2EB)       // big date on home card
    static let icon = Color(hex: 0x838E9A)
    static let iconSheet = Color(hex: 0x818F9C)
    static let onBadge = Color(hex: 0x11161C)
    static let separatorBar = Color(hex: 0x525458)

    // MARK: Accent
    static let accent = Color(hex: 0xEC6A42)         // "today" orange

    // MARK: Glass-ish buttons (fallback when Liquid Glass is unavailable)
    static let circleButton = Color(hex: 0x121212)
    static let circleButtonGlyph = Color(hex: 0x8C97A4)

    // MARK: Holiday
    static let holidayFill = Color(hex: 0x6E81BB)
    static let holidayBorder = Color(hex: 0x515F7F)
    static let holidayText = Color(hex: 0x11161C)

    // MARK: Timetable metrics
    static let pointsPerMinute: CGFloat = 1.2
    static let timeColumnWidth: CGFloat = 44
    static let gridTopPadding: CGFloat = 16.3
    static let gridBottomPadding: CGFloat = 120
    static let gridLineWidth: CGFloat = 2.0 / 3.0
    static let cardCorner: CGFloat = 4
    static let cardInsetLeading: CGFloat = 1.33
    static let cardInsetTrailing: CGFloat = 1.33
    static let cardTextFont: CGFloat = 12
    static let cardLineHeight: CGFloat = 14.33
    static let navRowHeight: CGFloat = 44
    static let dayHeaderHeight: CGFloat = 49.7

    // MARK: Lists / cards
    static let cardCornerLarge: CGFloat = 26
    static let rowHeight: CGFloat = 52
}

// MARK: - Lesson card palette

struct CardPalette {
    var fill: Color
    var bar: Color
    var text: Color
    var border: Color?
    var badge: Color
    var badgeGlyph: Color
    var strike: Bool
}

extension CardPalette {
    static func make(for lesson: Lesson, past: Bool) -> CardPalette {
        let pastFill = Color(hex: 0x343C44)
        let pastBar = Color(hex: 0x7A8289)
        let pastText = Theme.textSecondary
        let futureFill = Color(hex: 0x627280)
        let futureBar = Color(hex: 0xC0C8CE)
        let futureText = Theme.textPrimary

        var p = CardPalette(
            fill: past ? pastFill : futureFill,
            bar: past ? pastBar : futureBar,
            text: past ? pastText : futureText,
            border: nil,
            badge: Color(hex: 0x343C44),
            badgeGlyph: Theme.icon,
            strike: false
        )

        switch lesson.status {
        case .regular:
            break
        case .cancelled:
            p.fill = past ? pastFill : Color(hex: 0x76142F)
            p.border = past ? Color(hex: 0xCC2B4A) : Color(hex: 0xDD4466)
            p.strike = true
        case .substitution:
            p.fill = past ? pastFill : Color(hex: 0x4E3A7E)
            p.border = past ? Color(hex: 0x7C62C2) : Color(hex: 0x9F80F5)
        case .exam:
            p.fill = past ? pastFill : Color(hex: 0x6E5212)
            p.border = past ? Color(hex: 0xBF9530) : Color(hex: 0xF1B93A)
        case .additional:
            p.fill = past ? pastFill : Color(hex: 0x1D5E4B)
            p.border = past ? Color(hex: 0x2F9A79) : Color(hex: 0x3CC79A)
        case .event:
            p.fill = past ? pastFill : Color(hex: 0x2C5683)
            p.border = past ? Color(hex: 0x4A86BE) : Color(hex: 0x5DA9F0)
        }

        if let hex = lesson.colorHex, let custom = Color(hexString: hex), !past {
            p.fill = custom
        }
        return p
    }

    /// Small accent used for status chips in the detail sheet.
    static func statusColor(_ status: LessonStatus) -> Color {
        switch status {
        case .regular: return Theme.icon
        case .cancelled: return Color(hex: 0xDD4466)
        case .substitution: return Color(hex: 0x9F80F5)
        case .exam: return Color(hex: 0xF1B93A)
        case .additional: return Color(hex: 0x3CC79A)
        case .event: return Color(hex: 0x5DA9F0)
        }
    }
}

// MARK: - Colour helpers

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    init?(hexString: String) {
        var s = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(hex: v)
    }

    /// "#RRGGBB" representation (sRGB), used to persist custom card colours.
    var hexString: String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        func c(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", c(r), c(g), c(b))
    }
}

// MARK: - Glass circle button

extension View {
    /// 44 pt circular button background. Uses Liquid Glass on iOS 26+, a dark
    /// filled circle with a hairline border on earlier systems.
    @ViewBuilder
    func glassCircleBackground() -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Circle())
        } else {
            self.background(
                Circle()
                    .fill(Theme.circleButton)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            )
        }
        #else
        self.background(
            Circle()
                .fill(Theme.circleButton)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        )
        #endif
    }
}

struct CircleGlyph: View {
    var systemName: String
    var rotate: Bool = false
    var size: CGFloat = 20
    var weight: Font.Weight = .regular
    var color: Color = Theme.circleButtonGlyph

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: weight))
            .rotationEffect(.degrees(rotate ? 90 : 0))
            .foregroundStyle(color)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .glassCircleBackground()
    }
}

/// Vertical "⋮" glyph drawn with three dots (matches the reference better than
/// a rotated SF Symbol).
struct VerticalDots: View {
    var dot: CGFloat = 4.3
    var spacing: CGFloat = 3.3
    var color: Color = Theme.circleButtonGlyph

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<3, id: \.self) { _ in
                Circle().fill(color).frame(width: dot, height: dot)
            }
        }
    }
}

struct MoreCircleLabel: View {
    var body: some View {
        VerticalDots()
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .glassCircleBackground()
    }
}
