import SwiftUI
import UIKit

// Simple outline glyphs drawn in a 24×24 design space. They are generic shapes
// (school building, calendar, document) so they sit nicely next to SF Symbols.

private func scaled(_ rect: CGRect) -> (CGFloat, CGFloat, CGFloat) {
    let s = min(rect.width, rect.height) / 24
    let ox = rect.minX + (rect.width - 24 * s) / 2
    let oy = rect.minY + (rect.height - 24 * s) / 2
    return (s, ox, oy)
}

/// School building with a flag on the roof.
struct SchoolGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let (s, ox, oy) = scaled(rect)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()
        // Flag pole + flag
        path.move(to: p(12, 7.2)); path.addLine(to: p(12, 1.2))
        path.move(to: p(12, 1.4)); path.addLine(to: p(15.6, 1.4)); path.addLine(to: p(15.6, 3.8)); path.addLine(to: p(12, 3.8))
        // Centre block with pitched roof
        path.move(to: p(7.6, 22.6)); path.addLine(to: p(7.6, 10.4)); path.addLine(to: p(12, 7.2))
        path.addLine(to: p(16.4, 10.4)); path.addLine(to: p(16.4, 22.6))
        // Side wings
        path.move(to: p(7.6, 13.2)); path.addLine(to: p(2.4, 13.2)); path.addLine(to: p(2.4, 22.6))
        path.move(to: p(16.4, 13.2)); path.addLine(to: p(21.6, 13.2)); path.addLine(to: p(21.6, 22.6))
        // Ground line
        path.move(to: p(1.2, 22.6)); path.addLine(to: p(22.8, 22.6))
        // Round window
        path.addEllipse(in: CGRect(origin: p(10.4, 10.6), size: CGSize(width: 3.2 * s, height: 3.2 * s)))
        // Door
        path.move(to: p(10.2, 22.6)); path.addLine(to: p(10.2, 18.6))
        path.addArc(center: p(12, 18.6), radius: 1.8 * s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: p(13.8, 22.6))
        // Wing windows (2×2 grid each side)
        for x0 in [3.9, 17.7] as [CGFloat] {
            path.addRect(CGRect(origin: p(x0, 15.6), size: CGSize(width: 2.4 * s, height: 4.6 * s)))
            path.move(to: p(x0, 17.9)); path.addLine(to: p(x0 + 2.4, 17.9))
        }
        return path
    }
}

/// Calendar outline (rings + header line). The day number is drawn separately.
struct CalendarGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let (s, ox, oy) = scaled(rect)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()
        path.addRoundedRect(in: CGRect(origin: p(2, 3.6), size: CGSize(width: 20 * s, height: 18.6 * s)),
                            cornerSize: CGSize(width: 2.2 * s, height: 2.2 * s))
        path.move(to: p(2, 8.4)); path.addLine(to: p(22, 8.4))
        path.move(to: p(7.4, 1.4)); path.addLine(to: p(7.4, 5.4))
        path.move(to: p(16.6, 1.4)); path.addLine(to: p(16.6, 5.4))
        return path
    }
}

/// Document with text lines (used for homework / events, with a cap overlay).
struct DocumentGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let (s, ox, oy) = scaled(rect)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()
        path.move(to: p(11, 22.4))
        path.addLine(to: p(3.6, 22.4))
        path.addQuadCurve(to: p(2, 20.8), control: p(2, 22.4))
        path.addLine(to: p(2, 3.2))
        path.addQuadCurve(to: p(3.6, 1.6), control: p(2, 1.6))
        path.addLine(to: p(13.4, 1.6))
        path.addLine(to: p(17.6, 5.8))
        path.addLine(to: p(17.6, 11))
        path.move(to: p(13.4, 1.6)); path.addLine(to: p(13.4, 5.8)); path.addLine(to: p(17.6, 5.8))
        path.move(to: p(5.4, 9.6)); path.addLine(to: p(14, 9.6))
        path.move(to: p(5.4, 13.4)); path.addLine(to: p(11.4, 13.4))
        path.move(to: p(5.4, 17.2)); path.addLine(to: p(8.8, 17.2))
        return path
    }
}

