import Foundation
import Testing

private func localizationDictionary(_ language: String) throws -> [String: String] {
    let testFile = URL(fileURLWithPath: #filePath)
    let projectRoot = testFile
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let file = projectRoot
        .appendingPathComponent("App/Resources/\(language).lproj/Localizable.strings")
    let data = try Data(contentsOf: file)
    let propertyList = try PropertyListSerialization.propertyList(from: data, format: nil)
    return propertyList as! [String: String]
}

private func projectRootURL() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

@Test func englishAndChineseLocalizationsHaveMatchingKeys() throws {
    let english = try localizationDictionary("en")
    let chinese = try localizationDictionary("zh-Hans")

    #expect(!english.isEmpty)
    #expect(Set(english.keys) == Set(chinese.keys))
}

@Test func localizationsContainRepresentativeTranslations() throws {
    let english = try localizationDictionary("en")
    let chinese = try localizationDictionary("zh-Hans")

    #expect(english["protection.enable"] == "Enable audio quality protection")
    #expect(chinese["protection.enable"] == "启用音质保护")
    #expect(english["about.message"] != chinese["about.message"])
}

@Test func everyLocalizationKeyReferencedBySourceExists() throws {
    let english = try localizationDictionary("en")
    let sourceDirectory = projectRootURL().appendingPathComponent("Sources/SoundAnchor")
    let files = try FileManager.default.contentsOfDirectory(
        at: sourceDirectory,
        includingPropertiesForKeys: nil
    ).filter { $0.pathExtension == "swift" }
    let pattern = #"L10n\.(?:text|format)\(\"([^\"]+)\""#
    let regex = try NSRegularExpression(pattern: pattern)
    var referencedKeys = Set<String>()

    for file in files {
        let source = try String(contentsOf: file, encoding: .utf8)
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        for match in regex.matches(in: source, range: range) {
            guard let keyRange = Range(match.range(at: 1), in: source) else { continue }
            referencedKeys.insert(String(source[keyRange]))
        }
    }

    #expect(referencedKeys.isSubset(of: Set(english.keys)))
}
