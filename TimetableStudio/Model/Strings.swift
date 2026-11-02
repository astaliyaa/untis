import Foundation

/// UI strings in English (as in the reference screenshots) and German.
struct L10n {
    let lang: AppLanguage
    private var de: Bool { lang == .de }

    // Tabs
    var home: String { de ? "Start" : "Home" }
    var timetable: String { de ? "Stundenplan" : "Timetable" }
    var messages: String { de ? "Nachrichten" : "Messages" }
    var profile: String { de ? "Profil" : "Profile" }

    // Home
    var today: String { de ? "Heute" : "Today" }
    var tomorrow: String { de ? "Morgen" : "Tomorrow" }
    var myTimetable: String { de ? "Mein Stundenplan" : "My timetable" }
    func morePeriods(_ n: Int) -> String {
        de ? "+\(n) \(n == 1 ? "Stunde" : "Stunden")" : "+\(n) \(n == 1 ? "period" : "periods")"
    }
    var noLessons: String { de ? "Keine Stunden" : "No periods" }
    var myEvents: String { de ? "Meine Termine" : "My events" }
    var myAbsences: String { de ? "Meine Abwesenheiten" : "My Absences" }
    var noEvents: String { de ? "Keine Termine" : "No events" }
    var noAbsences: String { de ? "Keine Abwesenheiten" : "No absences" }
    var exam: String { de ? "Prüfung" : "Exam" }

    // Timetable
    var weekPrefix: String { de ? "KW" : "W" }
    var holiday: String { de ? "Ferien" : "Holiday" }
    var to: String { de ? "bis" : "to" }
    var homework: String { de ? "Hausaufgaben" : "Homework" }
    var lessonInfo: String { de ? "Stundeninfo" : "Lesson info" }
    var insteadOf: String { de ? "statt" : "instead of" }

    func status(_ s: LessonStatus) -> String {
        switch s {
        case .regular: return de ? "Regulär" : "Regular"
        case .cancelled: return de ? "Entfall" : "Cancelled"
        case .substitution: return de ? "Vertretung" : "Substitution"
        case .exam: return de ? "Prüfung" : "Exam"
        case .additional: return de ? "Zusatzstunde" : "Additional period"
        case .event: return de ? "Veranstaltung" : "Event"
        }
    }

    // Messages
    var inbox: String { de ? "Posteingang" : "Inbox" }
    var sent: String { de ? "Gesendet" : "Sent" }
    var drafts: String { de ? "Entwürfe" : "Drafts" }
    var search: String { de ? "Suchen" : "Search" }
    var noMessages: String { de ? "Keine Nachrichten" : "No messages" }
    func folder(_ f: MessageFolder) -> String {
        switch f {
        case .inbox: return inbox
        case .sent: return sent
        case .drafts: return drafts
        }
    }

    // Profile
    var contactDetails: String { de ? "Kontaktdaten" : "Contact details" }
    var changePassword: String { de ? "Passwort ändern" : "Change password" }
    var whatsNew: String { de ? "Was ist neu" : "What's new" }
    var rateApp: String { de ? "App bewerten" : "Rate app" }
    var about: String { de ? "Über" : "About" }
    var logOut: String { de ? "Abmelden" : "Log out" }

    func absenceState(_ s: AbsenceState) -> String {
        switch s {
        case .excused: return de ? "Entschuldigt" : "Excused"
        case .unexcused: return de ? "Unentschuldigt" : "Not excused"
        case .open: return de ? "Offen" : "Open"
        }
    }

    // MARK: Dates (fixed spellings so screenshots match regardless of device locale)

    private static let enDayShort = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    private static let deDayShort = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private static let enDay3 = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private static let deDay3 = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
    private static let enDayLong = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    private static let deDayLong = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
    private static let enMonth = ["January", "February", "March", "April", "May", "June", "July",
                                  "August", "September", "October", "November", "December"]
    private static let deMonth = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli",
                                  "August", "September", "Oktober", "November", "Dezember"]
    private static let enMonthShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    private static let deMonthShort = ["Jan.", "Feb.", "März", "Apr.", "Mai", "Juni", "Juli", "Aug.", "Sep.", "Okt.", "Nov.", "Dez."]

    func dayShort(_ d: DayKey) -> String { (de ? Self.deDayShort : Self.enDayShort)[d.weekdayIndex - 1] }
    func day3(_ d: DayKey) -> String { (de ? Self.deDay3 : Self.enDay3)[d.weekdayIndex - 1] }
    func dayLong(_ d: DayKey) -> String { (de ? Self.deDayLong : Self.enDayLong)[d.weekdayIndex - 1] }
    func month(_ d: DayKey) -> String { (de ? Self.deMonth : Self.enMonth)[d.month - 1] }
    func monthShort(_ d: DayKey) -> String { (de ? Self.deMonthShort : Self.enMonthShort)[d.month - 1] }

    /// "21. Oct"
    func messageDate(_ date: Date, now: Date) -> String {
        let d = DayKey(date)
        if d == DayKey(now) { return TimeFmt.hhmm(TimeFmt.minuteOfDay(date)) }
        if d.year != DayKey(now).year {
            return String(format: "%02d.%02d.%02d", d.day, d.month, d.year % 100)
        }
        return "\(d.day). \(monthShort(d))"
    }

    /// "03.11.26"
    func shortDate(_ d: DayKey) -> String {
        String(format: "%02d.%02d.%02d", d.day, d.month, d.year % 100)
    }

    /// "07/11"
    func holidayDate(_ d: DayKey) -> String {
        de ? String(format: "%02d.%02d.", d.day, d.month) : String(format: "%02d/%02d", d.day, d.month)
    }

    /// Weekday name relative to today: "Today", "Tomorrow" or "Wednesday".
    func relativeDay(_ d: DayKey, today: DayKey) -> String {
        let diff = today.days(to: d)
        if diff == 0 { return self.today }
        if diff == 1 { return tomorrow }
        return dayLong(d)
    }
}
