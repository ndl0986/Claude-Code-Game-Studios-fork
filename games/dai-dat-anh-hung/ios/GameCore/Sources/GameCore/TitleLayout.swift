import Foundation

/// A box in scene units (1280×720 world, y down).
public struct Box: Equatable, Sendable {
    public var x, y, w, h: Double
    public init(_ x: Double, _ y: Double, _ w: Double, _ h: Double) { self.x = x; self.y = y; self.w = w; self.h = h }
    public var right: Double { x + w }
    public var bottom: Double { y + h }
    public var midX: Double { x + w / 2 }
    public var midY: Double { y + h / 2 }
    public func overlaps(_ o: Box) -> Bool { x < o.right && o.x < right && y < o.bottom && o.y < bottom }
}

/// The title screen's boxes (design/ux/title.md §5.2, §5.5; D-27, D-27b), from the pad layout:
/// sound top-left, the VI|EN chip top-right, the title row, the hero card, Start, the map stub and
/// (debug builds) the debug line. Pure geometry, so the ACs (4d, 4f, 6) are unit tests.
public struct TitleLayout: Equatable, Sendable {
    public let sound, chip, titleRow, card, start, mapStub: Box
    public let debugLine: Box?
    /// D-27b: the stub and debug line sit right of Start because the column would pass safe_bottom.
    public let linesBesideStart: Bool

    public static let stubHeight = 38.0, debugHeight = 34.0

    public init(pad: PadLayout, debug: Bool) {
        let p = pad.pause // the title's sound sits in the pause slot (sound only on the title)
        sound = Box(p.cx - p.r, p.cy - p.r, 2 * p.r, 2 * p.r)
        chip = Box(pad.lang.x, pad.lang.y, pad.lang.w, pad.lang.h)
        titleRow = Box(260, 18, min(1020, chip.x - 8) - 260, 137)
        card = Box(260, 175, 760, 180)
        start = Box(430, 375, 420, max(pad.padWorld, 96))
        let stub = Box(240, start.bottom + 16, 800, Self.stubHeight)
        let dbg = Box(240, stub.bottom + 8, 800, Self.debugHeight)
        let last = debug ? dbg.bottom : stub.bottom
        if last > pad.safeBottom {
            linesBesideStart = true
            mapStub = Box(870, start.y, 380, Self.stubHeight)
            debugLine = debug ? Box(870, mapStub.bottom + 8, 380, Self.debugHeight) : nil
        } else {
            linesBesideStart = false
            mapStub = stub
            debugLine = debug ? dbg : nil
        }
    }

    /// Every box on screen, named (for overlap checks).
    public var all: [(String, Box)] {
        [("sound", sound), ("chip", chip), ("title", titleRow), ("card", card), ("start", start), ("stub", mapStub)]
            + (debugLine.map { [("debug", $0)] } ?? [])
    }
}
