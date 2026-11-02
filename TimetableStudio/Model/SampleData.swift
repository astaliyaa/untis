import Foundation

/// Fictional demo content. Everything here can be edited or wiped in the app.
enum SampleData {
    static func m(_ h: Int, _ min: Int) -> Int { h * 60 + min }

    static func defaultPeriods() -> [Period] {
        [
            (m(8, 0), m(8, 45)), (m(8, 45), m(9, 30)),
            (m(9, 45), m(10, 30)), (m(10, 30), m(11, 15)),
            (m(11, 30), m(12, 15)), (m(12, 15), m(13, 0)),
            (m(13, 0), m(13, 45)), (m(13, 45), m(14, 30)),
            (m(14, 30), m(15, 15)), (m(15, 15), m(16, 0)),
            (m(16, 0), m(16, 45)), (m(17, 0), m(17, 45)),
            (m(17, 45), m(18, 30))
        ].map { Period(start: $0.0, end: $0.1) }
    }

    struct Teacher { let code: String; let name: String }
    static let muel = Teacher(code: "MUEL", name: "Müller Anna")
    static let brau = Teacher(code: "BRAU", name: "Braun Felix")
    static let kell = Teacher(code: "KELL", name: "Keller Jana")
    static let schu = Teacher(code: "SCHU", name: "Schulz Tim")
    static let weis = Teacher(code: "WEIS", name: "Weiß Lena")
    static let fran = Teacher(code: "FRAN", name: "Franke Paul")
    static let lang = Teacher(code: "LANG", name: "Lange Mia")
    static let wolf = Teacher(code: "WOLF", name: "Wolf Erik")
    static let hoff = Teacher(code: "HOFF", name: "Hoffmann Sara")
    static let graf = Teacher(code: "GRAF", name: "Graf Nils")
    static let zimm = Teacher(code: "ZIMM", name: "Zimmer Lea")

    static func make() -> MockData {
        var d = MockData()
        let monday = DayKey.today.mondayOfWeek
        d.periods = defaultPeriods()
        d.lessons = week(monday, variant: 0) + week(monday.adding(days: 7), variant: 1) + week(monday.adding(days: 14), variant: 2)
        d.holidays = [Holiday(name: "Ferien13", start: monday.adding(days: 5), end: monday.adding(days: 6))]
        d.messages = messages(monday)
        d.absences = [
            Absence(start: monday.adding(days: -12), end: monday.adding(days: -12),
                    startMinute: m(8, 0), endMinute: m(13, 0), reason: "Krankheit", state: .excused),
            Absence(start: monday.adding(days: -30), end: monday.adding(days: -29),
                    startMinute: m(8, 0), endMinute: m(16, 45), reason: "Arzttermin", state: .excused)
        ]
        return d
    }

    private static func L(_ day: DayKey, _ s: Int, _ e: Int, _ t: Teacher, _ subject: String,
                          _ room: String, _ text: String, info: String = "",
                          status: LessonStatus = .regular) -> Lesson {
        Lesson(day: day, start: s, end: e, teacher: t.code, teacherName: t.name,
               subject: subject, room: room, text: text, info: info, status: status)
    }

