#if DEBUG
/// Debug builds only (compiled out of Release): the whole-mission bot, shared by the GameCore tests and the app's
/// `-autoplay` (r9 UI case D, the medal under a mash in a real run). The app feeds it only to play beats while no
/// story box is up; every story and quiz press stays a real touch.
/// A simple player for whole-mission tests: walks right, holds special in hold-meter, clears
/// training in order, turns toward the nearest enemy and swings. Story boxes are confirmed.
public func botInput(_ p: PlayState, step: Int) -> StepInput {
    if p.phase == .caption { return StepInput(confirm: true) }
    if p.phase == .beatPlay, let b = p.currentBeat {
        if b.type == "hold-meter" { return StepInput(held: [.special]) }
        if b.type == "training" {
            switch p.trainingStage {
            case .dummies:
                guard let d = p.dummies.first(where: { !$0.hit }) else { return StepInput() }
                let dx = d.x - p.hero.x
                if dx > 150 || dx < 0 { return StepInput(held: [dx > 0 ? .right : .left]) }
                return StepInput(tapped: step % 3 == 0 ? [.attack] : [])
            case .blocks: return StepInput(held: [.defend])
            case .special: return StepInput(tapped: [.special])
            case .done: return StepInput()
            }
        }
    }
    guard let e = p.enemies.filter({ $0.state != .flee }).min(by: { abs($0.x - p.hero.x) < abs($1.x - p.hero.x) }) else {
        return StepInput(held: [.right])
    }
    let dx = e.x - p.hero.x
    let dir: PadAction = dx >= 0 ? .right : .left
    if (dx >= 0 ? 1.0 : -1.0) != p.hero.face { return StepInput(held: [dir]) }
    if abs(dx) > 170 { return StepInput(held: [dir]) }
    return StepInput(tapped: step % 3 == 0 ? [.attack] : [])
}
#endif
