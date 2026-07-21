# LiquidGlassDemo

<p align="center">
  <img src="images/hero.png" alt="LiquidGlassDemo — a Liquid Glass card over a grid backdrop in the Slate dark theme" width="820">
</p>

A **boilerplate macOS app template** built in pure SwiftUI — clone it as the
starting point for your own desktop app. It ships a themed **Liquid Glass** window
shell (a collapsible three-column layout with a hero card over a grid backdrop)
already wired to the pieces every real app needs: adaptive multi-theme support,
live Light/Dark/System switching, a native settings modal, persisted preferences,
and the AppKit bridges you reach for when SwiftUI stops short. Built as a Swift
Package, so there's no Xcode project to open — `swift run` and go.

## Features

- **Three-column shell** — a collapsible left sidebar with a theme quick-switch
  list, a main content area (the glass card over a themed mesh backdrop), and an
  optional right inspector panel. Toggles live on the traffic-light row as native
  titlebar accessories.
- **Real Liquid Glass** — the hero card uses the native `glassEffect` on macOS 26
  (tinted, interactive), with a tuned blur-mask fallback below it.
- **Six themes** — Slate, Nous, Midnight, Ember, Mono, and Cyberpunk, each with
  light and dark variants. Pick a theme and the whole app recolors instantly —
  including the mesh backdrop behind the card.
- **Light / Dark / System** — an explicit appearance mode that resolves System to
  the live OS setting and reverts cleanly.
- **Glass controls** — tune the card's opacity and the backdrop blur behind it from
  the settings panel and watch the frosted grid respond.
- **Native settings modal** — a dim backdrop and a compact themed panel with a
  custom thin scrollbar.
- **Persistence** — theme, appearance mode, glass settings, and sidebar state are
  saved to `UserDefaults` and restored on the next launch.

## Themes

Every theme ships with a light and a dark variant.

<table>
  <tr><th>Dark</th><th>Light</th></tr>
  <tr>
    <td colspan="2"><b>Slate</b></td>
  </tr>
  <tr>
    <td><img src="images/theme-slate-dark.png" alt="Slate (dark)"></td>
    <td><img src="images/theme-slate-light.png" alt="Slate (light)"></td>
  </tr>
  <tr>
    <td colspan="2"><b>Nous</b></td>
  </tr>
  <tr>
    <td><img src="images/theme-nous-dark.png" alt="Nous (dark)"></td>
    <td><img src="images/theme-nous-light.png" alt="Nous (light)"></td>
  </tr>
  <tr>
    <td colspan="2"><b>Midnight</b></td>
  </tr>
  <tr>
    <td><img src="images/theme-midnight-dark.png" alt="Midnight (dark)"></td>
    <td><img src="images/theme-midnight-light.png" alt="Midnight (light)"></td>
  </tr>
  <tr>
    <td colspan="2"><b>Ember</b></td>
  </tr>
  <tr>
    <td><img src="images/theme-ember-dark.png" alt="Ember (dark)"></td>
    <td><img src="images/theme-ember-light.png" alt="Ember (light)"></td>
  </tr>
  <tr>
    <td colspan="2"><b>Mono</b></td>
  </tr>
  <tr>
    <td><img src="images/theme-mono-dark.png" alt="Mono (dark)"></td>
    <td><img src="images/theme-mono-light.png" alt="Mono (light)"></td>
  </tr>
  <tr>
    <td colspan="2"><b>Cyberpunk</b></td>
  </tr>
  <tr>
    <td><img src="images/theme-cyberpunk-dark.png" alt="Cyberpunk (dark)"></td>
    <td><img src="images/theme-cyberpunk-light.png" alt="Cyberpunk (light)"></td>
  </tr>
</table>

## Settings

Open settings from the titlebar cog. It's a native, fully themed modal — a dim
backdrop, a compact single-column panel, and a custom thin scrollbar — not a stock
`Settings` scene, so it recolors with the rest of the app and is easy to extend:
add a row to the panel in `SettingsModal.swift`.

The **Appearance** section drives the whole look:

- **Light / Dark / System** — a segmented mode control layered on top of the theme.
- **Theme picker** — a searchable grid where every theme is a live mini-mockup
  card; the selected one carries an accent border.
- **Card Opacity** and **Card Blur** — sliders that tune the glass card and its
  frosted backdrop in real time.

Every choice persists to `UserDefaults` and is restored on the next launch.

| Dark | Light |
|---|---|
| ![Settings — Appearance in the Midnight dark theme](images/settings-dark.png) | ![Settings — Appearance in the Slate light theme](images/settings-light.png) |

## Install

