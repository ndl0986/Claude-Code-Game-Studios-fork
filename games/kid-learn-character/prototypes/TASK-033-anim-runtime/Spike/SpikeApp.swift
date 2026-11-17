// PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
// The shell: a runtime switch (SpriteKit / Rive), the stage, three big keys (D, B, 3) and a status line.
import SwiftUI
import SpriteKit
#if !NORIVE
import RiveRuntime
#endif

@main
struct SpikeApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
        #if os(macOS)
        .defaultSize(width: 1194, height: 834)
        #endif
    }
}

struct ContentView: View {
    @StateObject private var c = SpikeController()
    @State private var scene: MorphScene?
    #if !NORIVE
    @State private var rive: RiveStage?
    #endif

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.15, blue: 0.30).ignoresSafeArea()
            stageView.ignoresSafeArea()
            VStack {
                HStack {
                    #if !NORIVE
                    Picker("Runtime", selection: $c.runtime) { Text("A  SpriteKit").tag("spritekit"); Text("B  Rive").tag("rive") }
                        .pickerStyle(.segmented).frame(width: 320)
                    #else
                    Text("A  SpriteKit (no Rive build)").foregroundStyle(.white)
                    #endif
                    Spacer()
                    Text(c.status).font(.system(size: 13, design: .monospaced)).foregroundStyle(.white.opacity(0.8)).lineLimit(3)
                    Button("Log") { c.dumpNow() }
                }.padding()
                Spacer()
                HStack(spacing: 24) {
                    ForEach(c.keys, id: \.self) { k in
                        TouchKey(key: k) { key, t in c.press(key, source: "touch", at: t) }.frame(width: 150, height: 150)
                    }
                }.padding(.bottom, 32)
            }
            KeyCatcher { key, t in c.press(key, source: "hardware", at: t) }.allowsHitTesting(false)
        }
        .onAppear {
            let s = MorphScene(spec: c.spec); s.controller = c; scene = s
            #if !NORIVE
            rive = RiveStage(controller: c)
            #endif
            attachStage()
            c.startAutomation()
        }
        .onChange(of: c.runtime) { attachStage() }
    }

    @ViewBuilder var stageView: some View {
        #if !NORIVE
        if c.runtime == "rive", let r = rive { r.vm.view() } else if let s = scene { SpriteView(scene: s, debugOptions: [.showsFPS, .showsNodeCount]) }
        #else
        if let s = scene { SpriteView(scene: s, debugOptions: [.showsFPS, .showsNodeCount]) }
        #endif
    }

    private func attachStage() {
        #if !NORIVE
        if c.runtime == "rive" { c.stage = rive; return }
        #endif
        c.stage = scene
    }
}
