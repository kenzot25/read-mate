import SwiftUI

public struct HUDView: View {
    @State private var selectedText: String
    @State private var hasAccessibility: Bool = false

    public init(initialSelectedText: String) {
        self._selectedText = State(initialValue: initialSelectedText)
    }

    public var body: some View {
        ZStack {
            // Bright solid background for high contrast readability
            Color.white
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)

            // Subtle border
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.88, green: 0.88, blue: 0.9), lineWidth: 1)

            VStack(spacing: 0) {
                // Minimal header: title + close button
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)

                    Text("ReadMate")
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

                // Content - Explain only
                Group {
                    if !hasAccessibility && selectedText.isEmpty {
                        AccessibilityOnboardingView(hasPermission: $hasAccessibility)
                    } else {
                        ExplainView(selectedText: $selectedText)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 440, height: 420)
        .onAppear {
            checkPermissions()
        }
    }

    private func checkPermissions() {
        self.hasAccessibility = SelectionService.shared.isAccessibilityGranted()
    }
}

struct AccessibilityOnboardingView: View {
    @Binding var hasPermission: Bool
    @State private var isChecking = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 38))
                .foregroundColor(.blue)
                .padding(14)
                .background(Color(red: 0.9, green: 0.93, blue: 1.0))
                .clipShape(Circle())

            Text("Accessibility Permission Required")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))

            VStack(alignment: .leading, spacing: 10) {
                OnboardingStepRow(step: "1", text: "Open System Settings.")
                OnboardingStepRow(step: "2", text: "Go to Privacy & Security \u{2192} Accessibility.")
                OnboardingStepRow(step: "3", text: "Toggle 'ReadMate' to enabled.")
            }
            .padding(.horizontal, 24)

            Text("This allows ReadMate to instantly read text you highlight in other apps when you press the shortcut.")
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 12) {
                Button(action: openSystemAccessibilitySettings) {
                    Text("Grant Permission")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: verifyPermission) {
                    HStack(spacing: 4) {
                        if isChecking {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Verify")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.92, green: 0.92, blue: 0.94))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)

            Spacer()
        }
    }

    private func openSystemAccessibilitySettings() {
        _ = SelectionService.shared.isAccessibilityGranted(prompt: true)

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func verifyPermission() {
        isChecking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let granted = SelectionService.shared.isAccessibilityGranted()
            self.hasPermission = granted
            self.isChecking = false
        }
    }
}

struct OnboardingStepRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 16, height: 16)
                .background(Color.blue)
                .clipShape(Circle())
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.25))
        }
    }
}