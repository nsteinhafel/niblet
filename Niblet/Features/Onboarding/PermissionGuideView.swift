import SwiftUI

struct PermissionGuideView: View {
    var onOpenSettings: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Accessibility Permission Required")
                .font(.headline)

            Text("Niblet needs accessibility access to block keyboard and mouse input while locked.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: 1, text: "Click \"Open Settings\" below")
                instructionRow(number: 2, text: "Find Niblet in the list")
                instructionRow(number: 3, text: "Toggle the switch to enable access")
            }
            .padding()
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Open Settings") {
                    onOpenSettings()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 340)
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(.blue)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}
