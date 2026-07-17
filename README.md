# LiquidGlassDemo

A macOS SwiftUI app demonstrating a **Liquid Glass** card (`.ultraThinMaterial`)
inside a three-column app shell, styled with an adaptive **Slate** theme (six
palettes × light/dark/system), adjustable window/card transparency, and a native
settings modal. Built as a Swift Package — no Xcode project required.

## Features

- **Three-column shell** — a collapsible left sidebar, a padded main content area
  (the glass hero card over a grid backdrop), and an optional right panel. Toggled
  from chrome-free buttons on the traffic-light row (native titlebar accessories).
- **Themes** — six palettes (Slate, Nous, Midnight, Ember, Mono, Cyberpunk), each
  with light + dark variants, plus a **Light / Dark / System** mode. Selecting a
  theme recolors the whole app live.
- **Transparency** — independent **Window Opacity** (fades the whole window via
  `NSWindow.alphaValue`) and **Card Opacity** (fades only the glass panel) sliders.
- **Settings modal** — dim backdrop + panel with a nav and an Appearance section
  (theme grid, mode, transparency) and a custom thin scrollbar.
- **Persistence** — theme, mode, opacities, and sidebar state are saved to
  `UserDefaults` and restored on relaunch.

## Architecture

| Path | Purpose |
|------|---------|
| [LiquidGlassDemoApp.swift](Sources/LiquidGlassDemo/LiquidGlassDemoApp.swift) | `@main` entry; windowed app, `--snapshot`/`--icon` render modes, `AppDelegate` (Dock icon + activation) |
| [ContentView.swift](Sources/LiquidGlassDemo/ContentView.swift) | Three-column shell, header, window configuration |
| [Sidebars.swift](Sources/LiquidGlassDemo/Sidebars.swift) | Left / right sidebar columns |
| [SettingsModal.swift](Sources/LiquidGlassDemo/SettingsModal.swift) · [ThemePicker.swift](Sources/LiquidGlassDemo/ThemePicker.swift) | Settings modal + Appearance/theme UI |
| [HeaderAccessory.swift](Sources/LiquidGlassDemo/HeaderAccessory.swift) · [IconButton.swift](Sources/LiquidGlassDemo/IconButton.swift) | Titlebar accessory buttons |
| [Theme.swift](Sources/LiquidGlassDemo/Theme.swift) | Observable theme store (`Theme.background`, …) + all palettes |
| [DesignSystem.swift](Sources/LiquidGlassDemo/DesignSystem.swift) | `Radius`, `Layout`, `Prefs` constants + `themedBorder` |
| [TransparencyModel.swift](Sources/LiquidGlassDemo/TransparencyModel.swift) · [UIState.swift](Sources/LiquidGlassDemo/UIState.swift) | Observable, persisted state |
| [LiquidGlassModel.swift](Sources/LiquidGlassDemo/LiquidGlassModel.swift) | Testable value types (card content, hover, `OpacityControl`, mesh) |
| [WindowConfigurator.swift](Sources/LiquidGlassDemo/WindowConfigurator.swift) · [PatternBackground.swift](Sources/LiquidGlassDemo/PatternBackground.swift) · [ScrollableContent.swift](Sources/LiquidGlassDemo/ScrollableContent.swift) · [AppIcon.swift](Sources/LiquidGlassDemo/AppIcon.swift) | NSWindow bridge, grid, custom scrollbar, Dock icon |
| [Tests/](Tests/LiquidGlassDemoTests/) | XCTest suite | [verify.sh](verify.sh) | build → test → snapshot loop |

**State & reactivity.** `Theme` is a global `@Observable` store, so reading
`Theme.background`-style properties in any view auto-tracks the selected theme —
switching palettes re-colors the app with no manual refresh. `UIState` and
`TransparencyModel` are `@Observable` and persist via `UserDefaults` (keys live in
`Prefs`). SwiftUI can't set window-level transparency/appearance directly, so
[WindowConfigurator](Sources/LiquidGlassDemo/WindowConfigurator.swift) bridges to
the `NSWindow`.

## Requirements

- **macOS 15+** (uses `pointerStyle`, `onScrollGeometryChange`, `ScrollPosition`)
- **Swift 6 toolchain** (Xcode 16+). Verify with `swift --version`.

## Build & run

```bash
swift build          # build
swift run            # launch the app window
swift run -c release # release build
```

## Testing / verifying

```bash
swift test           # 14 unit tests (opacity clamping, mesh invariants, hover, card content)
./verify.sh          # build → test → render a PNG snapshot → report
./verify.sh --no-visual   # build + test only
./verify.sh --live        # also grab a live window screenshot (needs Screen Recording permission)
```

The **snapshot** ([verify-artifacts/screenshot.png](verify-artifacts/screenshot.png))
is rendered in-process via `ImageRenderer` (the app's `--snapshot <path>` mode) — no
window, no Screen Recording permission, deterministic. Render one directly:

```bash
"$(swift build --show-bin-path)/LiquidGlassDemo" --snapshot out.png --size 1180x760
```

> **`ImageRenderer` caveats:** it can't capture live AppKit controls, the material's
> real blur, `NSWindow` transparency, or titlebar accessories — those only appear in
> the running app. It also ignores `preferredColorScheme`, so snapshots render in
> light appearance regardless of the selected mode (the theme palette is still
> applied). Use `./verify.sh --live` for a pixel-accurate window shot.

## Cleaning

```bash
swift package clean   # or: rm -rf .build
```
