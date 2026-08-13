import AppKit
import Testing
@testable import SoundAnchor

@Test @MainActor func statusBarIconUsesFullSizeTemplateCanvas() {
    let image = StatusBarIconFactory.makeImage()

    #expect(image.size.width == 16)
    #expect(image.size.height == 16)
    #expect(image.isTemplate)
    #expect(StatusBarIconFactory.imageScaling == .scaleProportionallyDown)
}

@Test @MainActor func statusBarButtonDoesNotUpscaleIcon() {
    let button = NSStatusBarButton(frame: NSRect(x: 0, y: 0, width: 24, height: 24))
    StatusBarIconFactory.configure(button: button)

    let cell = button.cell as! NSButtonCell
    let imageRect = cell.imageRect(forBounds: button.bounds)

    #expect(button.imageScaling == .scaleProportionallyDown)
    #expect(imageRect.width == 16)
    #expect(imageRect.height == 16)
}
