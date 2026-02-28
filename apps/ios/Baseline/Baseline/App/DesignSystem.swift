import SwiftUI

enum BaselineTheme {
    static let backgroundTop = Color(red: 0.95, green: 0.97, blue: 0.99)
    static let backgroundBottom = Color(red: 0.91, green: 0.94, blue: 0.97)
    static let card = Color.white.opacity(0.8)
    static let border = Color.black.opacity(0.08)
    static let primaryText = Color(red: 0.10, green: 0.12, blue: 0.15)
    static let secondaryText = Color(red: 0.30, green: 0.35, blue: 0.42)
    static let accent = Color(red: 0.06, green: 0.37, blue: 0.60)
    static let accentSoft = Color(red: 0.56, green: 0.76, blue: 0.90)
}

struct BaselineScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [BaselineTheme.backgroundTop, BaselineTheme.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct BaselineCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(BaselineTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BaselineTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
