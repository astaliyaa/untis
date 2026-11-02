import SwiftUI

struct CardLine {
    var text: String
    var bold: Bool
    var original: String?
}

extension Lesson {
    /// Lines shown on a timetable card: teacher, subject, room, lesson text.
    var cardLines: [CardLine] {
        var r: [CardLine] = []
        if !teacher.isEmpty || teacherChanged {
            r.append(CardLine(text: teacher, bold: true, original: teacherChanged ? originalTeacher : nil))
        }
        if !subject.isEmpty || subjectChanged {
            r.append(CardLine(text: subject, bold: false, original: subjectChanged ? originalSubject : nil))
        }
        if !room.isEmpty || roomChanged {
            r.append(CardLine(text: room, bold: false, original: roomChanged ? originalRoom : nil))
        }
        if !text.isEmpty {
            r.append(CardLine(text: text, bold: false, original: nil))
        }
        if status == .exam && !examName.isEmpty {
            r.append(CardLine(text: examName, bold: false, original: nil))
        }
        return r
    }
}

/// One period on the timetable grid.
struct LessonCard: View {
    var lesson: Lesson
    var past: Bool
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        let p = CardPalette.make(for: lesson, past: past)
        let lines = lesson.cardLines
        let fit = max(1, Int(((height - 4) / Theme.cardLineHeight).rounded(.down)))
        let overflow = lines.count > fit
        let visible = Array(lines.prefix(fit))
        let showInfo = !overflow && !lesson.info.isEmpty && height >= 22
        let lastBottom = 3.3 + CGFloat(visible.count) * Theme.cardLineHeight
        let badgeZoneTop = height - 4 - 14
        let padLast = (overflow || showInfo) && lastBottom > badgeZoneTop

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(p.fill)
            if let border = p.border {
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .strokeBorder(border, lineWidth: 2)
            }

            Capsule()
                .fill(p.bar)
                .frame(width: 4, height: max(0, height - 8))
                .offset(x: 4, y: 4)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(visible.enumerated()), id: \.offset) { index, line in
                    lineText(line, p)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(height: Theme.cardLineHeight, alignment: .leading)
                        .padding(.trailing, padLast && index == visible.count - 1 ? 18 : 0)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .padding(.top, 3.3)
            .frame(width: width, alignment: .leading)

            if overflow {
                VerticalDots(dot: 3.2, spacing: 2.2, color: p.bar)
                    .frame(width: 14, height: 13.3)
                    .background(p.badge, in: RoundedRectangle(cornerRadius: 3))
                    .offset(x: width - 18, y: height - 17.3)
            } else if showInfo {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(p.badgeGlyph)
                    .frame(width: 14, height: 14)
                    .background(p.badge, in: RoundedRectangle(cornerRadius: 3))
                    .offset(x: width - 18, y: height - 18)
            }
        }
        .frame(width: max(0, width), height: max(0, height), alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }

    private func lineText(_ line: CardLine, _ p: CardPalette) -> Text {
        let main = Text(line.text)
            .font(.system(size: Theme.cardTextFont, weight: line.bold ? .bold : .regular))
            .foregroundStyle(p.text)
            .strikethrough(p.strike, color: p.text)
        guard let original = line.original, !original.isEmpty else { return main }
        let dim = p.text.opacity(0.6)
        let old = Text(original)
            .font(.system(size: Theme.cardTextFont, weight: .regular))
            .foregroundStyle(dim)
            .strikethrough(true, color: dim)
        return Text("\(main) \(old)")
    }
}

/// Full-height holiday block in a day column.
struct HolidayBlock: View {
    var holiday: Holiday
    var t: L10n
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Theme.holidayFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(Theme.holidayBorder, lineWidth: 1.0 / 3.0)
                )
            VStack(spacing: 0) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.bottom, 3)
                Text(t.holiday)
                    .font(.system(size: 16, weight: .semibold))
                Text(holiday.name)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.top, 1)
                Text(holiday.start == holiday.end
                     ? t.holidayDate(holiday.start)
                     : "\(t.holidayDate(holiday.start)) \(t.to) \(t.holidayDate(holiday.end))")
                    .font(.system(size: 14.5))
                    .padding(.top, 8)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(Theme.holidayText)
            .padding(.horizontal, 2)
        }
        .frame(width: width, height: height)
    }
}
