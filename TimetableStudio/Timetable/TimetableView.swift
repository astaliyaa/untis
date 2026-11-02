import SwiftUI

enum TimetableMode { case week, day }

struct LessonRef: Identifiable, Hashable { var id: UUID }

struct EditorItem: Identifiable {
    var lesson: Lesson
    var isNew: Bool
    var id: UUID { lesson.id }
}

struct TimetableView: View {
    @EnvironmentObject private var store: MockStore
    @Binding var showStudio: Bool

    @State private var mode: TimetableMode = .week
    @State private var weekPage: Int? = 0
    @State private var dayPage: Int? = 0
    @State private var anchorMonday: DayKey = DayKey.today.mondayOfWeek
    @State private var anchorDay: DayKey = DayKey.today
    @State private var didInit = false

    @State private var detail: LessonRef?
    @State private var editor: EditorItem?
    @State private var holidayEditor: Holiday?
    @State private var confirmClear = false

    private let weekRange = -52...52
    private let dayRange = -300...300

    private var currentMonday: DayKey { anchorMonday.adding(days: 7 * (weekPage ?? 0)) }
    private var currentDay: DayKey { anchorDay.adding(days: dayPage ?? 0) }
    private var focusDay: DayKey {
        if mode == .day { return currentDay }
        let today = store.today
        if today.mondayOfWeek == currentMonday { return today }
        return currentMonday
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar {
                titleMenu
            } trailing: {
                moreMenu
            }

            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    if mode == .week {
                        weekPager(size: geo.size)
                    } else {
                        dayPager(size: geo.size)
                    }
                    if mode == .day && store.data.settings.showDayIndicator {
                        DayIndicator(index: currentDay.weekdayIndex - 1, count: 7, width: geo.size.width)
                            .offset(y: 9.7)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            if !didInit {
                didInit = true
                resetAnchors(to: store.today)
                if store.data.settings.startInDayView { mode = .day }
            }
        }
        .onChange(of: store.today) { _, newValue in
            resetAnchors(to: newValue)
        }
        .sheet(item: $detail) { ref in
            LessonDetailSheet(lessonID: ref.id)
                .environmentObject(store)
        }
        .sheet(item: $editor) { item in
            LessonEditor(lesson: item.lesson, isNew: item.isNew)
                .environmentObject(store)
        }
        .sheet(item: $holidayEditor) { h in
            HolidayEditor(holiday: h)
                .environmentObject(store)
        }
        .confirmationDialog("Remove every period in week \(currentMonday.isoWeek)?",
                            isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear week", role: .destructive) { store.clearWeek(currentMonday) }
        }
    }

    // MARK: Pagers

