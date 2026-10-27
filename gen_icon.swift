import AppKit

// Orange gradient tile + big white "1⁴" mark, rendered at all iconset sizes.
let gradTop = NSColor(red: 1.000, green: 0.663, blue: 0.251, alpha: 1.0) // bright orange
let gradBottom = NSColor(red: 0.965, green: 0.510, blue: 0.122, alpha: 1.0) // OG #F6821F

func whiteShield(size: NSSize) -> NSImage {
    guard let symbol = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: nil) else {
        fatalError("SF Symbol shield.fill not available")
    }
    let out = NSImage(size: size)
    out.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: size).fill(using: .sourceOver)
    // full-bleed mask: no aspect-fit margins (they'd survive destinationIn as hairlines)
    let full = NSRect(origin: .zero, size: size)
    let sz = symbol.size
    symbol.draw(in: full, from: NSRect(origin: .zero, size: sz), operation: .destinationIn, fraction: 1.0)
    out.unlockFocus()
    return out
}

func render(size: Int) -> NSImage {
    let s = CGFloat(size)
    let img = NSImage(size: NSSize(width: s, height: s))
    img.lockFocus()
    let full = NSRect(x: 0, y: 0, width: s, height: s)
    let tile = NSBezierPath(roundedRect: full, xRadius: s * 0.225, yRadius: s * 0.225)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    if let grad = NSGradient(starting: gradTop, ending: gradBottom) {
        grad.draw(from: NSPoint(x: s / 2, y: s), to: NSPoint(x: s / 2, y: 0), options: [])
    }
    NSGraphicsContext.restoreGraphicsState()

    // Big white shield
    let sw = s * 0.70, sh = s * 0.74
    let shieldRect = NSRect(x: (s - sw) / 2, y: (s - sh) / 2 - s * 0.005, width: sw, height: sh)
    whiteShield(size: shieldRect.size).draw(in: shieldRect, from: .zero,
        operation: .sourceOver, fraction: 1.0)

    // Orange 1⁴ inside the shield, riding slightly high (shields taper at the bottom)
    let markOrange = NSColor(red: 0.965, green: 0.510, blue: 0.122, alpha: 1.0)
    let one = "1" as NSString
    let four = "4" as NSString
    let p1 = NSFont.systemFont(ofSize: 200, weight: .black)
    let p4 = NSFont.systemFont(ofSize: 108, weight: .black)
    let m1 = one.size(withAttributes: [.font: p1])
    let m4 = four.size(withAttributes: [.font: p4])
    let raise = m1.height * 0.52
    let overlap = m4.width * 0.10
    let W = m1.width + m4.width - overlap
    let H = raise + m4.height
    let k = (shieldRect.width * 0.46) / W
    let f1 = NSFont.systemFont(ofSize: 200 * k, weight: .black)
    let f4 = NSFont.systemFont(ofSize: 108 * k, weight: .black)
    let a1: [NSAttributedString.Key: Any] = [.font: f1, .foregroundColor: markOrange]
    let a4: [NSAttributedString.Key: Any] = [.font: f4, .foregroundColor: markOrange]
    let w1 = m1.width * k
    let cx = shieldRect.midX - (W * k) / 2
    let cy = shieldRect.midY - (H * k) / 2 + shieldRect.height * 0.05
    one.draw(at: NSPoint(x: cx, y: cy), withAttributes: a1)
    four.draw(at: NSPoint(x: cx + w1 - overlap * k, y: cy + raise * k), withAttributes: a4)
    img.unlockFocus()
    return img
}

func png(_ img: NSImage, size: Int, to url: URL) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    img.draw(in: NSRect(x: 0, y: 0, width: size, height: size),
             from: NSRect(x: 0, y: 0, width: img.size.width, height: img.size.height),
             operation: .sourceOver, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("PNG encode failed for \(size)")
    }
    try! data.write(to: url)
}

let dir = URL(fileURLWithPath: "AppIcon.iconset", isDirectory: true)
try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
let specs: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in specs {
    png(render(size: 1024), size: px, to: dir.appendingPathComponent("\(name).png"))
    print("wrote \(name).png")
}
