import AppKit

private enum DDCError: Error, CustomStringConvertible {
    case helperMissing
    case commandFailed(String)
    case invalidValue(String)

    var description: String {
        switch self {
        case .helperMissing:
            return "m1ddc is not installed"
        case .commandFailed(let message):
            return message.isEmpty ? "DDC command failed" : message
        case .invalidValue(let value):
            return "Unexpected value: \(value)"
        }
    }
}

private final class DDCClient {
    private let helperCandidates = [
        "/opt/homebrew/bin/m1ddc",
        "/usr/local/bin/m1ddc"
    ]

    private var helperPath: String? {
        helperCandidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func displayName() throws -> String {
        let output = try run(["display", "list"])
        guard let firstLine = output.split(separator: "\n").first else {
            return "External display"
        }

        if let start = firstLine.firstIndex(of: "]") {
            let name = String(firstLine[firstLine.index(after: start)...])
                .trimmingCharacters(in: .whitespaces)
            return name.components(separatedBy: " (").first ?? name
        }

        return String(firstLine).trimmingCharacters(in: .whitespaces)
    }

    func volume() throws -> Int {
        let output = try run(["display", "1", "get", "volume"])
        guard let value = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw DDCError.invalidValue(output)
        }
        return max(0, min(100, value))
    }

    func setVolume(_ value: Int) throws {
        _ = try run(["display", "1", "set", "volume", "\(max(0, min(100, value)))"])
    }

    private func run(_ arguments: [String]) throws -> String {
        guard let helperPath else { throw DDCError.helperMissing }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: helperPath)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw DDCError.commandFailed(error.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return output
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let client = DDCClient()
    private let queue = DispatchQueue(label: "knob.menu.ddc", qos: .userInitiated)
    private let menu = NSMenu()
    private let titleItem = NSMenuItem(title: "Monitor Volume", action: nil, keyEquivalent: "")
    private let sliderItem = NSMenuItem()
    private let controlsItem = NSMenuItem()
    private let valueItem = NSMenuItem(title: "Volume: --", action: nil, keyEquivalent: "")
    private let statusItemText = NSMenuItem(title: "Starting...", action: nil, keyEquivalent: "")
    private let slider = NSSlider(value: 0, minValue: 0, maxValue: 100, target: nil, action: nil)
    private var lastNonZeroVolume = 20
    private var pendingSet: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "display", accessibilityDescription: "Monitor volume")
            image?.isTemplate = true
            button.image = image
            button.title = " --"
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        }
        statusItem.menu = menu
        menu.delegate = self
        configureMenu()
        refresh()
    }

    private func configureMenu() {
        menu.minimumWidth = 230
        titleItem.isEnabled = false
        titleItem.attributedTitle = NSAttributedString(
            string: titleItem.title,
            attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold)]
        )
        menu.addItem(titleItem)

        let sliderContainer = NSView(frame: NSRect(x: 0, y: 0, width: 230, height: 34))
        slider.frame = NSRect(x: 12, y: 6, width: 206, height: 22)
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderChanged)
        sliderContainer.addSubview(slider)
        sliderItem.view = sliderContainer
        menu.addItem(sliderItem)

        valueItem.isEnabled = false
        menu.addItem(valueItem)

        controlsItem.view = makeControlsView()
        menu.addItem(controlsItem)
        menu.addItem(.separator())
        statusItemText.isEnabled = false
        menu.addItem(statusItemText)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items where item.action != nil {
            item.target = self
        }
    }

    private func makeControlsView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 230, height: 42))
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let buttons: [(String, String, Selector)] = [
            ("speaker.slash.fill", "Mute", #selector(toggleMute)),
            ("speaker.minus.fill", "Volume Down", #selector(stepDown)),
            ("speaker.plus.fill", "Volume Up", #selector(stepUp)),
            ("arrow.clockwise", "Refresh", #selector(refresh))
        ]

        for buttonSpec in buttons {
            let button = NSButton(title: "", target: self, action: buttonSpec.2)
            button.image = NSImage(systemSymbolName: buttonSpec.0, accessibilityDescription: buttonSpec.1)
            button.imagePosition = .imageOnly
            button.bezelStyle = .rounded
            button.controlSize = .large
            button.toolTip = buttonSpec.1
            stack.addArrangedSubview(button)
            button.heightAnchor.constraint(equalToConstant: 28).isActive = true
        }

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
        ])

        return view
    }

    @objc private func sliderChanged() {
        let value = Int(slider.integerValue)
        applyValue(value)
        pendingSet?.cancel()

        let work = DispatchWorkItem { [weak self] in
            self?.setVolume(value, confirmAfterSet: false)
        }
        pendingSet = work
        queue.asyncAfter(deadline: .now() + 0.08, execute: work)
    }

    @objc private func toggleMute() {
        let current = Int(slider.integerValue)
        setVolume(current == 0 ? lastNonZeroVolume : 0)
    }

    @objc private func stepDown() {
        setVolume(Int(slider.integerValue) - 5)
    }

    @objc private func stepUp() {
        setVolume(Int(slider.integerValue) + 5)
    }

    @objc private func refresh() {
        statusItemText.title = "Refreshing..."
        queue.async { [weak self] in
            guard let self else { return }
            do {
                let name = try self.client.displayName()
                let value = try self.client.volume()
                DispatchQueue.main.async {
                    self.titleItem.title = name
                    self.titleItem.attributedTitle = NSAttributedString(
                        string: name,
                        attributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold)]
                    )
                    self.applyValue(value)
                    self.statusItemText.title = "Ready"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusItemText.title = "\(error)"
                }
            }
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func setVolume(_ rawValue: Int, confirmAfterSet: Bool = true) {
        let value = max(0, min(100, rawValue))
        DispatchQueue.main.async {
            self.applyValue(value)
        }

        queue.async { [weak self] in
            guard let self else { return }
            do {
                try self.client.setVolume(value)
                let confirmed = confirmAfterSet ? try self.client.volume() : value
                DispatchQueue.main.async {
                    self.applyValue(confirmed)
                    self.statusItemText.title = "Ready"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusItemText.title = "\(error)"
                }
            }
        }
    }

    private func applyValue(_ value: Int) {
        let clamped = max(0, min(100, value))
        slider.integerValue = clamped
        valueItem.title = "Volume: \(clamped)"
        statusItem.button?.title = " \(clamped)"
        if clamped > 0 {
            lastNonZeroVolume = clamped
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
