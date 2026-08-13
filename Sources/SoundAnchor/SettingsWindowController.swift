import AppKit

final class SettingsWindowController: NSWindowController {
    private let preferences: Preferences
    private let audioController: CoreAudioController
    private let onMenuBarVisibilityChange: (Bool) -> Void
    private let enabledCheckbox = NSButton(checkboxWithTitle: L10n.text("protection.enable"), target: nil, action: nil)
    private let bluetoothOnlyCheckbox = NSButton(checkboxWithTitle: L10n.text("protection.bluetooth_only.settings"), target: nil, action: nil)
    private let loginCheckbox = NSButton(checkboxWithTitle: L10n.text("launch_at_login"), target: nil, action: nil)
    private let menuBarCheckbox = NSButton(checkboxWithTitle: L10n.text("menu_bar.show"), target: nil, action: nil)
    private let inputPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let statusLabel = NSTextField(wrappingLabelWithString: L10n.text("status.reading"))
    private var devices: [AudioDevice] = []
    private var snapshot = AudioSnapshot.starting

    init(
        preferences: Preferences,
        audioController: CoreAudioController,
        onMenuBarVisibilityChange: @escaping (Bool) -> Void
    ) {
        self.preferences = preferences
        self.audioController = audioController
        self.onMenuBarVisibilityChange = onMenuBarVisibilityChange
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 470, height: 390),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text("settings.window_title")
        window.isReleasedWhenClosed = false
        super.init(window: window)
        configureContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        refreshControls()
        showWindow(nil)
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    func update(snapshot: AudioSnapshot, devices: [AudioDevice]) {
        self.snapshot = snapshot
        self.devices = devices
        refreshControls()
    }

    private func configureContent() {
        guard let content = window?.contentView else { return }

        let title = NSTextField(labelWithString: L10n.text("app.name"))
        title.font = .systemFont(ofSize: 24, weight: .bold)

        let subtitle = NSTextField(wrappingLabelWithString: L10n.text("settings.subtitle"))
        subtitle.textColor = .secondaryLabelColor

        let inputLabel = NSTextField(labelWithString: L10n.text("input.anchored"))
        inputLabel.font = .systemFont(ofSize: 13, weight: .medium)

        statusLabel.maximumNumberOfLines = 3
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.textColor = .secondaryLabelColor

        let repairButton = NSButton(title: L10n.text("action.repair_now"), target: self, action: #selector(repairNow))
        repairButton.bezelStyle = .rounded

        enabledCheckbox.target = self
        enabledCheckbox.action = #selector(toggleProtection)
        bluetoothOnlyCheckbox.target = self
        bluetoothOnlyCheckbox.action = #selector(toggleBluetoothOnly)
        loginCheckbox.target = self
        loginCheckbox.action = #selector(toggleLoginItem)
        menuBarCheckbox.target = self
        menuBarCheckbox.action = #selector(toggleMenuBarItem)
        inputPopup.target = self
        inputPopup.action = #selector(selectInput)

        let stack = NSStackView(views: [
            title,
            subtitle,
            NSBox.separator(),
            enabledCheckbox,
            bluetoothOnlyCheckbox,
            inputLabel,
            inputPopup,
            loginCheckbox,
            menuBarCheckbox,
            NSBox.separator(),
            statusLabel,
            repairButton
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 11
        stack.edgeInsets = NSEdgeInsets(top: 22, left: 24, bottom: 20, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false
        inputPopup.widthAnchor.constraint(equalToConstant: 310).isActive = true
        statusLabel.widthAnchor.constraint(equalToConstant: 422).isActive = true

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor)
        ])
    }

    private func refreshControls() {
        guard isWindowLoaded else { return }
        enabledCheckbox.state = preferences.isEnabled ? .on : .off
        bluetoothOnlyCheckbox.state = preferences.protectsOnlyWithBluetoothOutput ? .on : .off
        loginCheckbox.state = LoginItemManager.isEnabled ? .on : .off
        menuBarCheckbox.state = preferences.showsMenuBarItem ? .on : .off

        inputPopup.removeAllItems()
        for device in devices {
            inputPopup.addItem(withTitle: device.name)
            inputPopup.lastItem?.representedObject = device.uid
        }
        if let uid = preferences.anchoredInputUID,
           let index = devices.firstIndex(where: { $0.uid == uid }) {
            inputPopup.selectItem(at: index)
        }

        statusLabel.stringValue = Self.statusText(for: snapshot)
    }

    static func statusText(for snapshot: AudioSnapshot) -> String {
        let headline: String
        switch snapshot.protectionState {
        case .active:
            headline = L10n.text("status.active")
        case .corrected:
            headline = L10n.text("status.corrected")
        case .waitingForBluetooth:
            headline = L10n.text("status.waiting_for_bluetooth")
        case .disabled:
            headline = L10n.text("status.disabled")
        case .targetUnavailable:
            headline = L10n.text("status.target_unavailable")
        case .error(let message):
            headline = message
        }
        return L10n.format("status.summary", headline, snapshot.currentInputName, snapshot.currentOutputName)
    }

    @objc private func toggleProtection() {
        audioController.setProtectionEnabled(enabledCheckbox.state == .on)
    }

    @objc private func toggleBluetoothOnly() {
        audioController.setBluetoothOnly(bluetoothOnlyCheckbox.state == .on)
    }

    @objc private func selectInput() {
        guard let uid = inputPopup.selectedItem?.representedObject as? String else { return }
        audioController.setAnchoredInput(uid: uid)
    }

    @objc private func repairNow() {
        audioController.repairNow()
    }

    @objc private func toggleLoginItem() {
        do {
            try LoginItemManager.setEnabled(loginCheckbox.state == .on)
        } catch {
            loginCheckbox.state = LoginItemManager.isEnabled ? .on : .off
            let alert = NSAlert(error: error)
            alert.messageText = L10n.text("error.launch_at_login")
            alert.runModal()
        }
    }

    @objc private func toggleMenuBarItem() {
        onMenuBarVisibilityChange(menuBarCheckbox.state == .on)
    }
}

private extension NSBox {
    static func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }
}
