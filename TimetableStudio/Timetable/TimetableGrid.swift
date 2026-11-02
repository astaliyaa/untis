import SwiftUI

struct GridMetrics {
    var start: Int
    var end: Int

    func y(_ minute: Int) -> CGFloat {
        Theme.gridTopPadding + CGFloat(minute - start) * Theme.pointsPerMinute
    }

    var contentHeight: CGFloat { y(end) + Theme.gridBottomPadding }
}

/// Lessons placed side by side when they overlap.
struct PlacedLesson: Identifiable {
    var lesson: Lesson
    var lane: Int
    var lanes: Int
    var id: UUID { lesson.id }
}

enum LaneLayout {
    static func place(_ lessons: [Lesson]) -> [PlacedLesson] {
        let sorted = lessons.sorted { ($0.start, $0.end) < ($1.start, $1.end) }
        var result: [PlacedLesson] = []
        var cluster: [PlacedLesson] = []
        var laneEnds: [Int] = []
        var clusterEnd = Int.min

        func flush() {
            let lanes = max(1, laneEnds.count)
            result += cluster.map { var p = $0; p.lanes = lanes; return p }
            cluster = []
            laneEnds = []
        }

        for l in sorted {
            if l.start >= clusterEnd && !cluster.isEmpty { flush() }
            var lane = laneEnds.firstIndex { $0 <= l.start } ?? -1
            if lane == -1 {
                laneEnds.append(l.end)
                lane = laneEnds.count - 1
            } else {
                laneEnds[lane] = l.end
            }
            cluster.append(PlacedLesson(lesson: l, lane: lane, lanes: 1))
            clusterEnd = max(clusterEnd == Int.min ? l.end : clusterEnd, l.end)
        }
        flush()
        return result
    }
}

/// Header row under the title bar: "W 45 / Nov" plus one label per day.
struct DayHeaderRow: View {
    @EnvironmentObject private var store: MockStore
    var days: [DayKey]
    var width: CGFloat
    var onTapDay: (DayKey) -> Void

    var body: some View {
        let t = store.t
        let today = store.today
        let first = days.first ?? today
        let colW = (width - Theme.timeColumnWidth) / CGFloat(max(days.count, 1))

        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(t.weekPrefix) \(first.isoWeek)")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                Text(t.monthShort(first))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, 6)
            .frame(width: Theme.timeColumnWidth, alignment: .leading)

            ForEach(days) { d in
                let isToday = d == today
                Button { onTapDay(d) } label: {
                    VStack(spacing: 1) {
                        Text(t.dayShort(d))
                            .font(.system(size: 14))
                            .foregroundStyle(isToday ? Theme.accent : Theme.textSecondary)
                        Text("\(d.day)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isToday ? Theme.accent : Theme.textPrimary)
                    }
                    .frame(width: colW)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .frame(width: width, height: Theme.dayHeaderHeight, alignment: .topLeading)
        .background(Theme.background)
    }
}

/// The scrollable time grid for one or more days.
struct TimeGrid: View {
    @EnvironmentObject private var store: MockStore
    var days: [DayKey]
    var width: CGFloat
    var onTapLesson: (Lesson) -> Void
    var onTapEmpty: (DayKey, Int) -> Void
    var contextActions: (Lesson) -> AnyView

    var body: some View {
        let t = store.t
        let dayLessons = days.map { store.lessons(on: $0) }
        let range = store.gridRange(including: dayLessons.flatMap { $0 })
        let metrics = GridMetrics(start: range.start, end: range.end)
        let periods = store.sortedPeriods
        let colW = (width - Theme.timeColumnWidth) / CGFloat(max(days.count, 1))
        let boundaries = Array(Set(periods.flatMap { [$0.start, $0.end] })).sorted()
        let labels = Self.labels(periods)

        ZStack(alignment: .topLeading) {
            // Tap targets for empty slots (below everything else).
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                Color.clear
                    .frame(width: colW, height: metrics.contentHeight)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { location in
                        let minute = range.start + Int((location.y - Theme.gridTopPadding) / Theme.pointsPerMinute)
                        onTapEmpty(day, minute)
                    }
                    .offset(x: Theme.timeColumnWidth + CGFloat(index) * colW)
            }

            // Horizontal grid lines at every period boundary.
            ForEach(boundaries, id: \.self) { m in
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(width: width - Theme.timeColumnWidth, height: Theme.gridLineWidth)
                    .offset(x: Theme.timeColumnWidth, y: metrics.y(m) - Theme.gridLineWidth / 2)
                    .allowsHitTesting(false)
            }

            // Time labels.
            ForEach(labels, id: \.self) { label in
                Text(TimeFmt.hhmm(label.minute))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: Theme.timeColumnWidth, height: Theme.cardLineHeight)
                    .offset(y: label.isEnd ? metrics.y(label.minute) - Theme.cardLineHeight : metrics.y(label.minute) - 0.6)
                    .allowsHitTesting(false)
            }

            // Day columns.
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                let x0 = Theme.timeColumnWidth + CGFloat(index) * colW
                if let holiday = store.holiday(on: day) {
                    HolidayBlock(holiday: holiday, t: t, width: colW,
                                 height: metrics.contentHeight - metrics.y(range.start))
                        .offset(x: x0, y: metrics.y(range.start) + 0.5)
                } else {
                    ForEach(LaneLayout.place(dayLessons[index])) { placed in
                        let gap: CGFloat = Theme.cardInsetLeading + Theme.cardInsetTrailing
                        let laneW = (colW - gap - CGFloat(placed.lanes - 1) * gap) / CGFloat(placed.lanes)
                        let x = x0 + Theme.cardInsetLeading + CGFloat(placed.lane) * (laneW + gap)
                        let y = metrics.y(placed.lesson.start) + 1
                        let h = max(8, metrics.y(placed.lesson.end) - metrics.y(placed.lesson.start) - 2.2)
                        LessonCard(lesson: placed.lesson, past: store.isPast(placed.lesson), width: laneW, height: h)
                            .onTapGesture { onTapLesson(placed.lesson) }
                            .contextMenu { contextActions(placed.lesson) }
                            .offset(x: x, y: y)
                    }
                }
            }
        }
        .frame(width: width, height: metrics.contentHeight, alignment: .topLeading)
    }

    struct TimeLabel: Hashable {
        var minute: Int
        var isEnd: Bool
    }

    /// A start label for every period, plus an end label where a break follows.
    static func labels(_ periods: [Period]) -> [TimeLabel] {
        var out: [TimeLabel] = []
        for (i, p) in periods.enumerated() {
            out.append(TimeLabel(minute: p.start, isEnd: false))
            let next = i + 1 < periods.count ? periods[i + 1] : nil
            if next == nil || next!.start > p.end {
                out.append(TimeLabel(minute: p.end, isEnd: true))
            }
        }
        return out
    }
}

/// One page of the horizontal pager (a week or a single day).
struct TimetablePage: View {
    var days: [DayKey]
    var width: CGFloat
    var onTapDay: (DayKey) -> Void
    var onTapLesson: (Lesson) -> Void
    var onTapEmpty: (DayKey, Int) -> Void
    var contextActions: (Lesson) -> AnyView

    var body: some View {
        VStack(spacing: 0) {
            DayHeaderRow(days: days, width: width, onTapDay: onTapDay)
            ScrollView(.vertical) {
                TimeGrid(days: days, width: width, onTapLesson: onTapLesson,
                         onTapEmpty: onTapEmpty, contextActions: contextActions)
            }
            .scrollIndicators(.hidden)
            .background(Theme.surface)
        }
        .frame(width: width)
    }
}
