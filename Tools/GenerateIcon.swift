import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = root.appendingPathComponent("Resources/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawIcon(points: CGFloat, scale: CGFloat, output: URL) throws {
    let pixels = Int(points * scale)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "Icon", code: 1)
    }
    rep.size = NSSize(width: points, height: points)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    defer { NSGraphicsContext.restoreGraphicsState() }

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: points, height: points).fill()

    let bg = NSBezierPath(roundedRect: NSRect(x: points * 0.08, y: points * 0.08, width: points * 0.84, height: points * 0.84), xRadius: points * 0.2, yRadius: points * 0.2)
    NSColor(calibratedRed: 0.10, green: 0.46, blue: 0.72, alpha: 1).setFill()
    bg.fill()

    let screenRect = NSRect(x: points * 0.20, y: points * 0.34, width: points * 0.60, height: points * 0.38)
    let screen = NSBezierPath(roundedRect: screenRect, xRadius: points * 0.055, yRadius: points * 0.055)
    screen.lineWidth = max(2, points * 0.035)
    NSColor.white.withAlphaComponent(0.16).setFill()
    screen.fill()
    NSColor.white.setStroke()
    screen.stroke()

    let stand = NSBezierPath()
    stand.lineWidth = max(2, points * 0.03)
    stand.move(to: NSPoint(x: points * 0.5, y: points * 0.34))
    stand.line(to: NSPoint(x: points * 0.5, y: points * 0.24))
    stand.move(to: NSPoint(x: points * 0.38, y: points * 0.24))
    stand.line(to: NSPoint(x: points * 0.62, y: points * 0.24))
    NSColor.white.setStroke()
    stand.stroke()

    let sound = NSBezierPath()
    sound.lineWidth = max(2, points * 0.026)
    sound.appendArc(withCenter: NSPoint(x: points * 0.62, y: points * 0.53), radius: points * 0.08, startAngle: -35, endAngle: 35)
    sound.appendArc(withCenter: NSPoint(x: points * 0.62, y: points * 0.53), radius: points * 0.14, startAngle: -35, endAngle: 35)
    sound.stroke()

    let text = "45"
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: points * 0.18, weight: .bold),
        .foregroundColor: NSColor.white
    ]
    let textSize = text.size(withAttributes: attrs)
    text.draw(
        at: NSPoint(x: screenRect.midX - textSize.width / 2, y: screenRect.midY - textSize.height / 2),
        withAttributes: attrs
    )

    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Icon", code: 2)
    }
    try png.write(to: output)
}

let specs: [(CGFloat, CGFloat, String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png")
]

for spec in specs {
    try drawIcon(points: spec.0, scale: spec.1, output: iconset.appendingPathComponent(spec.2))
}
