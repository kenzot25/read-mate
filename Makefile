# ─────────────────────────────────────────────
#  ReadMate – Build & Distribution Makefile
# ─────────────────────────────────────────────

APP_NAME    = ReadMate
VERSION     = 0.1.0

# Paths
BUILD_DIR       = build
APP_BUNDLE      = $(BUILD_DIR)/$(APP_NAME).app
MACOS_DIR       = $(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR   = $(APP_BUNDLE)/Contents/Resources
DMG_STAGING     = $(BUILD_DIR)/dmg-staging
DMG_OUT         = $(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg
ASSETS_DIR      = Resources/Assets.xcassets

.PHONY: all build app release sign dmg run clean icons

# Default: build debug bundle
all: app

# ── Swift compile (debug) ──────────────────────
build:
	swift build

# ── Swift compile (release, optimised) ────────
release-build:
	swift build -c release

# ── Compile asset catalog into Assets.car ─────
compile-assets:
	mkdir -p "$(RESOURCES_DIR)"
	actool "$(ASSETS_DIR)" \
	    --compile "$(RESOURCES_DIR)" \
	    --platform macosx \
	    --minimum-deployment-target 15.0 \
	    --app-icon AppIcon \
	    --output-partial-info-plist "$(RESOURCES_DIR)/AssetCatalog-Info.plist" 2>/dev/null || \
	echo "⚠️  actool not found or failed — icon may be missing (install Xcode CLI tools)"

# ── Generate icon PNGs from Swift script ───────
icons:
	swift Scripts/generate_icon.swift

# ── Package debug binary into .app bundle ─────
app: build compile-assets
	mkdir -p "$(MACOS_DIR)"
	cp -f ".build/debug/$(APP_NAME)"  "$(MACOS_DIR)/$(APP_NAME)"
	cp -f "Resources/Info.plist"       "$(APP_BUNDLE)/Contents/Info.plist"
	@echo "✅  Debug bundle ready → $(APP_BUNDLE)"

# ── Package optimised binary into .app bundle ─
release: release-build compile-assets
	mkdir -p "$(MACOS_DIR)"
	cp -f ".build/release/$(APP_NAME)" "$(MACOS_DIR)/$(APP_NAME)"
	cp -f "Resources/Info.plist"       "$(APP_BUNDLE)/Contents/Info.plist"
	@echo "✅  Release bundle ready → $(APP_BUNDLE)"

# ── Ad-hoc code-sign the .app ─────────────────
#    Ad-hoc signing (-) lets the app run on any
#    Apple-silicon or Intel Mac without a paid
#    developer account. Users may need to right-
#    click → Open the first time (Gatekeeper).
sign: release
	codesign --deep --force --sign - \
	          --options runtime \
	          "$(APP_BUNDLE)"
	@echo "✅  App signed (ad-hoc)"
	codesign --verify --deep --strict "$(APP_BUNDLE)" && \
	  echo "✅  Signature verified"

# ── Build a distributable .dmg installer ──────
#    Creates a drag-to-Applications disk image.
dmg: sign
	@echo "📦  Building $(DMG_OUT) …"

	# 1. Clean and prepare staging area
	rm -rf  "$(DMG_STAGING)"
	mkdir -p "$(DMG_STAGING)"

	# 2. Copy the signed .app into staging
	cp -r "$(APP_BUNDLE)" "$(DMG_STAGING)/$(APP_NAME).app"

	# 3. Add /Applications symlink (drag-and-drop target)
	ln -s /Applications "$(DMG_STAGING)/Applications"

	# 4. Remove any old DMG
	rm -f "$(DMG_OUT)"

	# 5. Create compressed, internet-ready DMG
	hdiutil create \
	    -volname "$(APP_NAME) $(VERSION)" \
	    -srcfolder "$(DMG_STAGING)" \
	    -ov \
	    -format UDZO \
	    -imagekey zlib-level=9 \
	    "$(DMG_OUT)"

	# 6. Clean up staging
	rm -rf "$(DMG_STAGING)"

	@echo ""
	@echo "🎉  Installer ready:"
	@echo "    $(DMG_OUT)"
	@echo ""
	@echo "    Share this file. Users double-click it,"
	@echo "    drag ReadMate → Applications, and they're done."

# ── Launch the debug bundle ────────────────────
run: app
	open "$(APP_BUNDLE)"

# ── Remove all build artefacts ─────────────────
clean:
	swift package clean
	rm -rf build .build