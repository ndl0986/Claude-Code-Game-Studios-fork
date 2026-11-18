/// Reveal Stage F1 (K-20): the 1280 × 720 safe stage contained in the window; the sky and ground extend into the
/// rest. Never a letterbox (K-39: any window shape, portrait included).
public struct StageFit: Equatable, Sendable {
    /// The safe stage, in stage units (y down).
    public static let stageWidth = 1280.0
    public static let stageHeight = 720.0

    /// `stage_to_px`: window units per stage unit.
    public let scale: Double
    /// Where the safe stage's top-left corner sits in the window, in window units.
    public let offsetX: Double
    public let offsetY: Double
    /// The whole window in stage units (the visible rect): may extend past 0–1280 × 0–720.
    public let visibleX: Double
    public let visibleY: Double
    public let visibleWidth: Double
    public let visibleHeight: Double

    /// F1 for a window `width` × `height` (px, or points when the caller scales consistently). Both must be > 0.
    public init(width: Double, height: Double) {
        let s = min(width / Self.stageWidth, height / Self.stageHeight)
        scale = s
        offsetX = (width - Self.stageWidth * s) / 2
        offsetY = (height - Self.stageHeight * s) / 2
        visibleX = -offsetX / s
        visibleY = -offsetY / s
        visibleWidth = width / s
        visibleHeight = height / s
    }

    /// A stage point (y down) in window units (y down).
    public func toWindow(x: Double, y: Double) -> (x: Double, y: Double) { (offsetX + x * scale, offsetY + y * scale) }
}
