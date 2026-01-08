import SwiftUI

struct LockOverlayView: View {
    let unlockPhrase: String
    @State private var flashOpacity: Double = 0
    @State private var flashColor: Color = .blue

    private let colors: [Color] = [.blue, .purple, .pink, .mint, .cyan, .indigo]

    var body: some View {
        ZStack {
            // Very transparent background
            Color.black.opacity(0.1)

            // Gentle glow effect on key press
            flashColor.opacity(flashOpacity)
                .blur(radius: 100)
                .ignoresSafeArea()

            // Small unlock hint at bottom
            VStack {
                Spacer()
                HStack {
                    Image("MenuBarIconLocked")
                    Text("Type \"\(unlockPhrase)\" to unlock")
                        .font(.system(size: 14))
                }
                .foregroundStyle(.white.opacity(0.6))
                .padding(12)
                .background(.black.opacity(0.4))
                .clipShape(Capsule())
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .keyPressed)) { _ in
            flash()
        }
    }

    private func flash() {
        flashColor = colors.randomElement() ?? .blue
        withAnimation(.easeIn(duration: 0.1)) {
            flashOpacity = 0.15
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            flashOpacity = 0
        }
    }
}
