// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike; ADR-0006 D2, D7; Reveal Stage F1)

/// Reveal Stage F1: contain the 1280×720 safe stage, then extend. All values in physical pixels and stage units.
public struct StageFit: Equatable, Sendable {
    public let scale: Double            // stage_to_px
    public let offsetX: Double, offsetY: Double
    public let visibleX: Double, visibleY: Double, visibleW: Double, visibleH: Double

    public init(windowPxW w: Double, windowPxH h: Double) {
        scale = min(w / 1280, h / 720)
        offsetX = (w - 1280 * scale) / 2
        offsetY = (h - 720 * scale) / 2
        visibleX = -offsetX / scale; visibleY = -offsetY / scale
        visibleW = w / scale; visibleH = h / scale
    }

    /// Window px → stage units (y down), as KidCore would do for a TouchEvent (ADR-0002 D5).
    public func stagePoint(px x: Double, _ y: Double) -> (Double, Double) { ((x - offsetX) / scale, (y - offsetY) / scale) }
}

/// ADR-0006 D7: pixel density, with the unknown rule at the class maximum (K-34).
public enum PPI {
    /// iPad model identifiers → ppi. Spike values; each production row must cite Apple's tech-specs page.
    public static let iPadTable: [String: Double] = [
        "iPad16,3": 264, "iPad16,4": 264, "iPad16,5": 264, "iPad16,6": 264,     // iPad Pro M4
        "iPad15,3": 264, "iPad15,4": 264, "iPad15,5": 264, "iPad15,6": 264,     // iPad Air M2
        "iPad15,7": 264, "iPad15,8": 264,                                       // iPad (A16)
        "iPad16,1": 326, "iPad16,2": 326,                                       // iPad mini (A17 Pro)
        "iPad13,4": 264, "iPad13,5": 264, "iPad13,6": 264, "iPad13,7": 264,     // iPad Pro 11-inch (3rd gen, M1): TASK-127 device
    ]
    public static let iPadClassMax = 326.0
    public static let macClassMax = 254.0

    public enum Source: Equatable, Sendable { case table, measured, unknownClassMax }

    public static func iPad(model: String) -> (Double, Source) {
        if let v = iPadTable[model] { return (v, .table) }
        return (iPadClassMax, .unknownClassMax)
    }

    /// Mac: from CGDisplayScreenSize (mm) and pixels. 0 mm, or ≈72 dpi (the no-EDID estimate), counts as unknown.
    public static func mac(pixelsW: Double, mmW: Double) -> (Double, Source) {
        guard mmW > 0 else { return (macClassMax, .unknownClassMax) }
        let ppi = pixelsW / (mmW / 25.4)
        if abs(ppi - 72) < 1 { return (macClassMax, .unknownClassMax) }
        return (ppi, .measured)
    }
}
