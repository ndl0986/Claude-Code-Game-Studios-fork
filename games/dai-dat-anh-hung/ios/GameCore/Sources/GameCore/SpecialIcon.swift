/// TASK-023 W17: the special pad's glyph. The hold-meter beat's pad shows a clenched fist (the hero's hand in the
/// orange moment); every other beat that has the pad (training's finish) shows the banner. The pad's label stays
/// `ui.pad.special` until D-34. Same rule as Android r14 `SpecialIcon`.
public enum SpecialIcon: Sendable, Equatable {
    case banner, fist

    /// The glyph for a beat of this type.
    public static func forBeat(type: String?) -> SpecialIcon { type == "hold-meter" ? .fist : .banner }
}

extension PlayState {
    /// The special pad's glyph for the current beat (W17).
    public var specialIcon: SpecialIcon { SpecialIcon.forBeat(type: currentBeat?.type) }
}
