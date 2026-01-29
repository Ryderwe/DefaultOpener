import SwiftUI
import AppKit

@main
struct DefaultOpenerApp: App {
    init() {
        // SwiftPM 可执行文件在 Finder/Terminal 启动时有时不会自动变成“前台 GUI App”，
        // 导致窗口不显示（或显示但不激活/不在 Dock）。
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 980, height: 620)
    }
}
