import SwiftUI

@main
struct TimetableStudioApp: App {
    @StateObject private var store = MockStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

enum AppTab: Hashable {
    case home, timetable, messages, profile
}

struct RootView: View {
    @EnvironmentObject private var store: MockStore
    @State private var tab: AppTab = .home
    @State private var showStudio = false

    var body: some View {
        let t = store.t
        TabView(selection: $tab) {
            HomeView(showStudio: $showStudio, openTimetable: { tab = .timetable })
                .tabItem {
                    Label { Text(t.home) } icon: { Image(uiImage: TabIcons.home()) }
                }
                .tag(AppTab.home)

            TimetableView(showStudio: $showStudio)
                .tabItem {
                    Label { Text(t.timetable) } icon: { Image(uiImage: TabIcons.timetable(day: store.today.day)) }
                }
                .tag(AppTab.timetable)

            MessagesView()
                .tabItem {
                    Label(t.messages, systemImage: "envelope")
                }
                .tag(AppTab.messages)

            ProfileView(showStudio: $showStudio)
                .tabItem {
                    Label(t.profile, systemImage: "person")
                }
                .tag(AppTab.profile)
        }
        .tint(Color.white)
        .sheet(isPresented: $showStudio) {
            StudioSettingsView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
