import Foundation
import GameCore

/// Where the bundled `content/data/` folder lives in the app (a folder reference named `data`).
struct ContentBundle {
    let root: URL

    /// The app bundle's copy of content/data.
    static let main = ContentBundle(root: Bundle.main.bundleURL.appendingPathComponent("data"))

    /// UI strings, or nil if the file is missing or invalid (logged).
    func strings() -> StringsFile? {
        do {
            return try StringsFile.decode(Data(contentsOf: root.appendingPathComponent("strings.json")))
        } catch {
            NSLog("[content] strings.json failed to load: \(error)")
            return nil
        }
    }
}
