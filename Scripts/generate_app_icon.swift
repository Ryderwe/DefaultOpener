import AppKit
import CoreGraphics
import Foundation

struct IconRenderer {
    let canvas: CGFloat

    func render() -> NSBitmapImageRep {
        let pixelsWide = Int(canvas)
        let pixelsHigh = Int(canvas)
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: pixelsWide,
                pixelsHigh: pixelsHigh,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            fatalError("Failed to allocate bitmap")
        }

        rep.size = NSSize(width: canvas, height: canvas)

        let ctx = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        let cg = ctx.cgContext

        cg.setAllowsAntialiasing(true)
        cg.setShouldAntialias(true)
        cg.interpolationQuality = .high

        draw(in: cg)

        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    private func draw(in cg: CGContext) {
        let rect = CGRect(x: 0, y: 0, width: canvas, height: canvas)
        cg.clear(rect)

        // Background: rounded rect + gradient
        let outerInset = canvas * 0.06
        let bgRect = rect.insetBy(dx: outerInset, dy: outerInset)
        let bgPath = CGPath(roundedRect: bgRect, cornerWidth: canvas * 0.18, cornerHeight: canvas * 0.18, transform: nil)

        cg.saveGState()
        cg.addPath(bgPath)
        cg.clip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor] = [
            NSColor(calibratedRed: 0.11, green: 0.39, blue: 0.96, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.52, green: 0.23, blue: 0.93, alpha: 1).cgColor,
        ]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 1])!
        cg.drawLinearGradient(
            gradient,
            start: CGPoint(x: bgRect.minX, y: bgRect.maxY),
            end: CGPoint(x: bgRect.maxX, y: bgRect.minY),
            options: []
        )

        // Subtle gloss highlight
        cg.setFillColor(NSColor.white.withAlphaComponent(0.10).cgColor)
        cg.fillEllipse(in: CGRect(x: bgRect.minX - canvas * 0.10, y: bgRect.maxY - canvas * 0.45, width: canvas * 0.70, height: canvas * 0.70))
        cg.restoreGState()

        // Inner "content" card shadow
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -canvas * 0.01), blur: canvas * 0.03, color: NSColor.black.withAlphaComponent(0.25).cgColor)
        let cardRect = bgRect.insetBy(dx: canvas * 0.09, dy: canvas * 0.16)
        let cardPath = CGPath(roundedRect: cardRect, cornerWidth: canvas * 0.12, cornerHeight: canvas * 0.12, transform: nil)
        cg.setFillColor(NSColor.white.withAlphaComponent(0.16).cgColor)
        cg.addPath(cardPath)
        cg.fillPath()
        cg.restoreGState()

        // File (left)
        let fileW = canvas * 0.30
        let fileH = canvas * 0.42
        let fileRect = CGRect(
            x: cardRect.minX + canvas * 0.10,
            y: cardRect.midY - fileH * 0.52,
            width: fileW,
            height: fileH
        )
        drawFile(in: cg, rect: fileRect)

        // App (right)
        let appW = canvas * 0.32
        let appH = canvas * 0.32
        let appRect = CGRect(
            x: cardRect.maxX - canvas * 0.10 - appW,
            y: cardRect.midY - appH * 0.45,
            width: appW,
            height: appH
        )
        drawAppBadge(in: cg, rect: appRect)

        // Arrow between them
        drawArrow(in: cg, from: CGPoint(x: fileRect.maxX + canvas * 0.06, y: fileRect.midY), to: CGPoint(x: appRect.minX - canvas * 0.06, y: appRect.midY))

        // Small caption lines on the file
        drawFileLines(in: cg, rect: fileRect)
    }

    private func drawFile(in cg: CGContext, rect: CGRect) {
        let radius = canvas * 0.06
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -canvas * 0.006), blur: canvas * 0.02, color: NSColor.black.withAlphaComponent(0.18).cgColor)
        cg.setFillColor(NSColor.white.withAlphaComponent(0.95).cgColor)
        cg.addPath(path)
        cg.fillPath()
        cg.restoreGState()

        // Fold corner
        let fold = canvas * 0.09
        let foldPath = CGMutablePath()
        foldPath.move(to: CGPoint(x: rect.maxX - fold, y: rect.maxY))
        foldPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        foldPath.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - fold))
        foldPath.closeSubpath()

        cg.setFillColor(NSColor(calibratedWhite: 0.92, alpha: 1).cgColor)
        cg.addPath(foldPath)
        cg.fillPath()

        cg.setStrokeColor(NSColor.black.withAlphaComponent(0.10).cgColor)
        cg.setLineWidth(max(1, canvas * 0.004))
        cg.addPath(path)
        cg.strokePath()
    }

    private func drawAppBadge(in cg: CGContext, rect: CGRect) {
        let radius = canvas * 0.10
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -canvas * 0.006), blur: canvas * 0.02, color: NSColor.black.withAlphaComponent(0.18).cgColor)
        cg.setFillColor(NSColor.white.withAlphaComponent(0.90).cgColor)
        cg.addPath(path)
        cg.fillPath()
        cg.restoreGState()

        // Inner glyph: small "app" window
        let inset = rect.insetBy(dx: canvas * 0.06, dy: canvas * 0.07)
        let innerRadius = canvas * 0.05
        let inner = CGPath(roundedRect: inset, cornerWidth: innerRadius, cornerHeight: innerRadius, transform: nil)

        cg.setFillColor(NSColor(calibratedRed: 0.16, green: 0.44, blue: 0.96, alpha: 1).withAlphaComponent(0.20).cgColor)
        cg.addPath(inner)
        cg.fillPath()

        // Title bar dots
        let dotY = inset.maxY - canvas * 0.07
        let dotR = canvas * 0.012
        let dotXs = [inset.minX + canvas * 0.05, inset.minX + canvas * 0.09, inset.minX + canvas * 0.13]
        let dotColors: [NSColor] = [
            NSColor.systemRed.withAlphaComponent(0.75),
            NSColor.systemYellow.withAlphaComponent(0.75),
            NSColor.systemGreen.withAlphaComponent(0.75),
        ]
        for (x, c) in zip(dotXs, dotColors) {
            cg.setFillColor(c.cgColor)
            cg.fillEllipse(in: CGRect(x: x - dotR, y: dotY - dotR, width: dotR * 2, height: dotR * 2))
        }

        cg.setStrokeColor(NSColor.black.withAlphaComponent(0.10).cgColor)
        cg.setLineWidth(max(1, canvas * 0.004))
        cg.addPath(path)
        cg.strokePath()
    }

    private func drawArrow(in cg: CGContext, from: CGPoint, to: CGPoint) {
        let lineWidth = canvas * 0.05
        let head = canvas * 0.08

        cg.saveGState()
        cg.setLineCap(.round)
        cg.setLineJoin(.round)
        cg.setStrokeColor(NSColor.white.withAlphaComponent(0.90).cgColor)
        cg.setLineWidth(lineWidth)

        cg.move(to: from)
        cg.addLine(to: to)
        cg.strokePath()

        // Arrow head
        let angle = atan2(to.y - from.y, to.x - from.x)
        let p1 = CGPoint(x: to.x - cos(angle - .pi / 6) * head, y: to.y - sin(angle - .pi / 6) * head)
        let p2 = CGPoint(x: to.x - cos(angle + .pi / 6) * head, y: to.y - sin(angle + .pi / 6) * head)
        cg.move(to: p1)
        cg.addLine(to: to)
        cg.addLine(to: p2)
        cg.strokePath()

        // Soft outline to improve contrast
        cg.setStrokeColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        cg.setLineWidth(max(1, canvas * 0.010))
        cg.move(to: from)
        cg.addLine(to: to)
        cg.strokePath()

        cg.restoreGState()
    }

    private func drawFileLines(in cg: CGContext, rect: CGRect) {
        cg.saveGState()
        cg.setStrokeColor(NSColor.black.withAlphaComponent(0.12).cgColor)
        cg.setLineWidth(max(1, canvas * 0.006))
        cg.setLineCap(.round)

        let left = rect.minX + canvas * 0.05
        let right = rect.maxX - canvas * 0.07
        let top = rect.maxY - canvas * 0.14
        let gap = canvas * 0.06
        for i in 0..<4 {
            let y = top - CGFloat(i) * gap
            cg.move(to: CGPoint(x: left, y: y))
            cg.addLine(to: CGPoint(x: right - CGFloat(i) * canvas * 0.03, y: y))
        }
        cg.strokePath()
        cg.restoreGState()
    }
}

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Assets", isDirectory: true)
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let renderer = IconRenderer(canvas: 1024)
let rep = renderer.render()
let png = rep.representation(using: .png, properties: [:])!

let outFile = outDir.appendingPathComponent("AppIcon-1024.png")
try png.write(to: outFile, options: [.atomic])
print("Wrote \(outFile.path)")
