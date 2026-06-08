import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)

// Minimal menu bar so standard macOS shortcuts (Cmd+Q) are wired up.
// keyEquivalent strings get the ⌘ modifier implicitly via NSMenu.
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
let appMenu = NSMenu()
appMenu.addItem(
    withTitle: "Quit Tmac",
    action: #selector(NSApplication.terminate(_:)),
    keyEquivalent: "q"
)
appMenuItem.submenu = appMenu
mainMenu.addItem(appMenuItem)
app.mainMenu = mainMenu

app.activate(ignoringOtherApps: true)
app.run()
