import Foundation

/// Story and dialogue screens' boxes (design/ux/story-screens.md §5.2, dialogue.md §5.2; QC r5): the
/// button row at the bottom, text panels bottom-anchored above it, everything below the pause/sound
/// corner block. World px, y down, the world fitted to the safe rect (Input Rule 1: safe_bottom = 720).
public struct StoryLayout: Equatable, Sendable {
    /// "Tiếp" (right) and "Bỏ qua" (left): both ≥ pad_min tall on one row at safe_bottom − 18 (Input Rule 4).
    public let next, skip: Box
    /// The corner block's bottom + 8: no box may start above it.
    public let minTop: Double

    public init(pad: PadLayout) {
        let h = max(pad.padWorld, 96), y = pad.safeBottom + 8 - 18 - h // safeBottom carries the 8 margin
        next = Box(1262 - 340, y, 340, h)
        skip = Box(18, y, 240, h)
        minTop = pad.pause.cy + pad.pause.r + 8
    }

    /// A text panel centred on x 640, `box` + 2 × 32 wide, `height` tall, its bottom at Tiếp's top − 8.
    /// Beat card 235 (title row 60 + 8, 2 body lines), intro / caption / ending 167 (2 body lines).
    public func panel(box: Double, height: Double) -> Box {
        let w = box + 64
        return Box(640 - w / 2, next.y - 8 - height, w, height)
    }

    public static let cardHeight = 235.0, storyHeight = 167.0
    /// Dialogue (dialogue.md §5.2): the title row reserved on every line; speaker 286, narrator 235.
    public static let speakerHeight = 286.0, narratorHeight = 235.0, portraitSize = 256.0

    /// The dialogue panel and the portrait (hero left, others right; none for the narrator), 16 apart,
    /// the portrait bottom-aligned with the panel; the pair is centred on x 640.
    public func dialogue(speaker: String) -> (panel: Box, portrait: Box?) {
        if speaker == "narrator" { return (panel(box: 880, height: Self.narratorHeight), nil) }
        let pw = 720.0 + 64, total = Self.portraitSize + 16 + pw, x0 = 640 - total / 2
        let bottom = next.y - 8, top = bottom - Self.speakerHeight
        let heroLeft = speaker == "hero"
        let panel = Box(heroLeft ? x0 + Self.portraitSize + 16 : x0, top, pw, Self.speakerHeight)
        let portrait = Box(heroLeft ? x0 : x0 + pw + 16, bottom - Self.portraitSize, Self.portraitSize, Self.portraitSize)
        return (panel, portrait)
    }
}
