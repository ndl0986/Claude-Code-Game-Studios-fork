import Foundation

/// A UI string from `content/data/strings.json` (ADR-0001): VI + EN, no claims.
public struct UiText: Codable, Equatable, Sendable {
    public let id: String
    public let vi: String
    public let en: String

    /// The string in the given language.
    public func text(_ language: Language) -> String { language == .vi ? vi : en }
}

/// The two languages the game ships in, Vietnamese first.
public enum Language: String, Codable, Sendable { case vi, en }

/// `content/data/strings.json`.
public struct StringsFile: Codable, Sendable {
    public let schema_version: String
    public let strings: [UiText]

    /// Decodes the file from JSON data.
    public static func decode(_ data: Data) throws -> StringsFile {
        try JSONDecoder().decode(StringsFile.self, from: data)
    }

    /// The string with this id, or nil.
    public func string(_ id: String) -> UiText? { strings.first { $0.id == id } }
}
