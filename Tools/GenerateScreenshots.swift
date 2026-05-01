import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDir = root.appendingPathComponent("assets/screenshots")
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

func withBitmap(width: Int, height: Int, draw: (CGFloat, CGFloat) -> Void) throws -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width * 2,
        pixelsHigh: height * 2,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "Screenshots", code: 1)
    }
    rep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(CGFloat(width), CGFloat(height))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func write(_ rep: NSBitmapImageRep, to name: String) throws {
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Screenshots", code: 2)
    }
    try png.write(to: outputDir.appendingPathComponent(name))
}

func roundedRect(_ rect: NSRect, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

func text(_ string: String, at point: NSPoint, size: CGFloat = 13, weight: NSFont.Weight = .regular, color: NSColor = .labelColor) {
    string.draw(
        at: point,
        withAttributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
    )
}

func symbol(_ name: String, in rect: NSRect, color: NSColor = .labelColor) {
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) else { return }
    image.isTemplate = true
    NSGraphicsContext.saveGraphicsState()
    color.set()
    image.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
}

func drawMenuBarBadge(x: CGFloat, y: CGFloat) {
    symbol("display", in: NSRect(x: x, y: y + 2, width: 15, height: 15), color: .white)
    text("40", at: NSPoint(x: x + 19, y: y + 1.2), size: 12, weight: .semibold, color: .white)
}

func drawDropdown(origin: NSPoint, width: CGFloat = 260) {
    let rect = NSRect(x: origin.x, y: origin.y, width: width, height: 202)
    roundedRect(rect, radius: 12, color: NSColor(calibratedWhite: 0.08, alpha: 0.88))
    NSColor.white.withAlphaComponent(0.13).setStroke()
    let outline = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 12, yRadius: 12)
    outline.lineWidth = 1
    outline.stroke()

    text("PL3494WQ", at: NSPoint(x: origin.x + 16, y: origin.y + 172), size: 13, weight: .semibold, color: .white.withAlphaComponent(0.72))

    let sliderY = origin.y + 143
    roundedRect(NSRect(x: origin.x + 16, y: sliderY, width: 204, height: 4), radius: 2, color: .white.withAlphaComponent(0.2))
    roundedRect(NSRect(x: origin.x + 16, y: sliderY, width: 82, height: 4), radius: 2, color: .white.withAlphaComponent(0.48))
    roundedRect(NSRect(x: origin.x + 91, y: sliderY - 5.5, width: 15, height: 15), radius: 7.5, color: .white)

    text("Volume: 40", at: NSPoint(x: origin.x + 16, y: origin.y + 112), size: 13, weight: .regular, color: .white.withAlphaComponent(0.72))

    let buttonY = origin.y + 70
    let buttonSymbols = ["speaker.slash.fill", "speaker.minus.fill", "speaker.plus.fill", "arrow.clockwise"]
    for (index, name) in buttonSymbols.enumerated() {
        let x = origin.x + 16 + CGFloat(index) * 55
        roundedRect(NSRect(x: x, y: buttonY, width: 44, height: 30), radius: 7, color: .white.withAlphaComponent(0.13))
        symbol(name, in: NSRect(x: x + 12, y: buttonY + 7, width: 20, height: 16), color: .white.withAlphaComponent(0.88))
    }

    NSColor.white.withAlphaComponent(0.16).setStroke()
    let divider = NSBezierPath()
    divider.move(to: NSPoint(x: origin.x + 16, y: origin.y + 54))
    divider.line(to: NSPoint(x: origin.x + width - 16, y: origin.y + 54))
    divider.stroke()

    text("Ready", at: NSPoint(x: origin.x + 16, y: origin.y + 30), size: 12, color: .white.withAlphaComponent(0.45))
    text("Quit", at: NSPoint(x: origin.x + 16, y: origin.y + 10), size: 12, color: .white.withAlphaComponent(0.82))
}

let hero = try withBitmap(width: 1040, height: 580) { width, height in
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.36, blue: 0.55, alpha: 1),
        NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.12, alpha: 1)
    ])!
    gradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 90)

    roundedRect(NSRect(x: 0, y: height - 30, width: width, height: 30), radius: 0, color: NSColor(calibratedWhite: 0.04, alpha: 0.62))
    text("Finder", at: NSPoint(x: 18, y: height - 22), size: 13, weight: .semibold, color: .white.withAlphaComponent(0.86))
    text("File", at: NSPoint(x: 78, y: height - 22), size: 13, color: .white.withAlphaComponent(0.72))
    text("Edit", at: NSPoint(x: 120, y: height - 22), size: 13, color: .white.withAlphaComponent(0.72))

    drawMenuBarBadge(x: width - 222, y: height - 23)
    symbol("wifi", in: NSRect(x: width - 162, y: height - 22, width: 17, height: 17), color: .white.withAlphaComponent(0.86))
    symbol("moon.fill", in: NSRect(x: width - 126, y: height - 22, width: 15, height: 15), color: .white.withAlphaComponent(0.86))
    text("16:04", at: NSPoint(x: width - 84, y: height - 22), size: 13, weight: .medium, color: .white.withAlphaComponent(0.86))

    drawDropdown(origin: NSPoint(x: width - 310, y: height - 238), width: 260)

    text("knob", at: NSPoint(x: 84, y: 220), size: 42, weight: .bold, color: .white)
    text("A tiny menu bar volume control for monitor speakers.", at: NSPoint(x: 86, y: 188), size: 18, color: .white.withAlphaComponent(0.72))
}
try write(hero, to: "knob-hero.png")

let menu = try withBitmap(width: 360, height: 260) { width, height in
    NSColor(calibratedRed: 0.09, green: 0.13, blue: 0.17, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    drawDropdown(origin: NSPoint(x: 50, y: 28), width: 260)
}
try write(menu, to: "knob-menu.png")
