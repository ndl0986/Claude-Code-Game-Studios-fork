import SwiftUI

/// The app entry (App Shell R1): one window showing the blank Title on the stage (TASK-079 S1).
@main
struct LetterMorphApp: App {
    /// The launch time on the uptime clock (App Shell R1; ADR-0002 D3). Later stories hand this clock to KidCore.
    let launchUptime = SystemUptimeClock().now()

    var body: some Scene {
        WindowGroup {
            StageContainer()
                #if os(macOS)
                .frame(minWidth: 960, minHeight: 540) // App Shell R7: the smallest Mac window
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentMinSize)
        .restorationBehavior(.disabled) // Settings Store R2: no window restoration
        #endif
    }
}

/// The stage with nothing on it yet; later stories add the gate and panel as overlays in this same window
/// (ADR-0006 D1).
struct StageContainer: View {
    var body: some View {
        StageView()
            .ignoresSafeArea()
            #if os(iOS)
            // K-39: during play the status bar and home indicator are hidden and the system edge gestures need a
            // second swipe. Guided Access stays the real lock.
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
            .defersSystemGestures(on: .all)
            #endif
    }
}
