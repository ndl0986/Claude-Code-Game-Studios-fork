import Foundation
import KidCore

/// The uptime clock adapter (ADR-0002 D3): `ProcessInfo.systemUptime`, the clock of event timestamps and the
/// display link. This call is why the privacy manifest declares SystemBootTime / 35F9.1 (PKC-09).
struct SystemUptimeClock: UptimeClock {
    func now() -> Double { ProcessInfo.processInfo.systemUptime }
}
