import SwiftUI

/// "My events": exams and events taken from the timetable.
struct EventsView: View {
    @EnvironmentObject private var store: MockStore
    @State private var selected: Lesson?

    var body: some View {
        let t = store.t
        let items = store.data.lessons
            .filter { $0.status == .exam || $0.status == .event }
            .sorted { ($0.day, $0.start) < ($1.day, $1.start) }

        PlainPage(title: t.myEvents) {
            if items.isEmpty {
                EmptyHint(text: t.noEvents)
            } else {
                CardContainer {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, lesson in
                        Button { selected = lesson } label: {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(CardPalette.statusColor(lesson.status))
                                    .frame(width: 4, height: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lesson.examName.isEmpty ? (lesson.subject.isEmpty ? t.status(lesson.status) : lesson.subject) : lesson.examName)
                                        .font(.system(size: 17))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(t.day3(lesson.day)) | \(t.shortDate(lesson.day))  \(TimeFmt.hmm(lesson.start)) - \(TimeFmt.hmm(lesson.end))")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .lineLimit(1)
                                Spacer()
                                Text(lesson.subject)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.icon)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottom) {
                                if index < items.count - 1 {
                                    Rectangle().fill(Theme.listSeparator).frame(height: 1.0 / 3.0).padding(.leading, 34)
                                }
                            }
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
        .sheet(item: $selected) { lesson in
            LessonDetailSheet(lessonID: lesson.id)
                .environmentObject(store)
        }
    }
}

struct AbsencesView: View {
    @EnvironmentObject private var store: MockStore
    @State private var editing: Absence?

    var body: some View {
        let t = store.t
        let items = store.data.absences.sorted { $0.start > $1.start }
        PlainPage(title: t.myAbsences) {
            if items.isEmpty {
                EmptyHint(text: t.noAbsences)
            } else {
                CardContainer {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, a in
                        Button { editing = a } label: {
                            HStack(spacing: 14) {
                                AbsenceIcon()
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(absenceTitle(a, t))
                                        .font(.system(size: 17))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(TimeFmt.hhmm(a.startMinute)) - \(TimeFmt.hhmm(a.endMinute))\(a.reason.isEmpty ? "" : "  ·  \(a.reason)")")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .lineLimit(1)
                                Spacer()
                                Text(t.absenceState(a.state))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Theme.onBadge)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(a.state == .unexcused ? Color(hex: 0xDD4466) : Theme.icon,
                                                in: RoundedRectangle(cornerRadius: 6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                            .overlay(alignment: .bottom) {
                                if index < items.count - 1 {
                                    Rectangle().fill(Theme.listSeparator).frame(height: 1.0 / 3.0).padding(.leading, 56)
                                }
                            }
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = Absence(start: store.today, end: store.today)
                } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { a in
            AbsenceEditor(absence: a)
                .environmentObject(store)
        }
    }
}

private func absenceTitle(_ a: Absence, _ t: L10n) -> String {
    if a.start == a.end { return "\(t.day3(a.start)) | \(t.shortDate(a.start))" }
    return "\(t.shortDate(a.start)) - \(t.shortDate(a.end))"
}

struct ExtraItemView: View {
    @EnvironmentObject private var store: MockStore
    var body: some View {
        PlainPage(title: store.data.profile.extraItemTitle) {
            Text(store.data.profile.extraItemBody)
                .font(.system(size: 17))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 20)
        }
    }
}
