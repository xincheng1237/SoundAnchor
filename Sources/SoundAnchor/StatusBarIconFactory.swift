import AppKit

enum StatusBarIconFactory {
    static let imageSize = NSSize(width: 16, height: 16)
    static let imageScaling: NSImageScaling = .scaleProportionallyDown
    private static let drawingScale = 16.0 / 19.0

    static func configure(button: NSButton) {
        button.imagePosition = .imageOnly
        button.imageScaling = imageScaling
        button.image = makeImage()
        button.title = ""
        button.attributedTitle = NSAttributedString(string: "")
    }

    static func makeImage() -> NSImage {
        let image = NSImage(size: imageSize, flipped: false) { _ in
            NSGraphicsContext.saveGraphicsState()
            let transform = NSAffineTransform()
            transform.scale(by: drawingScale)
            transform.concat()
            defer { NSGraphicsContext.restoreGraphicsState() }

            NSColor.black.setStroke()

            let outerCircle = NSBezierPath(
                ovalIn: NSRect(x: 0.8, y: 0.8, width: 17.4, height: 17.4)
            )
            outerCircle.lineWidth = 1.65
            outerCircle.stroke()

            let anchorRing = NSBezierPath(
                ovalIn: NSRect(x: 7.9, y: 12.5, width: 3.2, height: 3.2)
            )
            anchorRing.lineWidth = 1.55
            anchorRing.stroke()

            let stemAndCrossbar = NSBezierPath()
            stemAndCrossbar.lineWidth = 1.65
            stemAndCrossbar.lineCapStyle = .round
            stemAndCrossbar.move(to: NSPoint(x: 9.5, y: 4.0))
            stemAndCrossbar.line(to: NSPoint(x: 9.5, y: 12.5))
            stemAndCrossbar.move(to: NSPoint(x: 6.6, y: 9.7))
            stemAndCrossbar.line(to: NSPoint(x: 12.4, y: 9.7))
            stemAndCrossbar.stroke()

            let arms = NSBezierPath()
            arms.lineWidth = 1.75
            arms.lineCapStyle = .round
            arms.lineJoinStyle = .round
            arms.move(to: NSPoint(x: 4.8, y: 6.7))
            arms.curve(
                to: NSPoint(x: 9.5, y: 3.2),
                controlPoint1: NSPoint(x: 5.2, y: 4.1),
                controlPoint2: NSPoint(x: 7.2, y: 3.2)
            )
            arms.curve(
                to: NSPoint(x: 14.2, y: 6.7),
                controlPoint1: NSPoint(x: 11.8, y: 3.2),
                controlPoint2: NSPoint(x: 13.8, y: 4.1)
            )
            arms.stroke()

            let leftFluke = NSBezierPath()
            leftFluke.lineWidth = 1.75
            leftFluke.lineCapStyle = .round
            leftFluke.lineJoinStyle = .round
            leftFluke.move(to: NSPoint(x: 4.8, y: 6.7))
            leftFluke.line(to: NSPoint(x: 4.7, y: 5.2))
            leftFluke.move(to: NSPoint(x: 4.8, y: 6.7))
            leftFluke.line(to: NSPoint(x: 6.2, y: 6.2))
            leftFluke.stroke()

            let rightFluke = NSBezierPath()
            rightFluke.lineWidth = 1.75
            rightFluke.lineCapStyle = .round
            rightFluke.lineJoinStyle = .round
            rightFluke.move(to: NSPoint(x: 14.2, y: 6.7))
            rightFluke.line(to: NSPoint(x: 14.3, y: 5.2))
            rightFluke.move(to: NSPoint(x: 14.2, y: 6.7))
            rightFluke.line(to: NSPoint(x: 12.8, y: 6.2))
            rightFluke.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }
}
