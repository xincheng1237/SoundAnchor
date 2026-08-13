import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let preferences = Preferences()
    private lazy var audioController = CoreAudioController(preferences: preferences)
    private lazy var settingsController = SettingsWindowController(
        preferences: preferences,
        audioController: audioController,
        onMenuBarVisibilityChange: { [weak self] isVisible in
            self?.setMenuBarItemVisible(isVisible)
        }
    )
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var snapshot = AudioSnapshot.starting
    private var inputDevices: [AudioDevice] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureFirstRunLoginItem()

        audioController.onStateChange = { [weak self] snapshot, devices in
            guard let self else { return }
            self.snapshot = snapshot
            self.inputDevices = devices
            self.updateStatusIcon()
            self.settingsController.update(snapshot: snapshot, devices: devices)
        }
        audioController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        audioController.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsController.present()
        return true
    }

    private func configureStatusItem() {
        menu.delegate = self
        statusItem.menu = menu
        if let button = statusItem.button {
            button.toolTip = "声锚 SoundAnchor"
            StatusBarIconFactory.configure(button: button)
        }
        updateStatusIcon()
        statusItem.isVisible = preferences.showsMenuBarItem
    }

    private func configureFirstRunLoginItem() {
        guard !preferences.didConfigureLoginItem,
              Bundle.main.bundleURL.pathExtension == "app" else { return }
        do {
            try LoginItemManager.setEnabled(true)
            preferences.didConfigureLoginItem = true
        } catch {
            // The app remains fully usable when login item setup fails.
        }
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        StatusBarIconFactory.configure(button: button)
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let status = NSMenuItem(title: SettingsWindowController.statusText(for: snapshot), action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let protection = NSMenuItem(title: "启用音质保护", action: #selector(toggleProtection), keyEquivalent: "")
        protection.target = self
        protection.state = preferences.isEnabled ? .on : .off
        menu.addItem(protection)

        let bluetoothOnly = NSMenuItem(title: "仅在蓝牙输出时保护", action: #selector(toggleBluetoothOnly), keyEquivalent: "")
        bluetoothOnly.target = self
        bluetoothOnly.state = preferences.protectsOnlyWithBluetoothOutput ? .on : .off
        menu.addItem(bluetoothOnly)

        let inputItem = NSMenuItem(title: "锚定的输入设备", action: nil, keyEquivalent: "")
        let inputMenu = NSMenu()
        for device in inputDevices {
            let item = NSMenuItem(title: device.name, action: #selector(selectInput(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = device.uid
            item.state = device.uid == preferences.anchoredInputUID ? .on : .off
            inputMenu.addItem(item)
        }
        if inputDevices.isEmpty {
            let item = NSMenuItem(title: "未找到输入设备", action: nil, keyEquivalent: "")
            item.isEnabled = false
            inputMenu.addItem(item)
        }
        inputItem.submenu = inputMenu
        menu.addItem(inputItem)

        menu.addItem(.separator())

        let repair = NSMenuItem(title: "立即修复", action: #selector(repairNow), keyEquivalent: "r")
        repair.target = self
        menu.addItem(repair)

        let settings = NSMenuItem(title: "设置…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let login = NSMenuItem(title: "登录时自动运行", action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(login)

        let menuBarItem = NSMenuItem(title: "在菜单栏中显示", action: #selector(toggleMenuBarItem), keyEquivalent: "")
        menuBarItem.target = self
        menuBarItem.state = preferences.showsMenuBarItem ? .on : .off
        menu.addItem(menuBarItem)

        menu.addItem(.separator())

        let about = NSMenuItem(title: "关于声锚", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "退出声锚", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func toggleProtection(_ sender: NSMenuItem) {
        audioController.setProtectionEnabled(!preferences.isEnabled)
    }

    @objc private func toggleBluetoothOnly(_ sender: NSMenuItem) {
        audioController.setBluetoothOnly(!preferences.protectsOnlyWithBluetoothOutput)
    }

    @objc private func selectInput(_ sender: NSMenuItem) {
        guard let uid = sender.representedObject as? String else { return }
        audioController.setAnchoredInput(uid: uid)
    }

    @objc private func repairNow() {
        audioController.repairNow()
    }

    @objc private func openSettings() {
        settingsController.present()
    }

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        do {
            try LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "无法更改登录启动设置"
            alert.runModal()
        }
    }

    @objc private func toggleMenuBarItem(_ sender: NSMenuItem) {
        setMenuBarItemVisible(!preferences.showsMenuBarItem)
    }

    private func setMenuBarItemVisible(_ isVisible: Bool) {
        preferences.showsMenuBarItem = isVisible
        statusItem.isVisible = isVisible
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "声锚 SoundAnchor"
        alert.informativeText = "让蓝牙耳机保持高音质。\n\n事件驱动，无轮询、无遥测、无网络请求。"
        alert.addButton(withTitle: "好")
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
