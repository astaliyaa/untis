import Foundation

// Every model decodes tolerantly (missing keys fall back to defaults) so that
// data saved by an older build keeps loading after an update.

extension KeyedDecodingContainer {
    func v<T: Decodable>(_ key: Key, _ fallback: @autoclosure () -> T) -> T {
        if let value = try? decodeIfPresent(T.self, forKey: key) {
            return value
        }
        return fallback()
    }
}

// MARK: - Lessons

enum LessonStatus: String, Codable, CaseIterable, Identifiable {
    case regular, cancelled, substitution, exam, additional, event
    var id: String { rawValue }
}

struct Homework: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String = ""
    var due: DayKey? = nil
    var done: Bool = false

    init(id: UUID = UUID(), text: String = "", due: DayKey? = nil, done: Bool = false) {
        self.id = id; self.text = text; self.due = due; self.done = done
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, UUID())
        text = c.v(.text, "")
        due = c.v(.due, nil)
        done = c.v(.done, false)
    }
}

struct Lesson: Identifiable, Codable, Hashable {
    var id = UUID()
    var day: DayKey
    var start: Int                 // minutes since midnight
    var end: Int
    var teacher: String = ""       // short code, e.g. "MUEL"
    var teacherName: String = ""   // full name shown in the detail sheet
    var subject: String = ""
    var room: String = ""
    var className: String = ""     // empty = use the profile's class
    var text: String = ""          // lesson text / group, e.g. "E_LK_2_BG12A_1"
    var info: String = ""          // non-empty shows the (i) badge
    var status: LessonStatus = .regular
    // Substitution / room change
    var originalTeacher: String = ""
    var originalTeacherName: String = ""
    var originalRoom: String = ""
    var originalSubject: String = ""
    var note: String = ""          // substitution text / cancellation reason
    // Exam
    var examName: String = ""
    var homework: [Homework] = []
    var colorHex: String? = nil

    init(id: UUID = UUID(), day: DayKey, start: Int, end: Int,
         teacher: String = "", teacherName: String = "", subject: String = "",
         room: String = "", className: String = "", text: String = "", info: String = "",
         status: LessonStatus = .regular, originalTeacher: String = "",
         originalTeacherName: String = "", originalRoom: String = "",
         originalSubject: String = "", note: String = "", examName: String = "",
         homework: [Homework] = [], colorHex: String? = nil) {
        self.id = id; self.day = day; self.start = start; self.end = end
        self.teacher = teacher; self.teacherName = teacherName; self.subject = subject
        self.room = room; self.className = className; self.text = text; self.info = info
        self.status = status; self.originalTeacher = originalTeacher
        self.originalTeacherName = originalTeacherName; self.originalRoom = originalRoom
        self.originalSubject = originalSubject; self.note = note; self.examName = examName
        self.homework = homework; self.colorHex = colorHex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, UUID())
        day = c.v(.day, DayKey.today)
        start = c.v(.start, 480)
        end = c.v(.end, 525)
        teacher = c.v(.teacher, "")
        teacherName = c.v(.teacherName, "")
        subject = c.v(.subject, "")
        room = c.v(.room, "")
        className = c.v(.className, "")
        text = c.v(.text, "")
        info = c.v(.info, "")
        status = c.v(.status, .regular)
        originalTeacher = c.v(.originalTeacher, "")
        originalTeacherName = c.v(.originalTeacherName, "")
        originalRoom = c.v(.originalRoom, "")
        originalSubject = c.v(.originalSubject, "")
        note = c.v(.note, "")
        examName = c.v(.examName, "")
        homework = c.v(.homework, [])
        colorHex = c.v(.colorHex, nil)
    }

    var teacherChanged: Bool { status == .substitution && !originalTeacher.isEmpty && originalTeacher != teacher }
    var roomChanged: Bool { status == .substitution && !originalRoom.isEmpty && originalRoom != room }
    var subjectChanged: Bool { status == .substitution && !originalSubject.isEmpty && originalSubject != subject }
}

// MARK: - Time grid

struct Period: Identifiable, Codable, Hashable {
    var id = UUID()
    var start: Int
    var end: Int

    init(id: UUID = UUID(), start: Int, end: Int) {
        self.id = id; self.start = start; self.end = end
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, UUID())
        start = c.v(.start, 480)
        end = c.v(.end, 525)
    }
}

// MARK: - Holidays

struct Holiday: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var start: DayKey
    var end: DayKey

    init(id: UUID = UUID(), name: String, start: DayKey, end: DayKey) {
        self.id = id; self.name = name; self.start = start; self.end = end
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, UUID())
        name = c.v(.name, "")
        start = c.v(.start, DayKey.today)
        end = c.v(.end, DayKey.today)
    }

    func contains(_ day: DayKey) -> Bool { day >= start && day <= end }
}

// MARK: - Messages

enum MessageFolder: String, Codable, CaseIterable, Identifiable {
    case inbox, sent, drafts
    var id: String { rawValue }
}

struct Message: Identifiable, Codable, Hashable {
    var id = UUID()
    var folder: MessageFolder = .inbox
    var senderName: String = ""     // "Keller Jana"
    var senderCode: String = ""     // "KELL"
    var recipients: String = ""
    var subject: String = ""
    var body: String = ""
    var date: Date = Date()
    var isRead: Bool = true

