import SwiftUI

struct MessagesView: View {
    @EnvironmentObject private var store: MockStore
    @State private var folder: MessageFolder = .inbox
    @State private var searching = false
    @State private var query = ""
    @State private var editing: Message?
    @FocusState private var searchFocused: Bool

    var body: some View {
        let t = store.t
        let items = store.data.messages
            .filter { $0.folder == folder }
            .filter { query.isEmpty || "\($0.displaySender) \($0.subject) \($0.body)".localizedCaseInsensitiveContains(query) }
            .sorted { $0.date > $1.date }

        NavigationStack {
            VStack(spacing: 0) {
                TopBar {
                    Text(t.messages)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textTitle)
                } trailing: {
                    Button {
                        withAnimation(.snappy) { searching.toggle() }
                        if !searching { query = "" } else { searchFocused = true }
                    } label: {
                        CircleGlyph(systemName: "magnifyingglass", size: 21, weight: .medium, color: Color.white)
                    }
                    .buttonStyle(.plain)
                    Button {
                        editing = Message(folder: folder == .drafts ? .drafts : .inbox, date: store.now, isRead: false)
                    } label: {
                        CircleGlyph(systemName: "plus", size: 22, weight: .regular, color: Color.white)
                    }
                    .buttonStyle(.plain)
                }

                if searching {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.icon)
                        TextField(t.search, text: $query)
                            .focused($searchFocused)
                            .foregroundStyle(Theme.textPrimary)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(Theme.surface, in: Capsule())
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Inbox / Sent / Drafts
                HStack(spacing: 27.7) {
                    ForEach(MessageFolder.allCases) { f in
                        Button { folder = f } label: {
                            Text(t.folder(f))
                                .font(.system(size: 17.5, weight: folder == f ? .bold : .semibold))
                                .foregroundStyle(folder == f ? Theme.textPrimary : Theme.textTitle)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.leading, 25)
                .frame(height: 62)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, message in
                            NavigationLink {
                                MessageDetailView(messageID: message.id)
                            } label: {
                                MessageRow(message: message, showSeparator: index < items.count - 1)
                            }
                            .buttonStyle(PressableStyle())
                            .contextMenu {
                                Button { editing = message } label: { Label("Edit", systemImage: "pencil") }
                                Button {
                                    var copy = message
                                    copy.id = UUID()
                                    store.data.messages.append(copy)
                                } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                                Button(role: .destructive) {
                                    store.data.messages.removeAll { $0.id == message.id }
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .background(items.isEmpty ? Color.clear : Theme.surface)
                    if items.isEmpty {
                        EmptyHint(text: t.noMessages)
                    }
                    Spacer(minLength: 120)
                }
                .scrollIndicators(.hidden)
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editing) { m in
                MessageEditor(message: m)
                    .environmentObject(store)
            }
        }
    }
}

struct MessageRow: View {
    @EnvironmentObject private var store: MockStore
    var message: Message
    var showSeparator: Bool

    var body: some View {
        let t = store.t
        HStack(alignment: .top, spacing: 0) {
            InitialsAvatar(initials: message.initials)
                .padding(.leading, 36)
                .padding(.top, 13)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(message.displaySender)
                        .font(.system(size: 17, weight: message.isRead ? .regular : .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(t.messageDate(message.date, now: store.now))
                        .font(.system(size: 15.5))
                        .foregroundStyle(Theme.textSecondary)
                }
                if !message.subject.isEmpty {
                    Text(message.subject)
                        .font(.system(size: 15.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                if !message.body.isEmpty {
                    Text(message.body.replacingOccurrences(of: "\n", with: " "))
                        .font(.system(size: 15.5))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.leading, 9)
            .padding(.trailing, 20)
            .padding(.top, 13.5)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: 2.0 / 3.0)
                    .padding(.leading, 88)
            }
        }
    }
}

struct MessageDetailView: View {
    @EnvironmentObject private var store: MockStore
    var messageID: UUID
    @State private var editing: Message?

    var body: some View {
        let t = store.t
        Group {
            if let m = store.data.messages.first(where: { $0.id == messageID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(m.subject)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        HStack(spacing: 12) {
                            InitialsAvatar(initials: m.initials)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(m.displaySender)
                                    .font(.system(size: 17))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(t.messageDate(m.date, now: store.now)), \(TimeFmt.hhmm(TimeFmt.minuteOfDay(m.date)))")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.icon)
                            }
                        }
                        Rectangle().fill(Theme.gridLine).frame(height: 2.0 / 3.0)
                        Text(m.body)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.textSecondary)
                            .textSelection(.enabled)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { editing = m } label: { Image(systemName: "pencil") }
                    }
                }
                .onAppear {
                    if let i = store.data.messages.firstIndex(where: { $0.id == messageID }), !store.data.messages[i].isRead {
                        store.data.messages[i].isRead = true
                    }
                }
            } else {
                EmptyHint(text: t.noMessages)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { m in
            MessageEditor(message: m)
                .environmentObject(store)
        }
    }
}

struct MessageEditor: View {
    @EnvironmentObject private var store: MockStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Message

    init(message: Message) {
        _draft = State(initialValue: message)
    }

    var body: some View {
        let t = store.t
        let exists = store.data.messages.contains { $0.id == draft.id }
        NavigationStack {
            Form {
                Section("Sender") {
                    TextField("Name (e.g. Keller Jana)", text: $draft.senderName)
                    TextField("Code (e.g. KELL)", text: $draft.senderCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section("Message") {
                    TextField("Subject", text: $draft.subject)
                    TextField("Text", text: $draft.body, axis: .vertical)
                        .lineLimit(4...12)
                }
                Section {
                    Picker("Folder", selection: $draft.folder) {
                        ForEach(MessageFolder.allCases) { f in Text(t.folder(f)).tag(f) }
                    }
                    DatePicker("Date", selection: $draft.date)
                    Toggle("Read", isOn: $draft.isRead)
                }
                if exists {
                    Section {
                        Button("Delete message", role: .destructive) {
                            store.data.messages.removeAll { $0.id == draft.id }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(exists ? "Edit message" : "New message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let i = store.data.messages.firstIndex(where: { $0.id == draft.id }) {
                            store.data.messages[i] = draft
                        } else {
                            store.data.messages.append(draft)
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
