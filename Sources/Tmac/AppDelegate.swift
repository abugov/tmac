import AppKit
import SwiftTerm

/// Schema of ~/.config/tmac/config.json — what command the wrapper runs.
private struct LaunchConfig: Codable {
    let command: String
    let args: [String]?
}

final class AppDelegate: NSObject, NSApplicationDelegate, LocalProcessTerminalViewDelegate {
    private var window: NSWindow!
    private var terminal: LocalProcessTerminalView!

    private static let configPath: String =
        ("~/.config/tmac/config.json" as NSString).expandingTildeInPath

    func applicationDidFinishLaunching(_ notification: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 1100, height: 700)

        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tmac"
        window.center()
        window.setFrameAutosaveName("TmacMainWindow")

        terminal = LocalProcessTerminalView(frame: frame)
        terminal.processDelegate = self
        terminal.autoresizingMask = [.width, .height]
        terminal.nativeForegroundColor = NSColor(white: 0.92, alpha: 1.0)
        terminal.nativeBackgroundColor = NSColor(white: 0.08, alpha: 1.0)
        window.contentView = terminal
        window.makeFirstResponder(terminal)
        window.makeKeyAndOrderFront(nil)

        startConfiguredCommand()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: - Launch

    private func startConfiguredCommand() {
        let cmd: String
        let args: [String]

        if FileManager.default.fileExists(atPath: AppDelegate.configPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: AppDelegate.configPath))
                let cfg = try JSONDecoder().decode(LaunchConfig.self, from: data)
                cmd = cfg.command
                args = cfg.args ?? []
            } catch {
                feedError("""
                Failed to parse \(AppDelegate.configPath):
                  \(error.localizedDescription)
                """)
                return
            }
        } else {
            // No config file — fall back to the user's shell so the window is
            // still useful as a plain terminal until they run `make setup`.
            cmd = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
            args = []
        }

        let resolvedCmd = resolveCommand(expandTilde(cmd))
        let resolvedArgs = args.map(expandTilde)

        guard FileManager.default.isExecutableFile(atPath: resolvedCmd) else {
            feedError("""
            Command not found or not executable:
              \(resolvedCmd)

            If you haven't set up Tmac yet, run from the project root:
              make setup
            """)
            return
        }

        // Inherit env, augment PATH for Finder-launched processes, set TERM.
        var env = ProcessInfo.processInfo.environment
        let extraPath = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        var pathParts = (env["PATH"] ?? "").split(separator: ":").map(String.init)
        for p in extraPath where !pathParts.contains(p) { pathParts.append(p) }
        env["PATH"] = pathParts.joined(separator: ":")
        env["TERM"] = "xterm-256color"
        let envArr = env.map { "\($0.key)=\($0.value)" }

        FileManager.default.changeCurrentDirectoryPath(
            FileManager.default.homeDirectoryForCurrentUser.path
        )

        terminal.startProcess(
            executable: resolvedCmd,
            args: resolvedArgs,
            environment: envArr,
            execName: (resolvedCmd as NSString).lastPathComponent
        )
    }

    private func expandTilde(_ path: String) -> String {
        return (path as NSString).expandingTildeInPath
    }

    /// If `cmd` already contains a `/`, use it as-is. Otherwise look it up in
    /// PATH (augmented with common Homebrew/system locations).
    private func resolveCommand(_ cmd: String) -> String {
        if cmd.contains("/") { return cmd }

        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let extraPath = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        var dirs = pathEnv.split(separator: ":").map(String.init)
        for p in extraPath where !dirs.contains(p) { dirs.append(p) }

        for dir in dirs {
            let candidate = (dir as NSString).appendingPathComponent(cmd)
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return cmd  // let the isExecutableFile check above produce a clear error
    }

    private func feedError(_ msg: String) {
        let crlf = msg.replacingOccurrences(of: "\n", with: "\r\n")
        terminal.feed(text: "\r\n\u{1b}[31m\(crlf)\u{1b}[0m\r\n")
    }

    // MARK: - LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        window.title = title.isEmpty ? "Tmac" : title
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        let code = exitCode.map { String($0) } ?? "unknown"
        if let term = source as? LocalProcessTerminalView {
            term.feed(text: "\r\n\u{1b}[33m[process exited with status \(code) — close window to quit]\u{1b}[0m\r\n")
        }
    }
}
