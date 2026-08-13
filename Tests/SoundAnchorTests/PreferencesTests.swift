import Foundation
import Testing
@testable import SoundAnchor

@Test func menuBarItemIsShownByDefault() {
    let suiteName = "SoundAnchorTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let preferences = Preferences(defaults: defaults)

    #expect(preferences.showsMenuBarItem)
}

@Test func hiddenMenuBarPreferencePersists() {
    let suiteName = "SoundAnchorTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let preferences = Preferences(defaults: defaults)
    preferences.showsMenuBarItem = false

    #expect(!Preferences(defaults: defaults).showsMenuBarItem)
}
