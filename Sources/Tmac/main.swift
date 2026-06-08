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

// Edit menu so ⌘V / ⌘C / ⌘X / ⌘A route via the responder chain to the
// SwiftTerm view (which implements paste:/copy:/cut:/selectAll:).
let editMenuItem = NSMenuItem()
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Cut",        action: Selector(("cut:")),       keyEquivalent: "x")
editMenu.addItem(withTitle: "Copy",       action: Selector(("copy:")),      keyEquivalent: "c")
editMenu.addItem(withTitle: "Paste",      action: Selector(("paste:")),     keyEquivalent: "v")
editMenu.addItem(NSMenuItem.separator())
editMenu.addItem(withTitle: "Select All", action: Selector(("selectAll:")), keyEquivalent: "a")
editMenuItem.submenu = editMenu
mainMenu.addItem(editMenuItem)


app.activate(ignoringOtherApps: true)
app.run()
