import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: MockStore
    @Binding var showStudio: Bool
    @State private var confirmLogout = false

    var body: some View {
        let t = store.t
        let p = store.data.profile
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LargeTitle(text: p.fullName)
                        .padding(.top, 56.3)

                    // Account card
                    Button { showStudio = true } label: {
                        HStack(spacing: 0) {
                            InitialsAvatar(initials: p.initials)
                                .padding(.leading, 16)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(p.username)
                                    .font(.system(size: 18))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                                Text(p.role)
                                    .font(.system(size: 13.5))
                                    .foregroundStyle(Theme.onBadge)
                                    .padding(.horizontal, 6.5)
                                    .frame(height: 19.3)
                                    .background(Theme.icon, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .padding(.leading, 10)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Theme.icon)
                                .padding(.trailing, 26)
                        }
                        .frame(height: 85.3)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCornerLarge, style: .continuous))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    CardContainer(horizontalMargin: 20) {
                        NavigationLink { ContactDetailsView() } label: {
                            CardRow(icon: .symbol("person.text.rectangle"), title: t.contactDetails, showSeparator: true)
                        }
                        .buttonStyle(PressableStyle())
                        NavigationLink { InfoPage(title: t.changePassword, text: "") } label: {
                            CardRow(icon: .symbol("lock.rotation"), title: t.changePassword)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.top, 32.3)

                    CardContainer(horizontalMargin: 20) {
                        NavigationLink { InfoPage(title: t.whatsNew, text: "") } label: {
                            CardRow(icon: .symbol("megaphone"), title: t.whatsNew, showSeparator: true)
                        }
                        .buttonStyle(PressableStyle())
                        NavigationLink { InfoPage(title: t.rateApp, text: "") } label: {
                            CardRow(icon: .symbol("star.square"), title: t.rateApp, showSeparator: true)
                        }
                        .buttonStyle(PressableStyle())
                        NavigationLink { InfoPage(title: t.about, text: "Timetable Studio 1.0") } label: {
                            CardRow(icon: .symbol("info.circle"), title: t.about)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.top, 32.7)

                    CardContainer(horizontalMargin: 20) {
                        Button { confirmLogout = true } label: {
                            CardRow(icon: .symbol("rectangle.portrait.and.arrow.right"), title: t.logOut)
                        }
                        .buttonStyle(PressableStyle())
                    }
                    .padding(.top, 39)

                    Spacer(minLength: 120)
                }
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .alert(t.logOut, isPresented: $confirmLogout) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This is a mockup – there is nothing to log out of.")
            }
        }
    }
}

struct ContactDetailsView: View {
    @EnvironmentObject private var store: MockStore
    var body: some View {
        let p = store.data.profile
        PlainPage(title: store.t.contactDetails) {
            CardContainer(horizontalMargin: 20) {
                detail("E-Mail", p.email, separator: true)
                detail("Phone", p.phone.isEmpty ? "–" : p.phone, separator: false)
            }
        }
    }

    private func detail(_ label: String, _ value: String, separator: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 13)).foregroundStyle(Theme.icon)
            Text(value).font(.system(size: 17)).foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            if separator {
                Rectangle().fill(Theme.listSeparator).frame(height: 1.0 / 3.0).padding(.leading, 16)
            }
        }
    }
}

struct InfoPage: View {
    var title: String
    var text: String
    var body: some View {
        PlainPage(title: title) {
            if !text.isEmpty {
                Text(text)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 20)
            }
        }
    }
}
