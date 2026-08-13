import AppKit

final class SettingsWindowController: NSWindowController {
    private let preferences: Preferences
    private let audioController: CoreAudioController
    private let onMenuBarVisibilityChange: (Bool) -> Void
    private let enabledCheckbox = NSButton(checkboxWithTitle: "启用音质保护", target: nil, action: nil)
    private let bluetoothOnlyCheckbox = NSButton(checkboxWithTitle: "仅在蓝牙输出设备使用时保护", target: nil, action: nil)
    private let loginCheckbox = NSButton(checkboxWithTitle: "登录时自动运行", target: nil, action: nil)
    private let menuBarCheckbox = NSButton(checkboxWithTitle: "在菜单栏中显示", target: nil, action: nil)
    private let inputPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let statusLabel = NSTextField(labelWithString: "正在读取音频状态…")
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
        window.title = "声锚设置"
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

        let title = NSTextField(labelWithString: "声锚 SoundAnchor")
        title.font = .systemFont(ofSize: 24, weight: .bold)

        let subtitle = NSTextField(wrappingLabelWithString: "防止蓝牙耳机因被选作麦克风而退回低音质通话模式。")
        subtitle.textColor = .secondaryLabelColor

        let inputLabel = NSTextField(labelWithString: "锚定的输入设备")
        inputLabel.font = .systemFont(ofSize: 13, weight: .medium)

        statusLabel.maximumNumberOfLines = 3
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.textColor = .secondaryLabelColor

        let repairButton = NSButton(title: "立即修复", target: self, action: #selector(repairNow))
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
            headline = "保护中"
        case .corrected:
            headline = "已自动修复"
        case .waitingForBluetooth:
            headline = "等待蓝牙输出"
        case .disabled:
            headline = "保护已暂停"
        case .targetUnavailable:
            headline = "找不到锚定设备"
        case .error(let message):
            headline = message
        }
        return "\(headline) · 输入：\(snapshot.currentInputName) · 输出：\(snapshot.currentOutputName)"
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
            alert.messageText = "无法更改登录启动设置"
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
