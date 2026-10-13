import Cocoa

var checks = 0
func check(_ condition: Bool, _ description: String) {
    checks += 1
    if !condition { fputs("FAIL: \(description)\n", stderr); exit(1) }
}
for locale in ["zh-TW", "zh-CN", "zh-HK", "zh-Hans-SG", "zh-Hant", "zh_MO"] { check(L.resolve(locale) == "zh", locale) }
for locale in ["ja-JP", "ko-KR", "de-DE", "de-CH"] { check(L.resolve(locale) == String(locale.prefix(2)), locale) }
for locale in ["en-US", "fr-FR", "ar-SA", "", "invalid"] { check(L.resolve(locale) == "en", locale) }
func sample(_ value: String) -> String {
    (0...9).reduce(value) { result, index in result.replacingOccurrences(of: "{\(index)}", with: "VALUE\(index)") }
}
for (index, code) in L.codes.enumerated() {
    L.select(code)
    for row in L.catalog { check(L.t(sample(row[0])) == sample(row[index]), "\(code): \(row[0])") }
}
L.select("en")
check(L.t("已執行送出點擊 2 輪；下個步驟剩 5 秒\n已貼上，等待點擊送出。 F8 可停止。") == "Send clicked for 2 rounds; next action in 5 s\nPasted; waiting to click Send. Press F8 to stop.", "Composed running status")
print("PASS: \(checks) macOS localization checks")
