import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MockStore
    @Binding var showStudio: Bool
    var openTimetable: () -> Void

    var body: some View {
        let t = store.t
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LargeTitle(text: store.data.profile.schoolName)
                        .padding(.top, 57.3)
                        .onLongPressGesture(minimumDuration: 0.8) { showStudio = true }

                    Button(action: openTimetable) {
                        TodayCard()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)

                    CardContainer {
                        NavigationLink { EventsView() } label: {
                            CardRow(icon: .homework, title: t.myEvents, showSeparator: true)
                        }
                        .buttonStyle(PressableStyle())
                        NavigationLink { AbsencesView() } label: {
                            CardRow(icon: .absence, title: t.myAbsences)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.top, 32.3)

                    if store.data.profile.showExtraItem {
                        CardContainer {
                            NavigationLink { ExtraItemView() } label: {
                                CardRow(icon: .symbol("square.stack.3d.up"), title: store.data.profile.extraItemTitle)
                            }
                            .buttonStyle(PressableStyle())
                        }
                        .padding(.top, 32.3)
                    }

                    Spacer(minLength: 120)
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// "Monday 2 November | Tomorrow · My timetable" card.
struct TodayCard: View {
    @EnvironmentObject private var store: MockStore

    var body: some View {
        let t = store.t
        let today = store.today
        let upcoming = store.upcomingDay()

        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(t.dayLong(today))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textTitle)
                Text("\(today.day)")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.textWarm)
                Text(t.month(today))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textWarm)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.top, 1.3)
            .frame(width: 88, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(upcoming.map { t.relativeDay($0.day, today: today) } ?? t.today)
                    Rectangle()
                        .fill(Theme.separatorBar)
                        .frame(width: 2, height: 11)
                    Text(t.myTimetable)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textTitle)
                .lineLimit(1)

                if let upcoming {
                    let shown = Array(upcoming.lessons.prefix(2))
                    VStack(alignment: .leading, spacing: 8.3) {
                        ForEach(shown) { lesson in
                            HomeLessonRow(lesson: lesson)
                        }
                    }
                    .padding(.top, 2.7)

                    let more = upcoming.lessons.count - shown.count
                    if more > 0 {
                        HStack(spacing: 8) {
                            HStack(spacing: 3.7) {
                                ForEach(0..<min(more, 4), id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Theme.textTitle)
                                        .frame(width: 4, height: 9.7)
                                }
                            }
                            Text(t.morePeriods(more))
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.top, 5)
                    }
                } else {
                    Text(t.noLessons)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 21)
        }
        .padding(.leading, 22)
        .padding(.top, 13.8)
        .padding(.bottom, 11.4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCornerLarge, style: .continuous))
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct HomeLessonRow: View {
    var lesson: Lesson

    var body: some View {
        let cancelled = lesson.status == .cancelled
        let third = lesson.room.isEmpty ? lesson.text : lesson.room
        HStack(alignment: .top, spacing: 5.3) {
            RoundedRectangle(cornerRadius: 2)
                .fill(lesson.status == .regular ? Theme.textTitle : CardPalette.statusColor(lesson.status))
                .frame(width: 4)
                .padding(.vertical, 2)
            VStack(alignment: .leading, spacing: 0) {
                Text(lesson.teacher.isEmpty ? " " : lesson.teacher)
                    .font(.system(size: 12, weight: .bold))
                    .strikethrough(cancelled)
                Text(lesson.subject.isEmpty ? " " : lesson.subject)
                    .font(.system(size: 12))
                    .strikethrough(cancelled)
                Text(third.isEmpty ? " " : third)
                    .font(.system(size: 12))
                    .strikethrough(cancelled)
            }
            .foregroundStyle(Theme.textPrimary)
            .lineLimit(1)
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 0) {
                Text(TimeFmt.hhmm(lesson.start))
                Spacer(minLength: 0)
                Text(TimeFmt.hhmm(lesson.end))
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
