import Foundation

final class Preferences {
    private enum Key {
        static let enabled = "protectionEnabled"
        static let bluetoothOnly = "protectOnlyWithBluetoothOutput"
        static let anchorUID = "anchoredInputUID"
        static let didConfigureLoginItem = "didConfigureLoginItem"
        static let showsMenuBarItem = "showsMenuBarItem"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.enabled: true,
            Key.bluetoothOnly: true,
            Key.showsMenuBarItem: true
        ])
    }

    var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    var protectsOnlyWithBluetoothOutput: Bool {
        get { defaults.bool(forKey: Key.bluetoothOnly) }
        set { defaults.set(newValue, forKey: Key.bluetoothOnly) }
    }

    var anchoredInputUID: String? {
        get { defaults.string(forKey: Key.anchorUID) }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Key.anchorUID)
            } else {
                defaults.removeObject(forKey: Key.anchorUID)
            }
        }
    }

    var didConfigureLoginItem: Bool {
        get { defaults.bool(forKey: Key.didConfigureLoginItem) }
        set { defaults.set(newValue, forKey: Key.didConfigureLoginItem) }
    }

    var showsMenuBarItem: Bool {
        get { defaults.bool(forKey: Key.showsMenuBarItem) }
        set { defaults.set(newValue, forKey: Key.showsMenuBarItem) }
    }
}
