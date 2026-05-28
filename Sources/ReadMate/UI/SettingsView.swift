import SwiftUI

public struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var isShowingKey: Bool = false
    @State private var isSavedSuccessfully: Bool = false
    @State private var dictionaryMode: DictionaryMode = PreferencesManager.shared.dictionaryMode

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {

                    // Gemini API Key Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GEMINI API KEY")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))

                        HStack(spacing: 8) {
                            if isShowingKey {
                                TextField("AIzaSy...", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.94, green: 0.94, blue: 0.96))
                                    .cornerRadius(8)
                                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15))
                            } else {
                                SecureField("AIzaSy...", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.94, green: 0.94, blue: 0.96))
                                    .cornerRadius(8)
                                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.15))
                            }

                            Button(action: { isShowingKey.toggle() }) {
                                Image(systemName: isShowingKey ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                                    .frame(width: 32, height: 32)
                                    .background(Color(red: 0.93, green: 0.93, blue: 0.95))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: saveKey) {
                            HStack(spacing: 6) {
                                if isSavedSuccessfully {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Saved securely")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "lock.shield.fill")
                                    Text("Save to Keychain")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: isSavedSuccessfully
                                        ? [Color.green.opacity(0.8), Color.green.opacity(0.6)]
                                        : [Color.blue, Color(red: 0.08, green: 0.35, blue: 0.95)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Text("Get a free Gemini API key from Google AI Studio. Stored securely in your native macOS Keychain.")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .background(Color(red: 0.9, green: 0.9, blue: 0.92))
                            .padding(.vertical, 4)

                        Text("DICTIONARY MODE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))

                        Picker("", selection: $dictionaryMode) {
                            ForEach(DictionaryMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 220)
                        .onChange(of: dictionaryMode) { newValue in
                            PreferencesManager.shared.dictionaryMode = newValue
                        }

                        Text("English-English uses Cambridge Dictionary. English-Vietnamese uses Cambridge English-Vietnamese dictionary.")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)

                    // Excluded Apps Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRIVACY & EXCLUDED APPS")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))

                        Text("No text is sent to the AI until you trigger a lookup. Keychains, Passwords, and Banking apps are naturally protected by your system security.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.45))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)

                    // App Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ABOUT")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ReadMate macOS v0.1.1")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                                Text("Open-Source native reading assistant.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.5))
                            }
                            Spacer()

                            Button(action: quitApplication) {
                                Text("Quit App")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.08))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.98))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear(perform: loadSavedKey)
    }

    private func loadSavedKey() {
        if let saved = KeychainManager.shared.retrieve() {
            self.apiKey = saved
        }
    }

    private func saveKey() {
        let success = KeychainManager.shared.save(key: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
        if success {
            withAnimation(.spring()) {
                isSavedSuccessfully = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    isSavedSuccessfully = false
                }
            }
        }
    }

    private func quitApplication() {
        NSApp.terminate(nil)
    }
}