import Foundation

extension Calendar {
    /// Gregorian calendar, weeks start on Monday (ISO 8601 style).
    static let app: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        c.timeZone = .current
        return c
    }()
}

/// A calendar day without a time component. Stored as y/m/d so that saved
/// data never shifts when the device time zone changes.
struct DayKey: Hashable, Codable, Comparable, Identifiable {
    var year: Int
    var month: Int
    var day: Int

    var id: String { string }

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date) {
        let c = Calendar.app.dateComponents([.year, .month, .day], from: date)
        self.year = c.year ?? 2026
        self.month = c.month ?? 1
        self.day = c.day ?? 1
    }

    static var today: DayKey { DayKey(Date()) }

    var date: Date {
        Calendar.app.date(from: DateComponents(year: year, month: month, day: day, hour: 0)) ?? Date()
    }

    func date(atMinute minute: Int) -> Date {
        date.addingTimeInterval(TimeInterval(minute * 60))
    }

    func adding(days: Int) -> DayKey {
        DayKey(Calendar.app.date(byAdding: .day, value: days, to: date) ?? date)
    }

    /// 1 = Monday … 7 = Sunday
    var weekdayIndex: Int {
        let w = Calendar.app.component(.weekday, from: date) // 1 = Sunday
        return ((w + 5) % 7) + 1
    }

    var mondayOfWeek: DayKey { adding(days: -(weekdayIndex - 1)) }

    var isoWeek: Int {
        Calendar(identifier: .iso8601).component(.weekOfYear, from: date)
    }

    func days(to other: DayKey) -> Int {
        Calendar.app.dateComponents([.day], from: date, to: other.date).day ?? 0
    }

    var string: String { String(format: "%04d-%02d-%02d", year, month, day) }

    static func < (lhs: DayKey, rhs: DayKey) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

enum TimeFmt {
    /// "08:00"
    static func hhmm(_ minute: Int) -> String {
        String(format: "%02d:%02d", minute / 60, minute % 60)
    }

    /// "8:00"
    static func hmm(_ minute: Int) -> String {
        String(format: "%d:%02d", minute / 60, minute % 60)
    }

    static func minuteOfDay(_ date: Date) -> Int {
        let c = Calendar.app.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func date(fromMinute minute: Int) -> Date {
        DayKey.today.date(atMinute: minute)
    }
}
