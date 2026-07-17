# CLAUDE.md

macOS SwiftUI demo (SwiftPM executable, no Xcode project). Target: macOS 15+, Swift 6.

## Build & verify
- `./verify.sh` — build + test + render a PNG snapshot (the visual-confirmation artifact). Run this after changes.
- `./verify.sh --no-visual` — build + test only. `swift test` for tests alone.
- Snapshots render in-process via `ImageRenderer` (no window, no permissions). `ContentView` must stay renderable without a live window.

## Conventions
- **Design tokens, not magic numbers.** Sizes, radii, fonts, and colors come from `DesignSystem.swift` (`Layout`, `Radius`, `Typography`, `Prefs`) and `Theme.swift`. Add a token instead of inlining a value.
- **Colors** come from the theme: read `@Environment(ThemeStore.self)` in views, or use `Color(lightHex:darkHex:)`. Never hardcode hex in a view.
- **Borders** use the `.themedBorder(_:)` modifier, not a raw `.overlay(RoundedRectangle...)`.
- **Keep logic out of views.** Pure, testable types live beside the view (`GlassHover`, `OpacityControl`, `MeshBackdrop`). Add a unit test in `Tests/` for new logic.

## State
- App state is `@Observable` classes owned by `ContentView` and injected via `.environment(...)`: `ThemeStore`, `UIState`, `TransparencyModel`, `SystemAppearance`.
- Persisted settings use the `didSet → UserDefaults` + read-in-`init` pattern with a key from `Prefs`.
- `@State` is always `private`. Mark UI-owned observable models `@MainActor`.

## AppKit bridging
- `NSWindow` tweaks go through `WindowConfigurator` (an `NSViewRepresentable` in the root `.background`). Pass observed state as its `version` so it re-runs on change.
- Titlebar buttons are SwiftUI hosted via `HeaderAccessoryController`; inject `ThemeStore` explicitly into each `NSHostingView` (it can't read the SwiftUI environment).

## Guardrails
- Prefer native SwiftUI APIs; bridge to AppKit only when SwiftUI can't reach a setting.
- Keep the two theme tables (`ThemeStore.palettes` and `ThemeSwatch.all`) in sync — they share `ThemeID`.
- Keep comments accurate: update or delete them when the code they describe changes.
