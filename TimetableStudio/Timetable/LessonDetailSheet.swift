import SwiftUI

/// Bottom sheet shown when tapping a period ("Tue | 03.11.26 · 8:00 - 9:30").
struct LessonDetailSheet: View {
    @EnvironmentObject private var store: MockStore
    @Environment(\.dismiss) private var dismiss
    var lessonID: UUID

    @State private var editor: EditorItem?
    @State private var showHomework = false

    var body: some View {
        NavigationStack {
            Group {
                if let lesson = store.lesson(id: lessonID) {
                    content(lesson)
                } else {
                    Color.clear.onAppear { dismiss() }
                }
            }
            .background(Theme.sheet.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showHomework) {
                HomeworkListView(lessonID: lessonID)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.sheet)
        .sheet(item: $editor) { item in
            LessonEditor(lesson: item.lesson, isNew: item.isNew)
                .environmentObject(store)
        }
    }

    @ViewBuilder
    private func content(_ lesson: Lesson) -> some View {
        let t = store.t
        let className = lesson.className.isEmpty ? store.data.profile.className : lesson.className
        let cancelled = lesson.status == .cancelled

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header: close · date/time · more
                ZStack {
                    VStack(spacing: -2) {
                        HStack(spacing: 5) {
                            Text(t.day3(lesson.day))
                            Text("|").foregroundStyle(Theme.iconSheet)
                            Text(t.shortDate(lesson.day))
                        }
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textTitle)
                        Text("\(TimeFmt.hmm(lesson.start)) - \(TimeFmt.hmm(lesson.end))")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTitle)
                    }
                    HStack {
                        Button { dismiss() } label: {
                            CircleGlyph(systemName: "xmark", size: 19, weight: .regular)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Menu {
                            Button { editor = EditorItem(lesson: lesson, isNew: false) } label: {
                                Label("Edit period", systemImage: "pencil")
                            }
                            Button {
                                let copy = store.duplicate(lesson)
                                editor = EditorItem(lesson: copy, isNew: false)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            Menu {
                                ForEach(LessonStatus.allCases) { s in
                                    Button(t.status(s)) { store.setStatus(s, for: lesson.id) }
                                }
                            } label: {
                                Label("Status", systemImage: "circle.lefthalf.filled")
                            }
                            Button(role: .destructive) {
                                store.delete(lessonID: lesson.id)
                                dismiss()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            MoreCircleLabel()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .frame(height: 64, alignment: .top)

                // Title block
                VStack(alignment: .leading, spacing: 5.8) {
                    titleLine(className: className, lesson: lesson)
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.textPrimary)
                        .strikethrough(cancelled)
                    if !lesson.subject.isEmpty || lesson.subjectChanged {
                        changeLine(lesson.subject, original: lesson.subjectChanged ? lesson.originalSubject : nil,
                                   size: 22, color: Theme.textPrimary, strike: cancelled)
                    }
                    if !lesson.room.isEmpty || lesson.roomChanged {
                        changeLine(lesson.room, original: lesson.roomChanged ? lesson.originalRoom : nil,
                                   size: 17, color: Theme.textSecondary, strike: cancelled)
                            .padding(.top, 2)
                    }
                    teacherLine(lesson)
                        .padding(.top, 4)
                    statusBlock(lesson)
                }
                .padding(.horizontal, 20)
                .padding(.top, 23.6)
                .padding(.bottom, 20)

                Rectangle()
                    .fill(Theme.sheetSeparator)
                    .frame(height: 2.0 / 3.0)

                // Homework row
                Button { showHomework = true } label: {
                    HStack(spacing: 0) {
                        HomeworkIcon(color: Theme.iconSheet, background: Theme.sheet)
                            .padding(.leading, 22)
                        Text(t.homework)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.leading, 19)
                        Spacer()
                        Text("\(lesson.homework.count)")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(hex: 0x10171D))
                            .frame(width: 31.7, height: 31.7)
                            .background(Theme.iconSheet, in: Circle())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(Theme.iconSheet)
                            .padding(.leading, 17)
                            .padding(.trailing, 28)
                    }
                    .frame(height: 80)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if !lesson.info.isEmpty {
                    HStack(alignment: .top, spacing: 0) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 21, weight: .light))
                            .foregroundStyle(Theme.iconSheet)
                            .frame(width: 24, height: 24)
                            .padding(.leading, 22)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(t.lessonInfo)
                                .font(.system(size: 17))
                                .foregroundStyle(Theme.textPrimary)
                            Text(lesson.info)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.leading, 19)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func titleLine(className: String, lesson: Lesson) -> Text {
        let parts = [className, lesson.text].filter { !$0.isEmpty }
        if parts.count == 2 {
            return Text("\(Text(parts[0])) \(Text("|").foregroundStyle(Theme.iconSheet)) \(Text(parts[1]))")
        }
        return Text(parts.first ?? lesson.subject)
    }

    private func changeLine(_ value: String, original: String?, size: CGFloat, color: Color, strike: Bool) -> some View {
        HStack(spacing: 8) {
            Text(value)
                .font(.system(size: size))
                .foregroundStyle(color)
                .strikethrough(strike)
            if let original, !original.isEmpty {
                Text(original)
                    .font(.system(size: size))
                    .foregroundStyle(Theme.icon)
                    .strikethrough(true)
            }
        }
        .lineLimit(2)
    }

    @ViewBuilder
    private func teacherLine(_ lesson: Lesson) -> some View {
        let name = lesson.teacherName.isEmpty ? lesson.teacher : "\(lesson.teacherName) (\(lesson.teacher))"
        VStack(alignment: .leading, spacing: 4) {
            if !name.isEmpty {
                Text(name)
                    .font(.system(size: 15.5))
                    .foregroundStyle(Theme.textSecondary)
                    .strikethrough(lesson.status == .cancelled)
            }
            if lesson.teacherChanged {
                let old = lesson.originalTeacherName.isEmpty
                    ? lesson.originalTeacher
                    : "\(lesson.originalTeacherName) (\(lesson.originalTeacher))"
                Text("\(store.t.insteadOf) \(old)")
                    .font(.system(size: 15.5))
                    .foregroundStyle(Theme.icon)
                    .strikethrough(true)
            }
        }
    }

    @ViewBuilder
    private func statusBlock(_ lesson: Lesson) -> some View {
        let t = store.t
        if lesson.status != .regular {
            VStack(alignment: .leading, spacing: 6) {
                Text(t.status(lesson.status))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.onBadge)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(CardPalette.statusColor(lesson.status), in: RoundedRectangle(cornerRadius: 6))
                if lesson.status == .exam && !lesson.examName.isEmpty {
                    Text(lesson.examName)
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.textPrimary)
                }
                if !lesson.note.isEmpty {
                    Text(lesson.note)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.top, 12)
        }
    }
}

struct HomeworkListView: View {
    @EnvironmentObject private var store: MockStore
    var lessonID: UUID
    @State private var newText = ""

    var body: some View {
        let t = store.t
        List {
            if let index = store.data.lessons.firstIndex(where: { $0.id == lessonID }) {
                Section {
                    ForEach($store.data.lessons[index].homework) { $hw in
                        HStack {
                            Button { hw.done.toggle() } label: {
                                Image(systemName: hw.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(hw.done ? Theme.accent : Theme.icon)
                            }
                            .buttonStyle(.plain)
                            TextField("Homework", text: $hw.text, axis: .vertical)
                        }
                    }
                    .onDelete { offsets in
                        store.data.lessons[index].homework.remove(atOffsets: offsets)
                    }
                }
                Section {
                    HStack {
                        TextField("New homework", text: $newText)
                        Button("Add") {
                            let text = newText.trimmingCharacters(in: .whitespaces)
                            guard !text.isEmpty else { return }
                            store.data.lessons[index].homework.append(Homework(text: text))
                            newText = ""
                        }
                        .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.sheet)
        .navigationTitle(t.homework)
        .navigationBarTitleDisplayMode(.inline)
    }
}