    private func weekPager(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(weekRange, id: \.self) { i in
                    let monday = anchorMonday.adding(days: 7 * i)
                    let count = min(max(store.data.settings.weekDayCount, 1), 7)
                    TimetablePage(
                        days: (0..<count).map { monday.adding(days: $0) },
                        width: size.width,
                        onTapDay: { openDay($0) },
                        onTapLesson: { detail = LessonRef(id: $0.id) },
                        onTapEmpty: { day, minute in newLesson(day: day, minute: minute) },
                        contextActions: { AnyView(contextMenu(for: $0)) }
                    )
                    .frame(width: size.width, height: size.height)
                    .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $weekPage)
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.center)
    }

    private func dayPager(size: CGSize) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(dayRange, id: \.self) { i in
                    let day = anchorDay.adding(days: i)
                    TimetablePage(
                        days: [day],
                        width: size.width,
                        onTapDay: { _ in openWeek() },
                        onTapLesson: { detail = LessonRef(id: $0.id) },
                        onTapEmpty: { day, minute in newLesson(day: day, minute: minute) },
                        contextActions: { AnyView(contextMenu(for: $0)) }
                    )
                    .frame(width: size.width, height: size.height)
                    .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $dayPage)
        .scrollIndicators(.hidden)
        .defaultScrollAnchor(.center)
    }

    // MARK: Navigation helpers

    private func resetAnchors(to day: DayKey) {
        anchorMonday = day.mondayOfWeek
        anchorDay = day
        weekPage = 0
        dayPage = 0
    }

    private func openDay(_ day: DayKey) {
        anchorDay = day
        dayPage = 0
        mode = .day
    }

    private func openWeek() {
        anchorMonday = currentDay.mondayOfWeek
        weekPage = 0
        mode = .week
    }

    private func goToday() {
        withAnimation {
            resetAnchors(to: store.today)
        }
    }

    // MARK: Editing helpers

    private func newLesson(day: DayKey, minute: Int? = nil, status: LessonStatus = .regular) {
        let periods = store.sortedPeriods
        var start = 8 * 60
        var end = start + 45
        if let minute, let p = periods.first(where: { $0.start <= minute && minute < $0.end }) {
            start = p.start
            end = p.end
        } else if let minute {
            start = (minute / 15) * 15
            end = start + 45
        } else if let p = periods.first {
            start = p.start
            end = p.end
        }
        let lesson = Lesson(day: day, start: start, end: end, status: status)
        editor = EditorItem(lesson: lesson, isNew: true)
    }

    @ViewBuilder
    private func contextMenu(for lesson: Lesson) -> some View {
        Button { editor = EditorItem(lesson: lesson, isNew: false) } label: {
            Label("Edit", systemImage: "pencil")
        }
        Button { store.duplicate(lesson) } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Menu {
            ForEach(LessonStatus.allCases) { s in
                Button {
                    store.setStatus(s, for: lesson.id)
                } label: {
                    if s == lesson.status {
                        Label(store.t.status(s), systemImage: "checkmark")
                    } else {
                        Text(store.t.status(s))
                    }
                }
            }
        } label: {
            Label("Status", systemImage: "circle.lefthalf.filled")
        }
        Button(role: .destructive) { store.delete(lessonID: lesson.id) } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: Bar items

    private var titleMenu: some View {
        Menu {
            Button {} label: {
                Label(store.data.profile.timetableName, systemImage: "checkmark")
            }
            Divider()
            Button { showStudio = true } label: {
                Label("Studio settings", systemImage: "gearshape")
            }
        } label: {
            HStack(spacing: 7) {
                Text(store.data.profile.timetableName)
                    .font(.system(size: 18))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.textTitle)
            .padding(.horizontal, 70)
            .contentShape(Rectangle())
        }
    }

    private var moreMenu: some View {
        Menu {
            Section {
                Button { goToday() } label: { Label(store.t.today, systemImage: "calendar") }
                if mode == .week {
                    Button { openDay(focusDay) } label: { Label("Day view", systemImage: "rectangle") }
                } else {
                    Button { openWeek() } label: { Label("Week view", systemImage: "rectangle.split.3x1") }
                }
            }
            Section("Edit timetable") {
                Button { newLesson(day: focusDay) } label: { Label("Add period", systemImage: "plus") }
                Button { newLesson(day: focusDay, status: .exam) } label: { Label("Add exam", systemImage: "graduationcap") }
                Button { newLesson(day: focusDay, status: .substitution) } label: { Label("Add substitution", systemImage: "arrow.left.arrow.right") }
                Button {
                    holidayEditor = Holiday(name: "Ferien", start: focusDay, end: focusDay)
                } label: { Label("Add holiday", systemImage: "sun.max") }
            }
            Section("Week \(currentMonday.isoWeek)") {
                Menu {
                    ForEach([1, 2, 4, 8, 12, 20, 40], id: \.self) { n in
                        let title: String = n == 1 ? "Next week" : "Next \(n) weeks"
                        Button(title) {
                            store.copyWeek(from: currentMonday, weeks: n, replace: true)
                        }
                    }
                } label: {
                    Label("Copy this week to…", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) { confirmClear = true } label: {
                    Label("Clear this week", systemImage: "trash")
                }
            }
            Section {
                Button { showStudio = true } label: { Label("Studio settings", systemImage: "gearshape") }
            }
        } label: {
            MoreCircleLabel()
        }
    }
}

/// Orange position marker under the title bar in day view.
struct DayIndicator: View {
    var index: Int
    var count: Int
    var width: CGFloat

    var body: some View {
        let segment = width / CGFloat(max(count, 1))
        ZStack(alignment: .leading) {
            Rectangle().fill(Theme.gridLine)
            Rectangle()
                .fill(Theme.accent)
                .frame(width: segment)
                .offset(x: segment * CGFloat(min(max(index, 0), count - 1)))
        }
        .frame(width: width, height: 4)
        .animation(.easeInOut(duration: 0.2), value: index)
    }
}
