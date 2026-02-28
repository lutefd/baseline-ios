import SwiftUI

enum BaselineTheme {
    static let backgroundTop = Color(red: 0.99, green: 0.99, blue: 0.985)
    static let backgroundBottom = Color(red: 0.935, green: 0.935, blue: 0.925)
    static let cardTint = Color.white.opacity(0.36)
    static let border = Color.white.opacity(0.7)
    static let innerShadow = Color.black.opacity(0.08)
    static let primaryText = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let secondaryText = Color(red: 0.36, green: 0.36, blue: 0.38)
    static let accent = Color(red: 0.28, green: 0.26, blue: 0.23)
    static let accentSoft = Color(red: 0.95, green: 0.94, blue: 0.92)
    static let chartSurface = Color(red: 0.97, green: 0.965, blue: 0.955).opacity(0.62)
    static let rowSurface = Color(red: 0.965, green: 0.955, blue: 0.94).opacity(0.72)
}

enum BaselineTypography {
    static let hero = Font.system(size: 50, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let cardValue = Font.system(size: 42, weight: .bold, design: .rounded)
    static let cardLabel = Font.system(size: 16, weight: .medium, design: .rounded)
    static let bodyStrong = Font.system(size: 19, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 14, weight: .medium, design: .rounded)
}

struct BaselineScreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [BaselineTheme.backgroundTop, BaselineTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.52))
                .frame(width: 260)
                .blur(radius: 56)
                .offset(x: -130, y: -260)

            Circle()
                .fill(.white.opacity(0.34))
                .frame(width: 220)
                .blur(radius: 60)
                .offset(x: 150, y: 260)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(.white.opacity(0.16))
                .frame(height: 280)
                .blur(radius: 30)
                .offset(y: 260)
        }
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
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BaselineTheme.cardTint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BaselineTheme.border, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BaselineTheme.innerShadow, lineWidth: 0.25)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.62), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: BaselineTheme.innerShadow, radius: 16, x: 0, y: 9)
    }
}
