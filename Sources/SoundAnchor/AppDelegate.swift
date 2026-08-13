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
            button.toolTip = L10n.text("app.name")
            StatusBarIconFactory.configure(button: button)
        }
        updateStatusIcon()
        statusItem.isVisible = preferences.showsMenuBarItem
    }

    private func configureFirstRunLoginItem() {
        guard !preferences.didConfigureLoginItem,
              Bundle.main.bundleIdentifier == LoginItemManager.label,
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

        let protection = NSMenuItem(title: L10n.text("protection.enable"), action: #selector(toggleProtection), keyEquivalent: "")
        protection.target = self
        protection.state = preferences.isEnabled ? .on : .off
        menu.addItem(protection)

        let bluetoothOnly = NSMenuItem(title: L10n.text("protection.bluetooth_only.menu"), action: #selector(toggleBluetoothOnly), keyEquivalent: "")
        bluetoothOnly.target = self
        bluetoothOnly.state = preferences.protectsOnlyWithBluetoothOutput ? .on : .off
        menu.addItem(bluetoothOnly)

        let inputItem = NSMenuItem(title: L10n.text("input.anchored"), action: nil, keyEquivalent: "")
        let inputMenu = NSMenu()
        for device in inputDevices {
            let item = NSMenuItem(title: device.name, action: #selector(selectInput(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = device.uid
            item.state = device.uid == preferences.anchoredInputUID ? .on : .off
            inputMenu.addItem(item)
        }
        if inputDevices.isEmpty {
            let item = NSMenuItem(title: L10n.text("input.none_found"), action: nil, keyEquivalent: "")
            item.isEnabled = false
            inputMenu.addItem(item)
        }
        inputItem.submenu = inputMenu
        menu.addItem(inputItem)

        menu.addItem(.separator())

        let repair = NSMenuItem(title: L10n.text("action.repair_now"), action: #selector(repairNow), keyEquivalent: "r")
        repair.target = self
        menu.addItem(repair)

        let settings = NSMenuItem(title: L10n.text("action.settings"), action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let login = NSMenuItem(title: L10n.text("launch_at_login"), action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(login)

        let menuBarItem = NSMenuItem(title: L10n.text("menu_bar.show"), action: #selector(toggleMenuBarItem), keyEquivalent: "")
        menuBarItem.target = self
        menuBarItem.state = preferences.showsMenuBarItem ? .on : .off
        menu.addItem(menuBarItem)

        menu.addItem(.separator())

        let about = NSMenuItem(title: L10n.text("action.about"), action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: L10n.text("action.quit"), action: #selector(quitApp), keyEquivalent: "q")
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
            alert.messageText = L10n.text("error.launch_at_login")
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
        alert.messageText = L10n.text("app.name")
        alert.informativeText = L10n.text("about.message")
        alert.addButton(withTitle: L10n.text("action.ok"))
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
