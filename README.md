# ReadMate

A native macOS menu-bar app that instantly explains any text you select. Built with Swift and SwiftUI.

Select a word, phrase, or sentence in any app — ReadMate pops up with the meaning, Vietnamese translation, vocabulary breakdown, grammar notes, and natural examples.

## Features

- **Instant explain** — Select text anywhere, press `Cmd+Shift+E` (or click the floating sparkles button)
- **Vietnamese translation** — Every lookup includes a Vietnamese meaning
- **Vocabulary breakdown** — Key words extracted and explained individually
- **Grammar insights** — Sentence structure and grammar patterns explained
- **Natural examples** — Real-world usage examples for context
- **AI-powered** — Uses Google Gemini for deep explanations (free API key from Google AI Studio)
- **Offline fallback** — Falls back to a free dictionary API when no API key is configured
- **Native macOS** — Menu bar agent, no Dock icon, feels right at home

## Install

### Download

Grab the latest `.dmg` from [Releases](https://github.com/kenzot25/read-mate/releases), open it, and drag ReadMate to your Applications folder.

First launch: right-click the app and choose **Open** (required for unsigned apps on macOS).

### Build from source

Requires macOS 15 (Sequoia) and Xcode Command Line Tools.

```bash
git clone https://github.com/kenzot25/read-mate.git
cd read-mate
make dmg
```

The DMG will be at `build/ReadMate-0.1.0.dmg`.

## Setup

1. Launch ReadMate — a sparkles icon appears in your menu bar
2. Grant **Accessibility** permission when prompted (needed to read selected text)
3. (Optional) Right-click the menu bar icon → **Settings** → add your Gemini API key for AI-powered explanations

## Usage

| Action | How |
|---|---|
| Explain selected text | Select text in any app, press `Cmd+Shift+E` |
| Quick explain | Select text, click the floating sparkles button that appears |
| Type manually | Left-click the menu bar icon, enter text in the input bar |
| Open settings | Right-click the menu bar icon → Settings |

## Tech Stack

- **Swift / SwiftUI** — Native macOS app
- **Swift Package Manager** — No Xcode project, pure SPM
- **Google Gemini API** — AI explanations (optional)
- **macOS Keychain** — Secure API key storage
- **Accessibility API** — Read text selection from other apps

## Project Structure

```
Sources/ReadMate/
├── Main.swift                    # App entry point, menu bar, hotkey
├── Models/
│   ├── AITemplate.swift          # Prompt templates for AI
│   └── WordLookup.swift          # Data models
├── Services/
│   ├── AIService.swift           # Gemini AI integration
│   ├── DictionaryService.swift   # Free dictionary fallback
│   ├── HistoryService.swift       # Local lookup history
│   ├── HotKeyManager.swift        # Global keyboard shortcut
│   ├── KeychainManager.swift      # macOS Keychain wrapper
│   └── SelectionService.swift     # Accessibility text selection
└── UI/
    ├── HUDView.swift              # Main popup container
    ├── ExplainView.swift          # Explanation content
    ├── FloatingPanel.swift        # NSPanel subclass
    ├── FloatingSelectionButton.swift # Cursor-following button
    ├── SettingsPanelView.swift     # Settings panel wrapper
    ├── SettingsView.swift          # Settings content
    └── VisualEffectView.swift      # NSVisualEffectView wrapper
```

## License

MIT