import SwiftUI
import AppKit

/// Focused-value keys that let menu-bar commands reach the main window's state
/// (owned by `ContentView`, below the commands' scene context). `ContentView`
/// publishes them via `.focusedSceneValue`; `ShellCommands` reads them.
extension FocusedValues {
    @Entry var uiState: UIState?
    @Entry var transparencyModel: TransparencyModel?
    @Entry var accessibilitySettings: AccessibilitySettings?
}

/// The app's menu-bar commands beyond the system defaults: About, updates,
/// settings, sidebar/inspector toggles, theme switching, and diagnostics.
/// Window-owned state arrives via `@FocusedValue`; app-level state is passed in.
struct ShellCommands: Commands {
    let theme: ThemeStore
    let updater: Updater

    @FocusedValue(\.uiState) private var ui: UIState?
    @FocusedValue(\.transparencyModel) private var model: TransparencyModel?
    @FocusedValue(\.accessibilitySettings) private var a11y: AccessibilitySettings?
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // Custom themed About panel in place of the stock AppKit one.
        CommandGroup(replacing: .appInfo) {
            Button("About \(AppInfo.name)") {
                openWindow(id: "about")
                NSApp.activate(ignoringOtherApps: true)
            }
        }

        // Standard "Check for Updates…" item under the app menu. Disabled (and
        // inert) unless running as a configured, signed bundle — see Updater.
        CommandGroup(after: .appInfo) {
            Button("Check for Updates…") { updater.checkForUpdates() }
                .disabled(!updater.canCheckForUpdates)
        }

        // ⌘, opens the custom settings modal (there's no `Settings` scene — the
        // modal is themed and part of the shell).
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") { ui?.showSettings = true }
                .keyboardShortcut(",", modifiers: .command)
                .disabled(ui == nil)
        }

        CommandGroup(after: .sidebar) {
            Button(ui?.leftSidebarVisible == true ? "Hide Sidebar" : "Show Sidebar") {
                ui?.leftSidebarVisible.toggle()
            }
            .keyboardShortcut("s", modifiers: [.control, .command])
            .disabled(ui == nil)

            Button(ui?.rightSidebarVisible == true ? "Hide Inspector" : "Show Inspector") {
                ui?.rightSidebarVisible.toggle()
            }
            .keyboardShortcut("i", modifiers: [.option, .command])
            .disabled(ui == nil)
        }

        // Theme quick-switch, ⌘1…⌘6 in `ThemeID` declaration order. Toggles
        // render the current theme with a checkmark; turning one on selects it
        // (turning the active one off is ignored, so it stays checked).
        CommandMenu("Themes") {
            ForEach(ThemeSwatch.all) { swatch in
                Toggle(swatch.name, isOn: Binding(
                    get: { theme.id == swatch.themeID },
                    set: { if $0 { theme.id = swatch.themeID } }
                ))
                .keyboardShortcut(themeShortcut(swatch.themeID))
            }
        }

        CommandGroup(after: .help) {
            Button("Copy Debug Info") {
                if let ui, let model {
                    DebugInfo.copyToPasteboard(theme: theme, ui: ui, model: model,
                                               sparkle: updater.canCheckForUpdates)
                }
            }
            .disabled(ui == nil || model == nil)
        }

        #if DEBUG
        // Development-only shortcuts — compiled out of release builds. The reset
        // writes each model's defaults back through its didSet, so UserDefaults
        // is cleared along with the live state.
        CommandMenu("Debug") {
            Button("Reset All Preferences") { resetPreferences() }
                .disabled(ui == nil || model == nil)
            Button("Reset Onboarding") {
                ui?.hasCompletedOnboarding = false
                ui?.showOnboarding = true
            }
            .disabled(ui == nil)
            Divider()
            Button("Force Light") { ui?.mode = .light }.disabled(ui == nil)
            Button("Force Dark") { ui?.mode = .dark }.disabled(ui == nil)
            Button("Force System") { ui?.mode = .system }.disabled(ui == nil)
        }
        #endif
    }

    #if DEBUG
    private func resetPreferences() {
        theme.id = .slate
        if let ui {
            ui.mode = .dark
            ui.leftSidebarVisible = true
            ui.rightSidebarVisible = false
            ui.leftSidebarWidth = Layout.leftSidebarWidth
            ui.rightSidebarWidth = Layout.rightSidebarWidth
            ui.showSettings = false
            // Back to the first-run state: the welcome panel returns next launch.
            ui.hasCompletedOnboarding = false
        }
        if let model {
            model.cardOpacity = OpacityControl.card.defaultValue
            model.blur = TransparencyModel.defaultBlur
        }
        if let a11y {
            a11y.reduceMotion = false
            a11y.reduceTransparency = false
            a11y.increaseContrast = false
        }
    }
    #endif

    /// ⌘<index+1> for the theme's position in `ThemeID.allCases` (⌘1 = first).
    private func themeShortcut(_ id: ThemeID) -> KeyboardShortcut {
        let index = ThemeID.allCases.firstIndex(of: id) ?? 0
        return KeyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
    }
}