Download the latest **`LiquidGlassDemo.dmg`** from the
[Releases](https://github.com/SohrabZ/swiftui-macos-app/releases) page, open it, and
drag the app to Applications. It's signed, notarized, and updates itself via
[Sparkle](https://sparkle-project.org) — new versions arrive automatically, or check
manually from **LiquidGlassDemo ▸ Check for Updates…**. Maintainers: see
[RELEASE.md](RELEASE.md) for cutting a release.

## Requirements

- **macOS 15+** — uses `pointerStyle`, `onScrollGeometryChange`, and `ScrollPosition`;
  on macOS 26 the hero card upgrades to the real `glassEffect` (gated with
  `#available`, blur-mask fallback below).
- **Swift 6** (Xcode 16+). Check with `swift --version`.

## Build & run

```bash
swift run                 # launch the app window
swift build -c release    # release build
```

To quit, use ⌘Q — closing the window keeps the app running (standard macOS behavior).

## Testing & verifying

```bash
swift test                     # swift-testing suites (hover, mesh, opacity, theme, wiring)
scripts/verify.sh              # build → test → render a PNG snapshot → report
scripts/verify.sh --no-visual  # build + test only
```

`verify.sh` renders a snapshot in-process with `ImageRenderer` — no window and no
Screen Recording permission — which makes it a deterministic visual check for CI.
Render one directly, and pick a theme and appearance:

```bash
BIN="$(swift build --show-bin-path)/LiquidGlassDemo"
"$BIN" --snapshot out.png --size 1180x760 --appearance dark --theme cyberpunk
```

> **Snapshot caveats:** `ImageRenderer` can't capture live AppKit controls, the
> real material blur, `NSWindow` transparency, or the settings modal — those only
> appear in the running app. The `--appearance`/`--theme` flags drive the palette so
> snapshots still vary by theme and light/dark.

## Project structure

| Path | Purpose |
|------|---------|
| [LiquidGlassDemoApp.swift](Sources/LiquidGlassDemo/LiquidGlassDemoApp.swift) | `@main` entry; windowed app, `--snapshot`/`--icon` render modes, `AppDelegate` (Dock icon, activation, window lifecycle) |
| [ContentView.swift](Sources/LiquidGlassDemo/ContentView.swift) | Three-column shell, header, and window configuration |
| [HeroCard.swift](Sources/LiquidGlassDemo/HeroCard.swift) | The glass hero card — native `glassEffect` on macOS 26, tinted fallback below |
| [Sidebars.swift](Sources/LiquidGlassDemo/Sidebars.swift) | Translucent side columns: theme quick-switch list, inspector, resize dividers |
| [SettingsModal.swift](Sources/LiquidGlassDemo/SettingsModal.swift) · [ThemePicker.swift](Sources/LiquidGlassDemo/ThemePicker.swift) | Settings modal and the Appearance/theme UI |
| [HeaderAccessory.swift](Sources/LiquidGlassDemo/HeaderAccessory.swift) · [IconButton.swift](Sources/LiquidGlassDemo/IconButton.swift) | Titlebar accessory buttons |
| [Theme.swift](Sources/LiquidGlassDemo/Theme.swift) | `ThemeStore` (`@Observable`) and every palette |
| [DesignSystem.swift](Sources/LiquidGlassDemo/DesignSystem.swift) | `Radius`, `Layout`, `Typography`, `Prefs` tokens + `themedBorder` |
| [TransparencyModel.swift](Sources/LiquidGlassDemo/TransparencyModel.swift) · [UIState.swift](Sources/LiquidGlassDemo/UIState.swift) | `@Observable`, persisted state |
| [LiquidGlassModel.swift](Sources/LiquidGlassDemo/LiquidGlassModel.swift) | Testable value types — card content, hover, `OpacityControl`, mesh backdrop |
| [WindowConfigurator.swift](Sources/LiquidGlassDemo/WindowConfigurator.swift) · [PatternBackground.swift](Sources/LiquidGlassDemo/PatternBackground.swift) · [ScrollableContent.swift](Sources/LiquidGlassDemo/ScrollableContent.swift) · [AppIcon.swift](Sources/LiquidGlassDemo/AppIcon.swift) | `NSWindow` bridge, grid, custom scrollbar, Dock icon |
| [Tests/](Tests/LiquidGlassDemoTests/) | swift-testing suites, one per subject |

**State & reactivity.** `ThemeStore`, `UIState`, and `TransparencyModel` are
`@Observable` classes owned by `ContentView` and injected through the environment,
so any view that reads them re-renders when they change — switching a theme recolors
the app with no manual refresh. Values persist via `UserDefaults` (keys in `Prefs`).
SwiftUI can't set window-level transparency or appearance directly, so
[WindowConfigurator](Sources/LiquidGlassDemo/WindowConfigurator.swift) bridges to the
`NSWindow`.

## Make it your own

Starting a new app from this template:

- **Rename** the executable and package in [Package.swift](Package.swift), then
  update the product name in `app.yml` / the release scripts.
- **Retheme** by editing the two palette tables (`ThemeStore.palettes` and
  `ThemeSwatch.all`) — keep them in sync; they share `ThemeID`.
- **Retoken** sizes, radii, fonts, and defaults keys in
  [DesignSystem.swift](Sources/LiquidGlassDemo/DesignSystem.swift) instead of
  inlining values.
- **Extend settings** by adding a row to the panel in
  [SettingsModal.swift](Sources/LiquidGlassDemo/SettingsModal.swift).
- **Swap the content** — replace the demo glass card in
  [HeroCard.swift](Sources/LiquidGlassDemo/HeroCard.swift) with your own
  main view; the shell, theming, and settings stay.

## License

MIT — see [LICENSE](LICENSE).
