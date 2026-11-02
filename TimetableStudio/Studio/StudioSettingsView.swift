import SwiftUI

/// Hidden control panel for the mockup (open via the ⋮ menu on the timetable,
/// a long press on the school name, or a tap on the account card in Profile).
struct StudioSettingsView: View {
    @EnvironmentObject private var store: MockStore
    @Environment(\.dismiss) private var dismiss
    @State private var holidayEditor: Holiday?
    @State private var absenceEditor: Absence?
    @State private var confirmReset = false
    @State private var confirmWipe = false
    @State private var importText = ""
    @State private var importResult: String?

    var body: some View {
        let t = store.t
        NavigationStack {
            Form {
                Section {
                    TextField("School name", text: $store.data.profile.schoolName)
                    TextField("Full name (Profile title)", text: $store.data.profile.fullName)
                    TextField("Username", text: $store.data.profile.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Role badge", text: $store.data.profile.role)
                    TextField("Timetable name (title bar)", text: $store.data.profile.timetableName)
                        .autocorrectionDisabled()
                    TextField("Class (lesson sheet)", text: $store.data.profile.className)
                        .autocorrectionDisabled()
                    TextField("E-mail", text: $store.data.profile.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $store.data.profile.phone)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Profile")
                }

                Section("Extra Home item") {
                    Toggle("Show", isOn: $store.data.profile.showExtraItem)
                    TextField("Title", text: $store.data.profile.extraItemTitle)
                    TextField("Page text", text: $store.data.profile.extraItemBody, axis: .vertical)
                }

                Section {
                    Picker("Language", selection: $store.data.settings.language) {
                        ForEach(AppLanguage.allCases) { l in Text(l.label).tag(l) }
                    }
                } header: {
                    Text("Language")
                }

                Section {
                    Toggle("Use custom date & time", isOn: $store.data.settings.useFakeNow)
                    if store.data.settings.useFakeNow {
                        DatePicker("Now", selection: $store.data.settings.fakeNow)
                    }
                } header: {
                    Text("Clock")
                } footer: {
                    Text("Controls which day is highlighted as today, which periods look past (dimmed) and what the Home card shows. The status bar clock is the real one.")
                }

                Section("Timetable") {
                    Picker("Days in week view", selection: $store.data.settings.weekDayCount) {
                        Text("Mon – Fri").tag(5)
                        Text("Mon – Sat").tag(6)
                        Text("Mon – Sun").tag(7)
                    }
                    Toggle("Dim past periods", isOn: $store.data.settings.dimPastLessons)
                    Toggle("Day position bar in day view", isOn: $store.data.settings.showDayIndicator)
                    Toggle("Open in day view", isOn: $store.data.settings.startInDayView)
                    NavigationLink("Time grid (\(store.data.periods.count) periods)") {
                        TimeGridEditor()
                    }
                }

                Section {
                    ForEach(store.data.holidays.sorted { $0.start < $1.start }) { h in
                        Button {
                            holidayEditor = h
                        } label: {
                            HStack {
                                Text(h.name).foregroundStyle(.primary)
                                Spacer()
                                Text("\(t.shortDate(h.start)) – \(t.shortDate(h.end))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button {
                        holidayEditor = Holiday(name: "Ferien", start: store.today, end: store.today.adding(days: 1))
                    } label: { Label("Add holiday", systemImage: "plus") }
                } header: {
                    Text("Holidays")
                }

                Section {
                    ForEach(store.data.absences.sorted { $0.start > $1.start }) { a in
                        Button { absenceEditor = a } label: {
                            HStack {
                                Text(a.reason.isEmpty ? "Absence" : a.reason).foregroundStyle(.primary)
                                Spacer()
                                Text(t.shortDate(a.start)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button {
                        absenceEditor = Absence(start: store.today, end: store.today)
                    } label: { Label("Add absence", systemImage: "plus") }
                } header: {
                    Text("Absences")
                }

                Section {
                    ShareLink(item: store.exportJSON(), preview: SharePreview("timetable-studio.json")) {
                        Label("Export data (JSON)", systemImage: "square.and.arrow.up")
                    }
                    TextField("Paste exported JSON here to import", text: $importText, axis: .vertical)
                        .lineLimit(1...4)
                        .font(.system(.footnote, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Import pasted JSON") {
                        importResult = store.importJSON(importText) ? "Imported." : "That JSON could not be read."
                        if importResult == "Imported." { importText = "" }
                    }
                    .disabled(importText.isEmpty)
                    if let importResult {
                        Text(importResult).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Backup")
                }

                Section {
                    Button("Load demo timetable") { confirmReset = true }
                    Button("Delete all periods", role: .destructive) { confirmWipe = true }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Tip: tap an empty slot in the timetable to add a period there, long-press a period to edit, duplicate, change its status or delete it.")
                }
            }
            .navigationTitle("Studio settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $holidayEditor) { h in
                HolidayEditor(holiday: h).environmentObject(store)
            }
            .sheet(item: $absenceEditor) { a in
                AbsenceEditor(absence: a).environmentObject(store)
            }
            .confirmationDialog("Replace everything with the demo timetable?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Load demo", role: .destructive) { store.resetToSample() }
            }
            .confirmationDialog("Delete every period?", isPresented: $confirmWipe, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) { store.data.lessons = [] }
            }
        }
    }
}

struct TimeGridEditor: View {
    @EnvironmentObject private var store: MockStore

    private func binding(_ minute: Binding<Int>) -> Binding<Date> {
        Binding(get: { TimeFmt.date(fromMinute: minute.wrappedValue) },
                set: { minute.wrappedValue = TimeFmt.minuteOfDay($0) })
    }

    var body: some View {
        Form {
            Section {
                ForEach($store.data.periods) { $period in
                    HStack {
                        DatePicker("", selection: binding($period.start), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Text("–")
                        DatePicker("", selection: binding($period.end), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        Spacer()
                        Text("\(period.end - period.start) min")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .onDelete { store.data.periods.remove(atOffsets: $0) }
                Button {
                    let last = store.sortedPeriods.last
                    let start = last?.end ?? 480
                    store.data.periods.append(Period(start: start, end: start + 45))
                } label: { Label("Add period", systemImage: "plus") }
            } footer: {
                Text("Every start and end time draws a line and a time label on the grid. Leave a gap between periods for a break.")
            }
            Section {
                Button("Sort by start time") {
                    store.data.periods.sort { $0.start < $1.start }
                }
                Button("Reset to default (08:00 – 18:30)") {
                    store.data.periods = SampleData.defaultPeriods()
                }
            }
        }
        .navigationTitle("Time grid")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }
}
