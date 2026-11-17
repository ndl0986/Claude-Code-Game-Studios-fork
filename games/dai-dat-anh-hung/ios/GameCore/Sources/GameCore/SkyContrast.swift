import Foundation

/// WCAG contrast for the pops' outline (hud §3.3, accessibility-requirements: ink on light skies, cream on the camp's
/// dark sky). The outline is chosen by the sky's own colours, never by a theme's name (QC r5 N1: a day sky under a
/// "camp" name would otherwise get cream at 1.28:1).
public enum SkyContrast {
    public enum Outline: String, Sendable { case ink, cream }
    public static let ink = "#3A2A20", cream = "#FFF6E3"

    /// Relative luminance of an sRGB "#RRGGBB" colour (WCAG 2.x).
    public static func luminance(_ hex: String) -> Double {
        let v = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        func ch(_ s: UInt32) -> Double {
            let c = Double((v >> s) & 0xFF) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * ch(16) + 0.7152 * ch(8) + 0.0722 * ch(0)
    }

    /// The contrast ratio between two colours (1…21).
    public static func ratio(_ a: String, _ b: String) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// The outline that reads better against both ends of the sky band (its worse end decides).
    public static func popOutline(skyTop: String, skyBottom: String) -> Outline {
        let i = min(ratio(ink, skyTop), ratio(ink, skyBottom)), c = min(ratio(cream, skyTop), ratio(cream, skyBottom))
        return c > i ? .cream : .ink
    }

    /// The pop's outline rings, outermost first, as (colour, distance from the glyph in px). Ink-only skies: one ink
    /// ring at 3.5 px. Where cream wins (hud AC15, r9): ink out to 6 px around cream out to 4 px, so the cream band is
    /// 4 px (≥ 3) and the ink band outside it 2 px (≥ 2): the cream reads on the dark sky, the ink on a light mid layer.
    public static func popRings(_ o: Outline) -> [(hex: String, px: Double)] {
        o == .cream ? [(ink, 6), (cream, 4)] : [(ink, 3.5)]
    }
}