    init(id: UUID = UUID(), folder: MessageFolder = .inbox, senderName: String = "",
         senderCode: String = "", recipients: String = "", subject: String = "",
         body: String = "", date: Date = Date(), isRead: Bool = true) {
        self.id = id; self.folder = folder; self.senderName = senderName
        self.senderCode = senderCode; self.recipients = recipients; self.subject = subject
        self.body = body; self.date = date; self.isRead = isRead
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, UUID())
        folder = c.v(.folder, .inbox)
        senderName = c.v(.senderName, "")
        senderCode = c.v(.senderCode, "")
        recipients = c.v(.recipients, "")
        subject = c.v(.subject, "")
        body = c.v(.body, "")
        date = c.v(.date, Date())
        isRead = c.v(.isRead, true)
    }

    var displaySender: String {
        senderCode.isEmpty ? senderName : "\(senderName) (\(senderCode))"
    }

    var initials: String { Initials.from(senderName) }
}

// MARK: - Absences

enum AbsenceState: String, Codable, CaseIterable, Identifiable {
    case excused, unexcused, open
    var id: String { rawValue }
}

struct Absence: Identifiable, Codable, Hashable {
    var id = UUID()
    var start: DayKey
    var end: DayKey
    var startMinute: Int = 480
    var endMinute: Int = 780
    var reason: String = ""
    var state: AbsenceState = .excused
    var note: String = ""

    init(id: UUID = UUID(), start: DayKey, end: DayKey, startMinute: Int = 480,
         endMinute: Int = 780, reason: String = "", state: AbsenceState = .excused, note: String = "") {
        self.id = id; self.start = start; self.end = end; self.startMinute = startMinute
        self.endMinute = endMinute; self.reason = reason; self.state = state; self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.v(.id, UUID())
        start = c.v(.start, DayKey.today)
        end = c.v(.end, DayKey.today)
        startMinute = c.v(.startMinute, 480)
        endMinute = c.v(.endMinute, 780)
        reason = c.v(.reason, "")
        state = c.v(.state, .excused)
        note = c.v(.note, "")
    }
}

// MARK: - Profile & settings

struct Profile: Codable, Hashable {
    var schoolName: String = "BBSMusterstadt"
    var fullName: String = "Mustermann Max"
    var username: String = "mustermax_2026"
    var role: String = "Student"
    var timetableName: String = "MusMax09"
    var className: String = "BG 12 A"
    var email: String = "max.mustermann@example.com"
    var phone: String = ""
    var extraItemTitle: String = "Volljährigkeit"
    var extraItemBody: String = "Hier können volljährige Schülerinnen und Schüler ihre Volljährigkeit bestätigen."
    var showExtraItem: Bool = true

    init() {}

    init(from decoder: Decoder) throws {
        let d = Profile()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schoolName = c.v(.schoolName, d.schoolName)
        fullName = c.v(.fullName, d.fullName)
        username = c.v(.username, d.username)
        role = c.v(.role, d.role)
        timetableName = c.v(.timetableName, d.timetableName)
        className = c.v(.className, d.className)
        email = c.v(.email, d.email)
        phone = c.v(.phone, d.phone)
        extraItemTitle = c.v(.extraItemTitle, d.extraItemTitle)
        extraItemBody = c.v(.extraItemBody, d.extraItemBody)
        showExtraItem = c.v(.showExtraItem, d.showExtraItem)
    }

    var initials: String { Initials.from(fullName) }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case en, de
    var id: String { rawValue }
    var label: String { self == .en ? "English" : "Deutsch" }
}

struct StudioSettings: Codable, Hashable {
    var language: AppLanguage = .en
    var useFakeNow: Bool = false
    var fakeNow: Date = Date()
    var dimPastLessons: Bool = true
    var showDayIndicator: Bool = true
    var weekDayCount: Int = 6
    var startInDayView: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let d = StudioSettings()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        language = c.v(.language, d.language)
        useFakeNow = c.v(.useFakeNow, d.useFakeNow)
        fakeNow = c.v(.fakeNow, d.fakeNow)
        dimPastLessons = c.v(.dimPastLessons, d.dimPastLessons)
        showDayIndicator = c.v(.showDayIndicator, d.showDayIndicator)
        weekDayCount = c.v(.weekDayCount, d.weekDayCount)
        startInDayView = c.v(.startInDayView, d.startInDayView)
    }
}

struct MockData: Codable {
    var profile = Profile()
    var settings = StudioSettings()
    var periods: [Period] = SampleData.defaultPeriods()
    var lessons: [Lesson] = []
    var holidays: [Holiday] = []
    var messages: [Message] = []
    var absences: [Absence] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile = c.v(.profile, Profile())
        settings = c.v(.settings, StudioSettings())
        periods = c.v(.periods, SampleData.defaultPeriods())
        lessons = c.v(.lessons, [])
        holidays = c.v(.holidays, [])
        messages = c.v(.messages, [])
        absences = c.v(.absences, [])
    }
}

enum Initials {
    static func from(_ name: String) -> String {
        let parts = name
            .replacingOccurrences(of: "(", with: " ")
            .split(separator: " ")
            .filter { !$0.isEmpty }
        let letters = parts.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return letters.joined()
    }
}
