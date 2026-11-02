import SwiftUI

/// Large bold page title ("BBSMusterstadt", user name on Profile).
struct LargeTitle: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(Theme.textTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .padding(.trailing, 16)
    }
}

/// Rounded dark container used for grouped rows.
struct CardContainer<Content: View>: View {
    var horizontalMargin: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCornerLarge, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerLarge, style: .continuous))
            .padding(.horizontal, horizontalMargin)
    }
}

/// One tappable row inside a `CardContainer`: icon, title, chevron.
struct CardRow: View {
    var icon: RowIcon
    var title: String
    var showSeparator: Bool = false
    var chevronTrailing: CGFloat = 27

    var body: some View {
        HStack(spacing: 0) {
            RowIconView(icon: icon)
                .padding(.leading, 16)
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .padding(.leading, 16)
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Theme.icon)
                .padding(.trailing, chevronTrailing)
        }
        .frame(height: Theme.rowHeight)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if showSeparator {
                Rectangle()
                    .fill(Theme.listSeparator)
                    .frame(height: 1.0 / 3.0)
                    .padding(.leading, 56)
                    .padding(.trailing, 16)
            }
        }
    }
}

/// Plain button style that only dims slightly on press (keeps the exact look).
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.white.opacity(0.06) : Color.clear)
    }
}

/// Centered title bar with optional trailing buttons, sitting on black.
struct TopBar<Center: View, Trailing: View>: View {
    @ViewBuilder var center: Center
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack {
            center
            HStack(spacing: 12) {
                Spacer()
                trailing
            }
            .padding(.trailing, 20)
        }
        .frame(height: Theme.navRowHeight)
    }
}

/// Initials avatar (gray circle, white letters).
struct InitialsAvatar: View {
    var initials: String
    var size: CGFloat = 44
    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .regular))
            .foregroundStyle(Color.white)
            .frame(width: size, height: size)
            .background(Theme.icon, in: Circle())
    }
}

/// Screens pushed from the main tabs use the system navigation bar (glass back
/// button on iOS 26) on a black background.
struct PlainPage<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { content }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EmptyHint: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 17))
            .foregroundStyle(Theme.icon)
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
    }
}