    /// variant 0 mirrors the reference layout, 1 shows substitutions/exams, 2 is plain.
    static func week(_ mo: DayKey, variant: Int) -> [Lesson] {
        let tu = mo.adding(days: 1), we = mo.adding(days: 2), th = mo.adding(days: 3), fr = mo.adding(days: 4)
        var l: [Lesson] = [
            // Monday
            L(mo, m(8, 0), m(9, 30), muel, "E_LK_2", "A128", "E_LK_2_BG12A_1"),
            L(mo, m(9, 45), m(11, 15), brau, "Ch_GK_1", "B127", "Ch_GK_1_BG12A_1"),
            L(mo, m(11, 30), m(12, 15), muel, "F_GK_1", "", "F_GK_1_BG12A"),
            L(mo, m(13, 0), m(13, 45), fran, "D_GK_3", "A131", "D_GK_3_BG12A_1",
              status: variant == 0 ? .cancelled : .regular),
            L(mo, m(15, 15), m(16, 45), hoff, "BK_GK_2", "", "BK_GK_2_BG12A_2"),
            // Tuesday
            L(tu, m(8, 0), m(9, 30), muel, "F_GK_1", "", "F_GK_1_BG12A_1"),
            L(tu, m(9, 45), m(11, 15), schu, "FtGt_LK_1", "B112", "FtGt_LK_1_BG12A_1",
              info: "Bitte Laptop mitbringen."),
            L(tu, m(11, 30), m(12, 15), schu, "FtGt_LK_1", "B112", "FtGt_LK_1_BG12A_1"),
            L(tu, m(12, 15), m(13, 0), kell, "M_GK_1", "A236", "M_GK_1_BG12A_1"),
            // Wednesday
            L(we, m(8, 0), m(9, 30), kell, "M_GK_1", "A236", "M_GK_1_BG12A_1",
              info: "Taschenrechner nicht vergessen."),
            L(we, m(9, 45), m(11, 15), weis, "Inf_LK_1", "A234", "Inf_LK_1_BG12A_1",
              info: "Projektarbeit"),
            L(we, m(11, 30), m(13, 0), wolf, "Eth_GK_1", "B208", "RelRk_BG12A",
              info: "Kursraum geändert"),
            L(we, m(13, 45), m(15, 15), graf, "GemK_GK_1", "A304", "GemK_GK_1_BG12A",
              status: variant == 0 ? .cancelled : .regular),
            // Thursday
            L(th, m(9, 45), m(11, 15), fran, "D_GK_3", "B208", "D_GK_3_BG12A_1"),
            L(th, m(11, 30), m(13, 0), muel, "E_LK_2", "A128", "E_LK_2_BG12A_1"),
            L(th, m(13, 45), m(14, 30), muel, "E_LK_2", "A128", "E_LK_2_BG12A_1"),
            L(th, m(14, 30), m(16, 0), zimm, "Sp_GK_1", "Halle-1", "Sp_GK_1_BG12A_1"),
            // Friday
            L(fr, m(8, 0), m(8, 45), lang, "FtGt_LK_1", "B206", "FtGt_LK_1_BG12A_1"),
            L(fr, m(8, 45), m(10, 30), lang, "FtGt_LK_1", "B206", "FtGt_LK_1_BG12A_1",
              info: "Praxisphase"),
            L(fr, m(10, 30), m(12, 15), weis, "Inf_LK_1", "A234", "Inf_LK_1_BG12A_1"),
            L(fr, m(12, 15), m(13, 0), weis, "Inf_LK_1", "A234", "Inf_LK_1_BG12A_1")
        ]

        if variant == 1 {
            // Substitution: Tuesday first block is taught by someone else in another room.
            if let i = l.firstIndex(where: { $0.day == tu && $0.start == m(8, 0) }) {
                l[i].status = .substitution
                l[i].originalTeacher = muel.code
                l[i].originalTeacherName = muel.name
                l[i].teacher = brau.code
                l[i].teacherName = brau.name
                l[i].originalRoom = ""
                l[i].room = "B105"
                l[i].note = "Vertretung"
            }
            // Exam on Wednesday.
            if let i = l.firstIndex(where: { $0.day == we && $0.start == m(8, 0) }) {
                l[i].status = .exam
                l[i].examName = "Klausur Analysis"
            }
            // Cancellation on Thursday afternoon.
            if let i = l.firstIndex(where: { $0.day == th && $0.start == m(14, 30) }) {
                l[i].status = .cancelled
                l[i].note = "Lehrkraft erkrankt"
            }
            // Additional period on Friday.
            l.append(Lesson(day: fr, start: m(13, 45), end: m(14, 30), teacher: kell.code,
                            teacherName: kell.name, subject: "M_GK_1", room: "A236",
                            text: "Förderstunde", status: .additional))
        }
        return l
    }

    static func messages(_ monday: DayKey) -> [Message] {
        [
            Message(folder: .inbox, senderName: kell.name, senderCode: kell.code,
                    subject: "Termin nächste Leistungsüberprüfung",
                    body: "",
                    date: monday.adding(days: -12).date(atMinute: m(14, 12))),
            Message(folder: .inbox, senderName: kell.name, senderCode: kell.code,
                    subject: "Für den LK Mathe 12. Klasse",
                    body: "Termin angekündigte Leistungsüberprüfung: Bitte bereitet die Kapitel 3 und 4 vor. Hilfsmittel: Taschenrechner und Formelsammlung.",
                    date: monday.adding(days: -66).date(atMinute: m(9, 40)))
        ]
    }
}
