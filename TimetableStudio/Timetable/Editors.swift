import SwiftUI

// Editing UI. These screens are only for preparing a mockup, so they use
// standard iOS forms rather than the timetable look.

private func dayBinding(_ day: Binding<DayKey>) -> Binding<Date> {
    Binding(get: { day.wrappedValue.date }, set: { day.wrappedValue = DayKey($0) })
}

private func minuteBinding(_ minute: Binding<Int>) -> Binding<Date> {
    Binding(get: { TimeFmt.date(fromMinute: minute.wrappedValue) },
            set: { minute.wrappedValue = TimeFmt.minuteOfDay($0) })
}

struct LessonEditor: View {
    @EnvironmentObject private var store: MockStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Lesson
    @State private var useColor: Bool
    @State private var color: Color
    @State private var repeatWeeks = 0
    @State private var confirmDelete = false
    private let isNew: Bool

    init(lesson: Lesson, isNew: Bool) {
        _draft = State(initialValue: lesson)
        _useColor = State(initialValue: lesson.colorHex != nil)
        _color = State(initialValue: lesson.colorHex.flatMap { Color(hexString: $0) } ?? Color(hex: 0x627280))
        self.isNew = isNew
    }

    private struct KnownTeacher: Hashable { var code: String; var name: String }

    private var knownTeachers: [KnownTeacher] {
        var seen = Set<String>()
        var out: [KnownTeacher] = []
        for l in store.data.lessons where !l.teacher.isEmpty {
            if seen.insert(l.teacher).inserted { out.append(KnownTeacher(code: l.teacher, name: l.teacherName)) }
        }
        return out.sorted { $0.code < $1.code }
    }

    private var repeatLabel: String {
        if repeatWeeks == 0 { return "Only this week" }
        return repeatWeeks == 1 ? "Also next week" : "Also next \(repeatWeeks) weeks"
    }

    private var knownSubjects: [String] {
        Array(Set(store.data.lessons.map(\.subject).filter { !$0.isEmpty })).sorted()
    }

    var body: some View {
        let t = store.t
        let periods = store.sortedPeriods
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Day", selection: dayBinding($draft.day), displayedComponents: .date)
                    Picker("Start", selection: $draft.start) {
                        ForEach(Array(periods.enumerated()), id: \.element.id) { i, p in
                            Text("\(i + 1). period  \(TimeFmt.hhmm(p.start))").tag(p.start)
                        }
                        if !periods.contains(where: { $0.start == draft.start }) {
                            Text(TimeFmt.hhmm(draft.start)).tag(draft.start)
                        }
                    }
                    Picker("End", selection: $draft.end) {
                        ForEach(Array(periods.enumerated()), id: \.element.id) { i, p in
                            if p.end > draft.start {
                                Text("\(i + 1). period  \(TimeFmt.hhmm(p.end))").tag(p.end)
                            }
                        }
                        if !periods.contains(where: { $0.end == draft.end }) {
                            Text(TimeFmt.hhmm(draft.end)).tag(draft.end)
                        }
                    }
                    DisclosureGroup("Exact times") {
                        DatePicker("From", selection: minuteBinding($draft.start), displayedComponents: .hourAndMinute)
                        DatePicker("To", selection: minuteBinding($draft.end), displayedComponents: .hourAndMinute)
                    }
                }

                Section {
                    Picker("Type", selection: $draft.status) {
                        ForEach(LessonStatus.allCases) { s in
                            Text(t.status(s)).tag(s)
                        }
                    }
                } header: {
                    Text("Type")
                } footer: {
                    Text("Cancelled = red frame + crossed out. Substitution = changed teacher/room/subject shown next to the original. Exam = shown under My events.")
                }

