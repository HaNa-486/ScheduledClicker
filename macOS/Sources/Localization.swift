import Cocoa

// UI translation only. Prompt text and scheduler data are never passed through this boundary.
enum L {
    static let codes = ["zh", "en", "ja", "ko", "de"]
    static let names = ["繁體中文", "English", "日本語", "한국어", "Deutsch"]
    static private(set) var language = resolve(Locale.preferredLanguages.first ?? "en")
    static let changed = Notification.Name("ScheduledClickerLanguageChanged")
    static func resolve(_ locale: String) -> String {
        let code = locale.replacingOccurrences(of: "_", with: "-").split(separator: "-").first.map(String.init)?.lowercased() ?? ""
        return ["zh", "ja", "ko", "de"].contains(code) ? code : "en"
    }
    static func select(_ code: String) {
        guard codes.contains(code), code != language else { return }
        language = code; NotificationCenter.default.post(name: changed, object: nil)
    }
    private static let lookup = Dictionary(uniqueKeysWithValues: catalog.map { ($0[0], $0) })
    private static let token = try! NSRegularExpression(pattern: #"\{(\d+)\}"#)
    private struct Template {
        let row: [String]
        let regex: NSRegularExpression
        let indices: [String]
        init(_ row: [String]) {
            self.row = row
            let key = row[0] as NSString
            var pattern = "^", end = 0, indices = [String]()
            for match in token.matches(in: row[0], range: NSRange(location: 0, length: key.length)) {
                pattern += NSRegularExpression.escapedPattern(for: key.substring(with: NSRange(location: end, length: match.range.location - end))) + "(.*?)"
                indices.append(key.substring(with: match.range(at: 1))); end = NSMaxRange(match.range)
            }
            pattern += NSRegularExpression.escapedPattern(for: key.substring(from: end)) + "$"
            regex = try! NSRegularExpression(pattern: pattern); self.indices = indices
        }
    }
    private static let templates = catalog.filter { $0[0].contains("{0}") }.sorted {
        token.stringByReplacingMatches(in: $0[0], range: NSRange(location: 0, length: ($0[0] as NSString).length), withTemplate: "").count > token.stringByReplacingMatches(in: $1[0], range: NSRange(location: 0, length: ($1[0] as NSString).length), withTemplate: "").count
    }.map(Template.init)
    private static let literals = try! NSRegularExpression(pattern: catalog.filter { !$0[0].contains("{0}") }.sorted { $0[0].count > $1[0].count }.map { NSRegularExpression.escapedPattern(for: $0[0]) }.joined(separator: "|"))

    static func t(_ source: String) -> String { render(source, depth: 0) }
    private static func render(_ source: String, depth: Int) -> String {
        guard language != "zh", !source.isEmpty, depth <= 8 else { return source }
        let column = codes.firstIndex(of: language)!
        if let row = lookup[source] { return row[column] }
        if source.contains("\n") { return source.components(separatedBy: "\n").map { render($0, depth: depth + 1) }.joined(separator: "\n") }
        let raw = source as NSString
        for template in templates {
            guard let match = template.regex.firstMatch(in: source, range: NSRange(location: 0, length: raw.length)) else { continue }
            var arguments = [String: String]()
            for (index, number) in template.indices.enumerated() { arguments[number] = render(raw.substring(with: match.range(at: index + 1)), depth: depth + 1) }
            let translated = template.row[column] as NSString
            let result = NSMutableString(string: template.row[column])
            for item in token.matches(in: template.row[column], range: NSRange(location: 0, length: translated.length)).reversed() {
                result.replaceCharacters(in: item.range, with: arguments[translated.substring(with: item.range(at: 1))] ?? "")
            }
            return result as String
        }
        let result = NSMutableString(string: source)
        for match in literals.matches(in: source, range: NSRange(location: 0, length: raw.length)).reversed() {
            result.replaceCharacters(in: match.range, with: lookup[raw.substring(with: match.range)]![column])
        }
        return result as String
    }
}

final class LanguagePicker: NSObject {
    let view = NSPopUpButton()
    private var observer: NSObjectProtocol?
    override init() {
        super.init()
        view.addItems(withTitles: L.names); view.selectItem(at: L.codes.firstIndex(of: L.language)!)
        view.setAccessibilityLabel("Language"); view.target = self; view.action = #selector(selectLanguage)
        observer = NotificationCenter.default.addObserver(forName: L.changed, object: nil, queue: .main) { [weak self] _ in self?.view.selectItem(at: L.codes.firstIndex(of: L.language)!) }
    }
    @objc private func selectLanguage() { L.select(L.codes[view.indexOfSelectedItem]) }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
}

// Bind static view text once; dynamic status fields are explicitly excluded by each window.
final class LocalizedView {
    private var updates: [() -> Void] = []
    private var observer: NSObjectProtocol?
    init(root: NSView, excluding: [NSView]) {
        bind(root, excluded: Set(excluding.map(ObjectIdentifier.init)))
        observer = NotificationCenter.default.addObserver(forName: L.changed, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        refresh()
    }
    init(window: NSWindow, excluding: [NSView]) {
        let title = window.title
        updates.append { [weak window] in window?.title = L.t(title) }
        if let root = window.contentView { bind(root, excluded: Set(excluding.map(ObjectIdentifier.init))) }
        observer = NotificationCenter.default.addObserver(forName: L.changed, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        refresh()
    }
    private func bind(_ view: NSView, excluded: Set<ObjectIdentifier>) {
        guard !excluded.contains(ObjectIdentifier(view)) else { return }
        if let popup = view as? NSPopUpButton {
            let titles = popup.itemTitles
            updates.append { [weak popup] in for (index, title) in titles.enumerated() { popup?.item(at: index)?.title = L.t(title) } }
        } else if let segments = view as? NSSegmentedControl {
            let titles = (0..<segments.segmentCount).map { segments.label(forSegment: $0) ?? "" }
            updates.append { [weak segments] in for (index, title) in titles.enumerated() { segments?.setLabel(L.t(title), forSegment: index) } }
        } else if let button = view as? NSButton {
            let title = button.title; updates.append { [weak button] in button?.title = L.t(title) }
        } else if let field = view as? NSTextField, !field.isEditable {
            let title = field.stringValue; updates.append { [weak field] in field?.stringValue = L.t(title) }
        }
        if let tooltip = view.toolTip { updates.append { [weak view] in view?.toolTip = L.t(tooltip) } }
        if let label = view.accessibilityLabel() { updates.append { [weak view] in view?.setAccessibilityLabel(L.t(label)) } }
        for child in view.subviews { bind(child, excluded: excluded) }
    }
    func refresh() { updates.forEach { $0() } }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
}
