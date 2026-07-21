## General

- A macOS SwiftUI demo ("Liquid Glass"): a themed glass-card window with collapsible sidebars, a settings modal, a menu bar extra (tray), and live theme + Light/Dark/System switching. SwiftPM executable, no Xcode project. Targets macOS 15+, Swift 6.
- The main scene is a single `Window` (not `WindowGroup`): one app window max — no File ▸ New Window duplicates, and `openWindow(id:)` always focuses the same window.
- Build all functionality in SwiftUI; drop to AppKit only for a feature SwiftUI doesn't expose (see AppKit bridging).
- Design UI idiomatically for macOS, following Apple's Human Interface Guidelines.
- Use SF Symbols for iconography, not custom image assets.
- Use modern macOS APIs available on the deployment target; gate anything newer than macOS 15 with `#available` and a fallback.
- Use modern Swift 6 features: `async/await`, actors, `@MainActor`, and macros where applicable.

## Bash commands

- `scripts/verify.sh` — build + test + render a PNG snapshot (the visual-confirmation artifact). Run after changes.
- `scripts/verify.sh --no-visual` — build + test only. `swift test` runs the tests alone.
- `swift run LiquidGlassDemo` (or `.build/debug/LiquidGlassDemo`) launches the real window. Kill any running instance first: `pkill -f LiquidGlassDemo || true`.
- CLI render paths (no window): `--snapshot <path> [--size WxH]` writes a PNG; `--icon <path>` writes the app icon.
- Snapshots render in-process via `ImageRenderer` (no window, no permissions), so `ContentView` must stay renderable without a live window.

## Code style

- Indent with 4 spaces.
- Use design tokens, not magic numbers: sizes, radii, fonts, and keys come from `DesignSystem.swift` (`Layout`, `Radius`, `Typography`, `Prefs`). Add a token rather than inlining a value.
- Read colors from the theme (`@Environment(ThemeStore.self)`) or `Color(lightHex:darkHex:)`; never hardcode hex in a view.
- Stroke borders with the `.themedBorder(_:)` modifier, not a raw `.overlay(RoundedRectangle…)`.
- Keep pure, testable logic out of views (`GlassHover`, `OpacityControl`, `MeshBackdrop`).
- Don't over-comment. Skip comments that restate the code; add one only to explain the non-obvious *why*, and keep it accurate — update or delete it when the code changes.
- Document `public`/`open` declarations with a 1–3 sentence summary plus any parameters, return value, and thrown errors. Keep private declarations to a one-line summary when they need one at all.

## Tests

- One `@Suite` per subject, in `Tests/LiquidGlassDemoTests/<Subject>Tests.swift`. Use swift-testing (`@Test` + `#expect`), not XCTest.
- Add coverage for new pure logic. Mark suites/tests that touch `@MainActor` types (`ThemeStore`, `ContentView`) with `@MainActor`.

## State

- App state is `@Observable` classes injected via `.environment(…)`: `ThemeStore` is owned by `LiquidGlassDemoApp` (shared with the `MenuBarExtra` scene — a tray theme switch recolors the window); `UIState`, `TransparencyModel`, and `SystemAppearance` are owned by `ContentView`.
- Persisted settings use the `didSet → UserDefaults` + read-in-`init` pattern with a key from `Prefs`.
- `@State` is always `private`. Mark UI-owned observable models `@MainActor`.

## AppKit bridging

- `NSWindow` tweaks go through `WindowConfigurator` (an `NSViewRepresentable` in the root `.background`); pass observed state as its `version` so it re-runs on change.
- Titlebar buttons are SwiftUI hosted via `HeaderAccessoryController`; inject `ThemeStore` explicitly into each `NSHostingView` (it can't read the SwiftUI environment).

## Distribution

- Ships as a signed, notarized DMG with Sparkle auto-updates (direct download, not the App Store). Full pipeline and setup: `RELEASE.md`.
- `scripts/build_app.sh` packages `dist/LiquidGlassDemo.app`; `scripts/release.sh` builds → notarizes → updates `appcast.xml` → publishes the GitHub release. Config lives in `app.yml` (public values only — no secrets).
- Sparkle is guarded in `Updater.swift`: it only starts inside a bundle with a real `SUFeedURL`/`SUPublicEDKey`, so `swift run` and the CLI render paths never touch it. Don't remove that guard.

## Guardrails

- Keep the two theme tables (`ThemeStore.palettes` and `ThemeSwatch.all`) in sync — they share `ThemeID`.
