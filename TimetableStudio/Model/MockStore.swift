import Foundation
import SwiftUI

/// Single source of truth. Persists everything as JSON in Application Support.
final class MockStore: ObservableObject {
    @Published var data: MockData {
        didSet { save() }
    }

    private let url: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("timetable-studio.json")

        if let raw = try? Data(contentsOf: url),
           let decoded = try? MockStore.decoder.decode(MockData.self, from: raw) {
            data = decoded
        } else {
            data = SampleData.make()
        }
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func save() {
        guard let raw = try? MockStore.encoder.encode(data) else { return }
        try? raw.write(to: url, options: .atomic)
    }

    // MARK: Derived values

    var t: L10n { L10n(lang: data.settings.language) }

    /// The (possibly simulated) current moment.
    var now: Date { data.settings.useFakeNow ? data.settings.fakeNow : Date() }
    var today: DayKey { DayKey(now) }
    var nowMinute: Int { TimeFmt.minuteOfDay(now) }

    func isPast(_ lesson: Lesson) -> Bool {
        guard data.settings.dimPastLessons else { return false }
        let t = today
        if lesson.day < t { return true }
        if lesson.day > t { return false }
        return lesson.end <= nowMinute
    }

    func lessons(on day: DayKey) -> [Lesson] {
        data.lessons
            .filter { $0.day == day }
            .sorted { ($0.start, $0.end, $0.teacher) < ($1.start, $1.end, $1.teacher) }
    }

    func holiday(on day: DayKey) -> Holiday? {
        data.holidays.first { $0.contains(day) }
    }

    func lesson(id: UUID) -> Lesson? {
        data.lessons.first { $0.id == id }
    }

    /// Visible minute range of the grid (first period start … last end).
    var gridRange: (start: Int, end: Int) {
        let starts = data.periods.map(\.start)
        let ends = data.periods.map(\.end)
        let s = starts.min() ?? 480
        let e = ends.max() ?? 1110
        return (s, max(e, s + 60))
    }

    func gridRange(including lessons: [Lesson]) -> (start: Int, end: Int) {
        var r = gridRange
        for l in lessons {
            r.start = min(r.start, l.start)
            r.end = max(r.end, l.end)
        }
        return r
    }

    var sortedPeriods: [Period] { data.periods.sorted { $0.start < $1.start } }

    // MARK: Lesson editing

    func upsert(_ lesson: Lesson) {
        if let i = data.lessons.firstIndex(where: { $0.id == lesson.id }) {
            data.lessons[i] = lesson
        } else {
            data.lessons.append(lesson)
        }
    }

    func delete(lessonID: UUID) {
        data.lessons.removeAll { $0.id == lessonID }
    }

    @discardableResult
    func duplicate(_ lesson: Lesson, toDay day: DayKey? = nil) -> Lesson {
        var copy = lesson
        copy.id = UUID()
        copy.day = day ?? lesson.day
        copy.homework = lesson.homework.map { var h = $0; h.id = UUID(); return h }
        data.lessons.append(copy)
        return copy
    }

    func setStatus(_ status: LessonStatus, for id: UUID) {
        guard let i = data.lessons.firstIndex(where: { $0.id == id }) else { return }
        data.lessons[i].status = status
    }

    /// Copies all lessons from the week starting at `monday` into the following
    /// `weeks` weeks (statuses reset to regular). Existing lessons in the target
    /// weeks are replaced when `replace` is true.
    func copyWeek(from monday: DayKey, weeks: Int, replace: Bool) {
        let source = data.lessons.filter { $0.day >= monday && $0.day < monday.adding(days: 7) }
        guard weeks > 0 else { return }
        var lessons = data.lessons
        for w in 1...weeks {
            let targetMonday = monday.adding(days: 7 * w)
            if replace {
                lessons.removeAll { $0.day >= targetMonday && $0.day < targetMonday.adding(days: 7) }
            }
            for l in source {
                var c = l
                c.id = UUID()
                c.day = l.day.adding(days: 7 * w)
                c.status = .regular
                c.originalTeacher = ""
                c.originalTeacherName = ""
                c.originalRoom = ""
                c.originalSubject = ""
                c.note = ""
                c.examName = ""
                c.homework = []
                lessons.append(c)
            }
        }
        data.lessons = lessons
    }

    func clearWeek(_ monday: DayKey) {
        data.lessons.removeAll { $0.day >= monday && $0.day < monday.adding(days: 7) }
    }

    func resetToSample() {
        var fresh = SampleData.make()
        fresh.settings = data.settings
        fresh.settings.useFakeNow = false
        data = fresh
    }

    func exportJSON() -> String {
        guard let raw = try? MockStore.encoder.encode(data) else { return "{}" }
        return String(decoding: raw, as: UTF8.self)
    }

    func importJSON(_ text: String) -> Bool {
        guard let raw = text.data(using: .utf8),
              let decoded = try? MockStore.decoder.decode(MockData.self, from: raw) else { return false }
        data = decoded
        return true
    }

    // MARK: Home card helpers

    /// The day shown on the Home card: today if lessons are still ahead,
    /// otherwise the next day (within two weeks) that has lessons.
    func upcomingDay() -> (day: DayKey, lessons: [Lesson])? {
        let t = today
        let todays = lessons(on: t).filter { $0.end > nowMinute }
        if !todays.isEmpty && holiday(on: t) == nil {
            return (t, lessons(on: t).filter { $0.end > nowMinute })
        }
        for offset in 1...21 {
            let d = t.adding(days: offset)
            if holiday(on: d) != nil { continue }
            let ls = lessons(on: d)
            if !ls.isEmpty { return (d, ls) }
        }
        return nil
    }
}
