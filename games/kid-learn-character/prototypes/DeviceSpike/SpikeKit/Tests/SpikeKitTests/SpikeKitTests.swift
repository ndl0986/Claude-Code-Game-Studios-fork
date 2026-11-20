// PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike)
import Foundation
import Testing
@testable import SpikeKit

@Test func foldIsASCIIOnly() {
    #expect(KeyMap.foldASCII("d") == "D")
    #expect(KeyMap.foldASCII("7") == "7")
    #expect(KeyMap.foldASCII("é") == nil)
    #expect(KeyMap.foldASCII("в") == nil)
    #expect(KeyMap.foldASCII("ab") == nil)
}

@Test func characterFirstThenPosition() {
    // AZERTY: the key at US "Q" prints "a" → A (character first)
    let az = KeyMap.fromHID(usage: 0x14, characters: "a", modifiers: 0, kind: .down, isRepeat: false, time: 0)
    #expect(az.resolved == "A")
    // Cyrillic: the key at US "D" prints "в" → position fallback D
    let cy = KeyMap.fromHID(usage: 0x07, characters: "в", modifiers: 0, kind: .down, isRepeat: false, time: 0)
    #expect(cy.resolved == "D")
    // AZERTY digit row: "&" at US "1" → 1
    #expect(KeyMap.fromMac(keyCode: 18, characters: "&", modifiers: 0, kind: .down, isRepeat: false, time: 0).resolved == "1")
    // numpad 7 with Num Lock off still gives 7
    #expect(KeyMap.fromHID(usage: 0x5F, characters: nil, modifiers: 0, kind: .down, isRepeat: false, time: 0).resolved == "7")
    #expect(KeyMap.fromMac(keyCode: 89, characters: nil, modifiers: 0, kind: .down, isRepeat: false, time: 0).resolved == "7")
}

@Test func parentChord() {
    let q = { (m: Int) in KeyMap.fromMac(keyCode: 12, characters: "q", modifiers: m, kind: .down, isRepeat: false, time: 0) }
    #expect(KeyMap.isParentChord(q(Mod.ctrl | Mod.alt | Mod.cmd)))
    #expect(KeyMap.isParentChord(q(Mod.ctrl | Mod.alt | Mod.cmd | Mod.shift | Mod.caps)))
    #expect(!KeyMap.isParentChord(q(Mod.ctrl | Mod.alt)))
    #expect(!KeyMap.isParentChord(q(Mod.ctrl | Mod.alt | Mod.cmd | Mod.fn)))
}

@Test func stageFitMatchesRevealStageF1() {
    let f = StageFit(windowPxW: 2388, windowPxH: 1668)               // 11" iPad
    #expect(abs(f.scale - 1.865625) < 1e-9)
    #expect(abs(f.visibleY - -87.0) < 0.5 && abs(f.visibleH - 894.1) < 0.5)
    let w = StageFit(windowPxW: 3440, windowPxH: 1440)               // 21:9 Mac
    #expect(abs(w.scale - 2.0) < 1e-9 && abs(w.visibleX - -220) < 1e-9 && abs(w.visibleW - 1720) < 1e-9)
    let (x, y) = f.stagePoint(px: f.offsetX, f.offsetY)
    #expect(abs(x) < 1e-9 && abs(y) < 1e-9)
}

@Test func ppiUnknownTakesClassMaximum() {
    #expect(PPI.iPad(model: "iPad16,3") == (264, .table))
    #expect(PPI.iPad(model: "iPad13,4") == (264, .table))   // TASK-127 session iPad (logged 326 unknownClassMax before)
    #expect(PPI.iPad(model: "iPad99,9") == (PPI.iPadClassMax, .unknownClassMax))
    #expect(PPI.mac(pixelsW: 3456, mmW: 0).1 == .unknownClassMax)
    #expect(PPI.mac(pixelsW: 1000, mmW: 1000 / (72.0 / 25.4)).1 == .unknownClassMax)   // the no-EDID 72 dpi estimate
    let m = PPI.mac(pixelsW: 3456, mmW: 345.6)
    #expect(m.1 == .measured && abs(m.0 - 254) < 0.01)
}

let sample = """
<svg xmlns="http://www.w3.org/2000/svg" width="640" height="440" viewBox="0 0 640 440">
  <title>t</title>
  <g id="root" data-pivot="320 410">
    <g id="root_body" fill="#c4864a"><rect x="300" y="330" width="16" height="80" rx="8"/><ellipse cx="330" cy="302" rx="72" ry="50"/></g>
    <g id="root_outline" stroke="#2a2340" stroke-width="6" stroke-linejoin="round" fill="none" opacity="0.8"><path d="M 1 2 C 3 4 5 6 7 8 Z"/></g>
    <g id="root_detail"/>
    <g id="wing_far" data-pivot="312 282" transform="rotate(-14 312 282)">
      <g id="wing_far_body" fill="#e6b88a"><path d="M 312 282 L 400 282 Z"/></g>
      <g id="wing_far_outline"/><g id="wing_far_detail"/>
    </g>
  </g>
</svg>
"""

@Test func readsPartsLayersAndPivots() throws {
    let root = try SVGArt.parse(Data(sample.utf8))
    #expect(root.id == "root" && root.pivot == (320, 410) as (Double, Double) ? true : root.pivot.0 == 320)
    #expect(root.partIds == ["root", "wing_far"])
    var layers: [String] = []
    for item in root.items { if case .layer(let l) = item { layers.append(l.name) } }
    #expect(layers == ["body", "outline", "detail"])
    if case .layer(let outline) = root.items[1] { #expect(outline.shapes.first?.style.opacity == 0.8); #expect(outline.shapes.first?.style.stroke == 0x2a2340) }
    // the wing's rotate(-14 312 282) keeps the pivot fixed
    if case .part(let wing) = root.items[3], case .layer(let body) = wing.items[0], case .move(let x, let y) = body.shapes[0].ops[0] {
        #expect(abs(x - 312) < 1e-9 && abs(y - 282) < 1e-9)
    } else { Issue.record("wing not parsed") }
}

@Test func rejectsOutsideTheSubset() {
    #expect(throws: SVGArtError.self) { try SVGArt.parse(Data("<svg><g id=\"root\" data-pivot=\"0 0\"><g id=\"root_body\"><text>x</text></g></g></svg>".utf8)) }
    #expect(throws: SVGArtError.self) { try SVGArt.parse(Data("<svg><g id=\"root\" data-pivot=\"0 0\"><g id=\"neck_body\"/></g></svg>".utf8)) }
    #expect(throws: SVGArtError.self) { try SVGArt.parse(Data("<svg><g id=\"root\" data-pivot=\"0 0\"><g id=\"root_body\" fill=\"url(#g)\"/></g></svg>".utf8)) }
}