                Section("Period") {
                    HStack {
                        TextField("Teacher code (e.g. MUEL)", text: $draft.teacher)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        if !knownTeachers.isEmpty {
                            Menu {
                                ForEach(knownTeachers, id: \.self) { k in
                                    Button("\(k.code)  \(k.name)") {
                                        draft.teacher = k.code
                                        draft.teacherName = k.name
                                    }
                                }
                            } label: { Image(systemName: "person.crop.circle.badge.plus") }
                        }
                    }
                    TextField("Teacher full name", text: $draft.teacherName)
                        .autocorrectionDisabled()
                    HStack {
                        TextField("Subject (e.g. M_GK_1)", text: $draft.subject)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if !knownSubjects.isEmpty {
                            Menu {
                                ForEach(knownSubjects, id: \.self) { s in
                                    Button(s) { draft.subject = s }
                                }
                            } label: { Image(systemName: "text.badge.plus") }
                        }
                    }
                    TextField("Room (e.g. A128)", text: $draft.room)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                    TextField("Lesson text (4th line)", text: $draft.text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Class (empty = \(store.data.profile.className))", text: $draft.className)
                        .autocorrectionDisabled()
                    TextField("Lesson info (shows ⓘ badge)", text: $draft.info, axis: .vertical)
                }

                if draft.status == .substitution {
                    Section {
                        TextField("Original teacher code", text: $draft.originalTeacher)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        TextField("Original teacher name", text: $draft.originalTeacherName)
                            .autocorrectionDisabled()
                        TextField("Original subject", text: $draft.originalSubject)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        TextField("Original room", text: $draft.originalRoom)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        TextField("Substitution text", text: $draft.note, axis: .vertical)
                    } header: {
                        Text("Substitution")
                    } footer: {
                        Text("Fields that differ from the values above are shown crossed out next to the new value.")
                    }
                }

                if draft.status == .exam {
                    Section("Exam") {
                        TextField("Exam name (e.g. Klausur Analysis)", text: $draft.examName)
                        TextField("Note", text: $draft.note, axis: .vertical)
                    }
                }

                if draft.status == .cancelled || draft.status == .additional || draft.status == .event {
                    Section("Note") {
                        TextField("Reason / text", text: $draft.note, axis: .vertical)
                    }
                }

                Section("Look") {
                    Toggle("Custom card colour", isOn: $useColor)
                    if useColor {
                        ColorPicker("Colour", selection: $color, supportsOpacity: false)
                    }
                }

                if isNew {
                    Section {
                        Stepper(repeatLabel, value: $repeatWeeks, in: 0...40)
                    } header: {
                        Text("Repeat")
                    }
                } else {
                    Section {
                        Button("Delete period", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(isNew ? "New period" : "Edit period")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(draft.end <= draft.start)
                }
            }
            .onChange(of: draft.status) { _, newValue in
                if newValue == .substitution && draft.originalTeacher.isEmpty && draft.originalRoom.isEmpty {
                    draft.originalTeacher = draft.teacher
                    draft.originalTeacherName = draft.teacherName
                    draft.originalRoom = draft.room
                    draft.originalSubject = draft.subject
                }
            }
            .onChange(of: draft.start) { _, newValue in
                if draft.end <= newValue {
                    draft.end = periods.first(where: { $0.start == newValue })?.end ?? newValue + 45
                }
            }
            .confirmationDialog("Delete this period?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    store.delete(lessonID: draft.id)
                    dismiss()
                }
            }
        }
    }

    private func save() {
        var lesson = draft
        lesson.colorHex = useColor ? color.hexString : nil
        store.upsert(lesson)
        if isNew && repeatWeeks > 0 {
            for w in 1...repeatWeeks {
                store.duplicate(lesson, toDay: lesson.day.adding(days: 7 * w))
            }
        }
        dismiss()
    }
}

struct HolidayEditor: View {
    @EnvironmentObject private var store: MockStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Holiday

    init(holiday: Holiday) {
        _draft = State(initialValue: holiday)
    }

    var body: some View {
        let exists = store.data.holidays.contains { $0.id == draft.id }
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Ferien13)", text: $draft.name)
                    DatePicker("From", selection: dayBinding($draft.start), displayedComponents: .date)
                    DatePicker("To", selection: dayBinding($draft.end), in: draft.start.date..., displayedComponents: .date)
                } footer: {
                    Text("Holiday days are drawn as a blue column and hide any periods on those days.")
                }
                if exists {
                    Section {
                        Button("Delete holiday", role: .destructive) {
                            store.data.holidays.removeAll { $0.id == draft.id }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(exists ? "Edit holiday" : "New holiday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if draft.end < draft.start { draft.end = draft.start }
                        if let i = store.data.holidays.firstIndex(where: { $0.id == draft.id }) {
                            store.data.holidays[i] = draft
                        } else {
                            store.data.holidays.append(draft)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AbsenceEditor: View {
    @EnvironmentObject private var store: MockStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Absence

    init(absence: Absence) {
        _draft = State(initialValue: absence)
    }

    var body: some View {
        let t = store.t
        let exists = store.data.absences.contains { $0.id == draft.id }
        NavigationStack {
            Form {
                Section {
                    DatePicker("From", selection: dayBinding($draft.start), displayedComponents: .date)
                    DatePicker("To", selection: dayBinding($draft.end), in: draft.start.date..., displayedComponents: .date)
                    DatePicker("Start time", selection: minuteBinding($draft.startMinute), displayedComponents: .hourAndMinute)
                    DatePicker("End time", selection: minuteBinding($draft.endMinute), displayedComponents: .hourAndMinute)
                }
                Section {
                    TextField("Reason", text: $draft.reason)
                    Picker("Status", selection: $draft.state) {
                        ForEach(AbsenceState.allCases) { s in Text(t.absenceState(s)).tag(s) }
                    }
                    TextField("Note", text: $draft.note, axis: .vertical)
                }
                if exists {
                    Section {
                        Button("Delete absence", role: .destructive) {
                            store.data.absences.removeAll { $0.id == draft.id }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(exists ? "Edit absence" : "New absence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if draft.end < draft.start { draft.end = draft.start }
                        if let i = store.data.absences.firstIndex(where: { $0.id == draft.id }) {
                            store.data.absences[i] = draft
                        } else {
                            store.data.absences.append(draft)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
