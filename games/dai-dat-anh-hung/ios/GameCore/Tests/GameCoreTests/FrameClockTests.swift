import XCTest
@testable import GameCore

/// iOS r10 N1 (parity with Android r13 FrameClockTest): the app's fixed-step clock. The frame that leaves the pause
/// screen credits no time and drops the carried remainder, so the banner moment holds its full 0.833 s after a resume.
final class FrameClockTests: XCTestCase {
    let step = 1.0 / 60

    // (a)
    func test_the_first_frame_runs_no_steps() {
        var f = FrameClock()
        XCTAssertEqual(f.frame(100), 0)
        XCTAssertEqual(f.dt, 0)
        XCTAssertEqual(f.acc, 0)
    }

    // (b)
    func test_sixty_hertz_runs_one_step_a_frame_and_long_or_backward_frames_are_clamped() {
        var f = FrameClock()
        _ = f.frame(0)
        for k in 1...120 { XCTAssertEqual(f.frame(Double(k) * step), 1, "frame \(k)") }
        let t = 120 * step
        XCTAssertEqual(f.frame(t + 5), 15, "a 5 s stall credits only maxDt = 0.25 s")
        XCTAssertEqual(f.dt, 0.25, accuracy: 1e-12)
        XCTAssertEqual(f.frame(t + 4), 0, "a frame time going backward credits nothing")
        XCTAssertEqual(f.dt, 0)
    }

    func test_the_debug_scale_applies_before_the_accumulator() {
        var f = FrameClock()
        _ = f.frame(0)
        var n = 0
        for k in 1...600 { n += f.frame(Double(k) * step, scale: 0.1) }
        XCTAssertEqual(n, 60, "×0.1: ten seconds of frames run one second of steps")
    }

    // (c)
    func test_a_resume_frame_runs_no_steps_and_drops_the_remainder() {
        var f = FrameClock()
        _ = f.frame(0)
        XCTAssertEqual(f.frame(1.9 * step), 1)
        XCTAssertEqual(f.acc, 0.9 * step, accuracy: 1e-12)
        XCTAssertEqual(f.frame(3.4 * step, leftPause: true), 0, "1.5 steps of frame time and 0.9 carried: all dropped")
        XCTAssertEqual(f.acc, 0)
        XCTAssertEqual(f.dt, 0)
        XCTAssertEqual(f.frame(4.4 * step), 1, "only time after the resume frame counts")
    }

    // (d)
    func test_after_a_resume_sim_time_never_runs_ahead_of_wall_time() {
        var f = FrameClock()
        var t = 0.0
        _ = f.frame(t)
        t += 1.95 * step; _ = f.frame(t) // a remainder to carry
        t += 1.3 * step
        _ = f.frame(t, leftPause: true)
        let resumedAt = t
        var sim = 0.0
        let jitter = [0.0, 0.001, 0.002]
        for k in 0..<240 {
            t += step + jitter[k % 3] // vsyncs late by 0/1/2 ms
            sim += Double(f.frame(t)) * step
            let wall = t - resumedAt
            XCTAssertLessThanOrEqual(sim, wall + 1e-9, "frame \(k + 1): sim never ahead of wall time since the resume")
            XCTAssertGreaterThan(sim, wall - step - 1e-9, "frame \(k + 1): sim within one step of wall time")
        }
    }

    // (e)
    func test_driven_through_game_the_banner_moment_ends_50_frames_after_the_resume_frame() throws {
        let c = try ContentSet.load(dataRoot: Repo.data), hero = realHero(c)
        for wasRemainder in [0.0, 0.5, 0.9] {
            let g = Game(content: c, hero: hero, store: MemoryStore(), isDebug: true)
            g.debugStart(screen: "play", q: nil, beat: beatIndex(hero, "training") + 1, stage: "finish", stars: nil)
            var f = FrameClock(), t = 10.0, wasPaused = false
            /// One display frame, the way GameScene.update runs it.
            func frame(_ dt: Double, _ input: StepInput = StepInput()) -> Int {
                t += dt
                let leftPause = wasPaused && g.screen != .pause
                wasPaused = g.screen == .pause
                let n = f.frame(t, leftPause: leftPause)
                for i in 0..<n { g.step(f.step, i == 0 ? input : StepInput()) }
                return n
            }
            _ = frame(0); _ = frame(step)
            _ = frame(step, StepInput(tapped: [.special]))
            XCTAssertNotNil(g.play.finishHold); XCTAssertEqual(g.play.phase, .beatEnd)
            for _ in 0..<18 { _ = frame(step) } // 0.3 s into the hold, during the rise
            _ = frame((1 + wasRemainder) * step) // a late frame leaves a remainder carried
            g.pause()
            for _ in 0..<30 { _ = frame(step) } // the pause screen
            _ = frame(0.7 * step) // and a remainder while paused
            g.resume() // the tap, between frames
            XCTAssertEqual(g.play.endT, PlayState.finishRise, accuracy: 1e-9)
            XCTAssertEqual(frame(1.6 * step), 0, "remainder \(wasRemainder): the resume frame runs no steps")
            var frames = 0
            while g.play.phase == .beatEnd && frames < 600 { _ = frame(step); frames += 1 }
            XCTAssertEqual(frames, 50, "remainder \(wasRemainder): banner-up ends 50 frames (0.833 s) after the resume frame")
        }
    }
}
