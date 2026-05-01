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
    color.setStroke()
    color.setFill()

    func speakerShape() {
        let p = NSBezierPath()
        p.move(to: NSPoint(x: rect.minX + rect.width * 0.16, y: rect.midY))
        p.line(to: NSPoint(x: rect.minX + rect.width * 0.38, y: rect.midY))
        p.line(to: NSPoint(x: rect.minX + rect.width * 0.64, y: rect.maxY - 2))
        p.line(to: NSPoint(x: rect.minX + rect.width * 0.64, y: rect.minY + 2))
        p.line(to: NSPoint(x: rect.minX + rect.width * 0.38, y: rect.midY))
        p.close()
        p.fill()
    }

    switch name {
    case "display":
        let screen = NSBezierPath(roundedRect: NSRect(x: rect.minX + 1, y: rect.minY + 4, width: rect.width - 2, height: rect.height - 6), xRadius: 1.5, yRadius: 1.5)
        screen.lineWidth = 1.4
        screen.stroke()
        let stand = NSBezierPath()
        stand.lineWidth = 1.2
        stand.move(to: NSPoint(x: rect.midX, y: rect.minY + 4))
        stand.line(to: NSPoint(x: rect.midX, y: rect.minY + 1))
        stand.move(to: NSPoint(x: rect.midX - 4, y: rect.minY + 1))
        stand.line(to: NSPoint(x: rect.midX + 4, y: rect.minY + 1))
        stand.stroke()
    case "wifi":
        for radius in [7.0, 4.5] {
            let arc = NSBezierPath()
            arc.lineWidth = 1.6
            arc.appendArc(withCenter: NSPoint(x: rect.midX, y: rect.minY + 3), radius: radius, startAngle: 40, endAngle: 140)
            arc.stroke()
        }
        NSBezierPath(ovalIn: NSRect(x: rect.midX - 1.3, y: rect.minY + 2, width: 2.6, height: 2.6)).fill()
    case "moon.fill":
        NSBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 1)).fill()
        NSColor(calibratedRed: 0.09, green: 0.16, blue: 0.22, alpha: 1).setFill()
        NSBezierPath(ovalIn: rect.offsetBy(dx: 5, dy: 2).insetBy(dx: 2, dy: 1)).fill()
    case "speaker.slash.fill":
        speakerShape()
        let slash = NSBezierPath()
        slash.lineWidth = 2
        slash.lineCapStyle = .round
        slash.move(to: NSPoint(x: rect.minX + 2, y: rect.maxY - 2))
        slash.line(to: NSPoint(x: rect.maxX - 2, y: rect.minY + 2))
        slash.stroke()
    case "speaker.minus.fill":
        speakerShape()
        let minus = NSBezierPath()
        minus.lineWidth = 2
        minus.lineCapStyle = .round
        minus.move(to: NSPoint(x: rect.maxX - 7, y: rect.midY))
        minus.line(to: NSPoint(x: rect.maxX - 2, y: rect.midY))
        minus.stroke()
    case "speaker.plus.fill":
        speakerShape()
        let plus = NSBezierPath()
        plus.lineWidth = 2
        plus.lineCapStyle = .round
        plus.move(to: NSPoint(x: rect.maxX - 8, y: rect.midY))
        plus.line(to: NSPoint(x: rect.maxX - 2, y: rect.midY))
        plus.move(to: NSPoint(x: rect.maxX - 5, y: rect.midY - 3))
        plus.line(to: NSPoint(x: rect.maxX - 5, y: rect.midY + 3))
        plus.stroke()
    case "arrow.clockwise":
        let arc = NSBezierPath()
        arc.lineWidth = 2
        arc.lineCapStyle = .round
        arc.appendArc(withCenter: rect.center, radius: min(rect.width, rect.height) * 0.34, startAngle: 35, endAngle: 320)
        arc.stroke()
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: rect.maxX - 4, y: rect.midY + 3))
        arrow.line(to: NSPoint(x: rect.maxX - 1, y: rect.midY + 7))
        arrow.line(to: NSPoint(x: rect.maxX - 6, y: rect.midY + 7))
        arrow.fill()
    default:
        NSBezierPath(ovalIn: rect.insetBy(dx: 4, dy: 4)).fill()
    }
}

extension NSRect {
    var center: NSPoint { NSPoint(x: midX, y: midY) }
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
        symbol(name, in: NSRect(x: x + 12, y: buttonY + 7, width: 20, height: 16), color: .white.withAlphaComponent(0.94))
    }

    NSColor.white.withAlphaComponent(0.16).setStroke()
    let divider = NSBezierPath()
    divider.move(to: NSPoint(x: origin.x + 16, y: origin.y + 54))
    divider.line(to: NSPoint(x: origin.x + width - 16, y: origin.y + 54))
    divider.stroke()

    text("Ready", at: NSPoint(x: origin.x + 16, y: origin.y + 30), size: 12, color: .white.withAlphaComponent(0.45))
    text("Quit", at: NSPoint(x: origin.x + 16, y: origin.y + 10), size: 12, color: .white.withAlphaComponent(0.82))
}

let hero = try withBitmap(width: 880, height: 420) { width, height in
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.18, green: 0.40, blue: 0.53, alpha: 1),
        NSColor(calibratedRed: 0.09, green: 0.16, blue: 0.22, alpha: 1)
    ])!
    gradient.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 90)

    roundedRect(NSRect(x: 0, y: height - 30, width: width, height: 30), radius: 0, color: NSColor(calibratedWhite: 0.04, alpha: 0.62))
    text("Finder", at: NSPoint(x: 18, y: height - 22), size: 13, weight: .semibold, color: .white.withAlphaComponent(0.86))
    text("File", at: NSPoint(x: 78, y: height - 22), size: 13, color: .white.withAlphaComponent(0.72))
    text("Edit", at: NSPoint(x: 120, y: height - 22), size: 13, color: .white.withAlphaComponent(0.72))

    drawMenuBarBadge(x: width - 268, y: height - 23)
    symbol("wifi", in: NSRect(x: width - 206, y: height - 22, width: 17, height: 17), color: .white.withAlphaComponent(0.86))
    symbol("moon.fill", in: NSRect(x: width - 170, y: height - 22, width: 15, height: 15), color: .white.withAlphaComponent(0.86))
    text("16:04", at: NSPoint(x: width - 128, y: height - 22), size: 13, weight: .medium, color: .white.withAlphaComponent(0.86))

    drawDropdown(origin: NSPoint(x: width - 356, y: height - 247), width: 260)

    text("knob", at: NSPoint(x: 58, y: 74), size: 30, weight: .bold, color: .white.withAlphaComponent(0.94))
    text("Monitor volume, back in the menu bar.", at: NSPoint(x: 60, y: 51), size: 14, color: .white.withAlphaComponent(0.64))
}
try write(hero, to: "knob-hero.png")

let menu = try withBitmap(width: 360, height: 260) { width, height in
    NSColor(calibratedRed: 0.16, green: 0.25, blue: 0.32, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    drawDropdown(origin: NSPoint(x: 50, y: 28), width: 260)
}
try write(menu, to: "knob-menu.png")
