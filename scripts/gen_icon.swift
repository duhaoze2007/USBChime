#!/usr/bin/env swift
// Generates USBChime's 1024x1024 app icon — the cable.connector SF Symbol
// (USB-C plug with cable tail) rendered large on the gradient squircle.
// Run: swift scripts/gen_icon.swift  →  icon-src/AppIcon_1024.png
import AppKit
import CoreGraphics

let size = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

let canvas = NSRect(x: 0, y: 0, width: size, height: size)

// ---- Background: rounded rect with blue→purple gradient ----
let radius: CGFloat = 232
let bgPath = NSBezierPath(roundedRect: canvas, xRadius: radius, yRadius: radius)
bgPath.addClip()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.16, green: 0.55, blue: 0.98, alpha: 1.0),   // #298FFA
    NSColor(calibratedRed: 0.42, green: 0.32, blue: 0.94, alpha: 1.0),   // #6B52F0
])!
gradient.draw(in: canvas, angle: -55)

// Soft top highlight
NSColor(calibratedWhite: 1.0, alpha: 0.10).setFill()
NSBezierPath(roundedRect: canvas, xRadius: radius, yRadius: radius).fill()

// Drop shadow under the symbol
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 44, color: NSColor.black.withAlphaComponent(0.38).cgColor)

// ---- The cable.connector symbol (same one as the menu bar icon), white ----
let palette = NSImage.SymbolConfiguration(paletteColors: [NSColor(calibratedWhite: 1.0, alpha: 0.97)])
let config = NSImage.SymbolConfiguration(pointSize: 620, weight: .semibold).applying(palette)
if let symbol = NSImage(systemSymbolName: "cable.connector", accessibilityDescription: nil)?.withSymbolConfiguration(config) {
    // SF Symbols pad unevenly (the cable tail sits low); enlarge the draw
    // rect and shift it up so margins are balanced on all sides.
    let drawSize: CGFloat = 720
    let rect = NSRect(x: (CGFloat(size) - drawSize) / 2,
                      y: (CGFloat(size) - drawSize) / 2 + 46,
                      width: drawSize, height: drawSize)
    symbol.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
}

ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

// ---- Save PNG ----
let png = rep.representation(using: .png, properties: [:])!
let outURL = URL(fileURLWithPath: "icon-src/AppIcon_1024.png")
try! png.write(to: outURL)
print("Wrote \(outURL.path)")