/// Graduation cap (mortarboard), drawn in its own 24×24 space.
struct CapGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let (s, ox, oy) = scaled(rect)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
        var path = Path()
        path.move(to: p(12, 4)); path.addLine(to: p(23, 9.5)); path.addLine(to: p(12, 15)); path.addLine(to: p(1, 9.5)); path.closeSubpath()
        path.move(to: p(5.5, 12)); path.addLine(to: p(5.5, 18))
        path.addQuadCurve(to: p(18.5, 18), control: p(12, 23))
        path.addLine(to: p(18.5, 12))
        return path
    }
}

private let iconStroke = StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)

/// Document + graduation cap (Homework / My events).
struct HomeworkIcon: View {
    var color: Color = Theme.icon
    var background: Color = Theme.surface
    var size: CGFloat = 24

    var body: some View {
        ZStack(alignment: .topLeading) {
            DocumentGlyph().stroke(color, style: iconStroke)
                .frame(width: size, height: size)
            CapGlyph()
                .fill(background)
                .overlay(CapGlyph().stroke(color, style: iconStroke))
                .frame(width: size * 0.62, height: size * 0.62)
                .offset(x: size * 0.42, y: size * 0.46)
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }
}

/// Calendar + info badge (My Absences).
struct AbsenceIcon: View {
    var color: Color = Theme.icon
    var background: Color = Theme.surface
    var size: CGFloat = 24

    var body: some View {
        ZStack(alignment: .topLeading) {
            CalendarGlyph().stroke(color, style: iconStroke)
                .frame(width: size * 0.86, height: size * 0.86)
            ZStack {
                Circle().fill(background)
                Circle().stroke(color, lineWidth: 1.5)
                Image(systemName: "info")
                    .font(.system(size: size * 0.3, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: size * 0.52, height: size * 0.52)
            .offset(x: size * 0.5, y: size * 0.5)
        }
        .frame(width: size, height: size, alignment: .topLeading)
    }
}

struct SchoolIcon: View {
    var color: Color = Theme.icon
    var size: CGFloat = 24
    var body: some View {
        SchoolGlyph().stroke(color, style: iconStroke).frame(width: size, height: size)
    }
}

/// Row icon: either an SF Symbol or one of the custom glyphs.
enum RowIcon {
    case symbol(String)
    case homework
    case absence
}

struct RowIconView: View {
    var icon: RowIcon
    var background: Color = Theme.surface

    var body: some View {
        Group {
            switch icon {
            case .symbol(let name):
                Image(systemName: name)
                    .font(.system(size: 21, weight: .light))
                    .foregroundStyle(Theme.icon)
            case .homework:
                HomeworkIcon(background: background)
            case .absence:
                AbsenceIcon(background: background)
            }
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Tab bar images

enum TabIcons {
    private static var cache: [String: UIImage] = [:]

    @MainActor
    private static func render<V: View>(_ key: String, _ view: V) -> UIImage {
        if let hit = cache[key] { return hit }
        let renderer = ImageRenderer(content: view.frame(width: 26, height: 26))
        renderer.scale = 3
        let image = (renderer.uiImage ?? UIImage()).withRenderingMode(.alwaysTemplate)
        cache[key] = image
        return image
    }

    @MainActor
    static func home() -> UIImage {
        render("home", SchoolGlyph()
            .stroke(Color.black, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            .padding(1))
    }

    @MainActor
    static func timetable(day: Int) -> UIImage {
        render("tt\(day)", ZStack {
            CalendarGlyph()
                .stroke(Color.black, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            Text("\(day)")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Color.black)
                .offset(y: 3.4)
        }
        .padding(1))
    }
}
