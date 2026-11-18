// The ADR-0002 D3, D4 and D6 seams: the only ways KidCore reads time, chance or the platform. Names are final
// (ADR-0002 D6); the app implements them, and tests and contract fixtures inject fakes. Shapes for the seams that
// later stories fill in (audio, render, residency) stay minimal until their ADRs (0006, 0009, 0010) need more.

/// Awake time since boot, in seconds (ADR-0002 D3): event and frame times.
public protocol UptimeClock { func now() -> Double }

/// Time that keeps counting while the device sleeps (ADR-0002 D3; App Shell R6 "away").
public protocol AwayClock { func now() -> Double }

/// Local civil time for the Scene's looks (ADR-0002 D3).
public struct WallTime: Equatable, Sendable {
    /// Minutes since local midnight, fractional.
    public var minutesOfDay: Double
    /// The local date as yyyymmdd.
    public var dayKey: Int
    /// A wall time from its fields.
    public init(minutesOfDay: Double, dayKey: Int) { self.minutesOfDay = minutesOfDay; self.dayKey = dayKey }
}

/// The local wall clock (ADR-0002 D3).
public protocol WallClock { func now() -> WallTime }

/// One random stream (ADR-0002 D4). Each stream has its own source and seed.
public protocol RandomSource { mutating func next() -> UInt64 }

/// A fixed list of 64-bit values, for tests and contract fixtures ("draws", ADR-0004).
public struct DrawList: RandomSource {
    private var values: [UInt64]
    private var index = 0
    /// The draws, in the order they are consumed.
    public init(_ values: [UInt64]) { self.values = values }
    /// The number of draws not yet consumed (a contract case fails on a leftover draw).
    public var remaining: Int { values.count - index }
    /// The next draw; running out is a programming error in a test.
    public mutating func next() -> UInt64 {
        precondition(index < values.count, "DrawList exhausted")
        defer { index += 1 }
        return values[index]
    }
}

/// The stored settings record as bytes (ADR-0002 D6; ADR-0005).
public protocol SettingsBackend {
    /// The stored bytes, or nil when there is no record.
    func read() -> [UInt8]?
    /// Writes the whole record; nil when the platform cannot report the result.
    func write(_ bytes: [UInt8]) -> Bool?
    /// Removes the record (Reset).
    func remove()
}

/// The Mac kiosk's effects (ADR-0002 D6; ADR-0008). A no-op on iPad.
public protocol KioskEffects {
    func apply()
    func remove()
    func coverDisplays(_ on: Bool)
    var isActive: Bool { get }
    var windowCoversDisplay: Bool { get }
}

/// The window and screen, read live (ADR-0002 D6; ADR-0006 D2, D7). Insets are top, left, bottom, right in px.
public struct DisplayMetrics: Equatable, Sendable {
    public var windowPx: (w: Double, h: Double)
    public var pxPerPt: Double
    public var safeAreaInsetsPx: [Double]
    public var ppiX: Double
    public var ppiY: Double
    public var gestureInsetsPx: [Double]
    public init(windowPx: (w: Double, h: Double), pxPerPt: Double, safeAreaInsetsPx: [Double], ppiX: Double,
                ppiY: Double, gestureInsetsPx: [Double]) {
        self.windowPx = windowPx; self.pxPerPt = pxPerPt; self.safeAreaInsetsPx = safeAreaInsetsPx
        self.ppiX = ppiX; self.ppiY = ppiY; self.gestureInsetsPx = gestureInsetsPx
    }
    public static func == (a: DisplayMetrics, b: DisplayMetrics) -> Bool {
        a.windowPx == b.windowPx && a.pxPerPt == b.pxPerPt && a.safeAreaInsetsPx == b.safeAreaInsetsPx
            && a.ppiX == b.ppiX && a.ppiY == b.ppiY && a.gestureInsetsPx == b.gestureInsetsPx
    }
}

/// Accessibility settings read live (ADR-0002 D6).
public struct AccessibilityState: Equatable, Sendable {
    public var reduceMotion: Bool
    public var guidedAccessEnabled: Bool
    public init(reduceMotion: Bool, guidedAccessEnabled: Bool) {
        self.reduceMotion = reduceMotion; self.guidedAccessEnabled = guidedAccessEnabled
    }
}

/// Lifecycle events the app hands to KidCore (ADR-0002 D6).
public enum AppLifecycleEvent: Equatable, Sendable {
    case foreground, background, active, inactive, windowKeyGained, windowKeyLost, screenParametersChanged, memoryWarning
}

/// The debug log: one line, never written to disk (ADR-0002 D6; Settings Store R2; PKC-14).
public protocol DebugLog { func log(_ line: String) }

/// The Mac OS key state, wired only if Input AC-1k6 passes (ADR-0002 D6; Input R6).
public protocol KeyStateQuery { func anyNonModifierDown(except physicalId: String) -> Bool }

/// The bundled-content probe (ADR-0003 D3): exact-case paths relative to a theme's folder.
public protocol ContentProbe {
    func exists(_ path: String) -> Bool
    func byteSize(_ path: String) -> Int64?
    func decodedDuration(_ path: String) -> Double?
}
