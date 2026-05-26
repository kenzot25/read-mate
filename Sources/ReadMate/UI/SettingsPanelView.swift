import SwiftUI

struct SettingsPanelView: View {
    var body: some View {
        ZStack {
            Color.white
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)

            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.88, green: 0.88, blue: 0.9), lineWidth: 1)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)

                    Text("Settings")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))

                    Spacer()

                    Button(action: { PanelController.shared.hidePanel() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                            .frame(width: 20, height: 20)
                            .background(Color(red: 0.92, green: 0.92, blue: 0.94))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(Color(red: 0.97, green: 0.97, blue: 0.98))

                Divider()
                    .background(Color(red: 0.9, green: 0.9, blue: 0.92))

                SettingsView()
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 440, height: 420)
    }
}