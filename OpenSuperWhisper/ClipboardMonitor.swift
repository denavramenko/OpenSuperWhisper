import Cocoa
import Combine

/// Polls the general pasteboard and remembers the latest text clipboard entry.
/// When: OpenSuperWhisper starts; keeps a snapshot of clipboard text so a recorded
///       Interaction can be paired with whatever the user recently copied.
/// Why: clipboard content is valuable context for interpreting a voice note.
final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published private(set) var latestText: String?

    private var lastChangeCount: Int = -1
    private var timer: Timer?

    private init() {}

    func start() {
        guard timer == nil else { return }

        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount
        latestText = pasteboard.string(forType: .string)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func currentText() -> String? {
        return latestText
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        latestText = pasteboard.string(forType: .string)
    }
}
