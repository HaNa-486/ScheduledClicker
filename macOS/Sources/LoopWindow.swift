import Cocoa

final class LoopWindow: NSObject, NSTextViewDelegate {
    let window: NSWindow
    let view = ModeContentView(frame: NSRect(x: 0, y: 0, width: 1040, height: 600))
    var busy: Bool { engine.active || captureKind != 0 }
    var onBusyChanged: (() -> Void)?
    private var lastBusy = false
    private let input = NativeLoopInput()
    private lazy var engine = LoopEngine(actions: input, completionClock: { ProcessInfo.processInfo.systemUptime })
    private var timer: Timer?
    private var globalKey: Any?
    private var localKey: Any?
    private var sleepObserver: NSObjectProtocol?
    private var captureKind = 0
    private var captureDue: TimeInterval = 0
    private var prompts = [L.t("繼續")]
    private var editingIndex = 0
    private var loading = false
    private var localized: LocalizedView?
    private var languageObserver: NSObjectProtocol?
    private let notice = NSTextField(wrappingLabelWithString: "執行時保持喚醒、不鎖屏，目標視窗與聊天固定。\n使用剪貼簿貼上，會覆寫剪貼簿；不判斷 AI 狀態或送達結果。\n試跑會真的輸入並點送出。中途停止後請檢查草稿，避免重複。\n兩個停止條件同時勾選時，先達到者停止。關閉本視窗也會取消。")
    private var controls: [NSControl] = []
    private let first = NSDatePicker()
    private let deadline = NSDatePicker()
    private let hours = NSTextField(string: "5")
    private let minutes = NSTextField(string: "10")
    private let seconds = NSTextField(string: "0")
    private let wait = NSTextField(string: "1")
    private let count = NSTextField(string: "3")
    private let countBound = NSButton(checkboxWithTitle: "最多輪次", target: nil, action: nil)
    private let timeBound = NSButton(checkboxWithTitle: "截止時間", target: nil, action: nil)
    private let repeatLast = NSButton(checkboxWithTitle: "序列用完後，重複最後一筆", target: nil, action: nil)
    private let replace = NSButton(checkboxWithTitle: "取代輸入框原有文字（預設保留並插入）", target: nil, action: nil)
    private let mode = NSPopUpButton()
    private let entries = NSPopUpButton()
    private let editor = NSTextView()
    private let add = NSButton(title: "新增一輪", target: nil, action: nil)
    private let remove = NSButton(title: "刪除此輪", target: nil, action: nil)
    private let inputLabel = NSTextField(labelWithString: "尚未擷取")
    private let sendLabel = NSTextField(labelWithString: "尚未擷取")
    private let start = NSButton(title: "啟動循環", target: nil, action: nil)
    private let trial = NSButton(title: "試跑一輪", target: nil, action: nil)
    private let pause = NSButton(title: "暫停", target: nil, action: nil)
    private let cancel = NSButton(title: "取消 / 停止", target: nil, action: nil)
    private let status = NSTextField(wrappingLabelWithString: "等待設定。")
    private static var mono: TimeInterval { ProcessInfo.processInfo.systemUptime }

    init(window: NSWindow) {
        self.window = window
        super.init()
        build()
        localized = LocalizedView(root: view, excluding: [status, pause, inputLabel, sendLabel, entries, editor])
        languageObserver = NotificationCenter.default.addObserver(forName: L.changed, object: nil, queue: .main) { [weak self] _ in self?.languageChanged() }
        refreshEntries(selected: 0)
        view.isHidden = true
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.stop("電腦即將睡眠，排程已停止，不補送。")
        }
        languageChanged()
    }

    deinit {
        timer?.invalidate(); removeKeys()
        if let languageObserver { NotificationCenter.default.removeObserver(languageObserver) }
        if let sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver) }
    }

    private func startTimer() {
        guard timer?.isValid != true else { return }
        let tick = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(tick, forMode: .common); timer = tick
    }
    func show() { view.isHidden = false; startTimer(); refresh() }
    func hide() { guard !busy else { return }; view.isHidden = true; timer?.invalidate(); timer = nil }
    func shutdown() { captureKind = 0; stop("程式已結束。"); timer?.invalidate(); timer = nil; removeKeys() }
    func stop(_ message: String) { engine.stop(message); refresh() }

    private func build() {
        let root = view
        root.addSubview(NativeUI.card("", frame: NSRect(x: 16, y: 0, width: 596, height: 200)))
        root.addSubview(NativeUI.card("", frame: NSRect(x: 624, y: 0, width: 400, height: 200)))
        root.addSubview(NativeUI.card("", frame: NSRect(x: 16, y: 208, width: 1008, height: 194)))
        func label(_ text: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 205, heading: Bool = false) {
            root.addSubview(NativeUI.label(text, frame: NSRect(x: x, y: y, width: width, height: 22), heading: heading))
        }
        func place(_ control: NSControl, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat) {
            control.frame = NSRect(x: x, y: y, width: width, height: 28); root.addSubview(control); controls.append(control)
        }
        label("首次時間與循環間隔", 28, 7, 560, heading: true)
        label("位置擷取", 636, 7, 370, heading: true)
        for date in [first, deadline] { date.datePickerStyle = .textFieldAndStepper; date.datePickerElements = [.yearMonthDay, .hourMinuteSecond] }
        first.dateValue = Date().addingTimeInterval(60); deadline.dateValue = Date().addingTimeInterval(86400)
        first.setAccessibilityLabel("首次執行时间"); deadline.setAccessibilityLabel("截止時間")
        label("首次執行", 28, 38); place(first, 240, 32, 300)
        label("每輪結束後等", 28, 72); place(hours, 240, 66, 54); label("時", 300, 72, 40)
        place(minutes, 348, 66, 54); label("分", 408, 72, 40); place(seconds, 456, 66, 54); label("秒", 516, 72, 50)
        hours.setAccessibilityLabel("循環間隔小時"); minutes.setAccessibilityLabel("循環間隔分鐘"); seconds.setAccessibilityLabel("循環間隔秒數")
        label("點擊／貼上之間等待", 28, 106); place(wait, 240, 100, 60); label("秒（1–10）", 310, 106)
        wait.setAccessibilityLabel("步驟等待秒數")
        countBound.state = .on; place(countBound, 28, 134, 205); place(count, 240, 134, 80); label("輪", 330, 140)
        count.setAccessibilityLabel("最多執行輪次")
        place(timeBound, 28, 170, 205); place(deadline, 240, 170, 300)
        countBound.target = self; countBound.action = #selector(optionsChanged)
        timeBound.target = self; timeBound.action = #selector(optionsChanged)
        label("請擷取同一視窗內的兩個位置", 636, 36, 370)
        let inputButton = NSButton(title: "擷取輸入框（3 秒）", target: self, action: #selector(captureInput))
        let sendButton = NSButton(title: "擷取送出鈕（3 秒）", target: self, action: #selector(captureSend))
        inputButton.bezelStyle = .rounded; sendButton.bezelStyle = .rounded
        place(inputButton, 636, 65, 285); place(inputLabel, 640, 98, 355)
        place(sendButton, 636, 133, 285); place(sendLabel, 640, 166, 355)
        label("提示詞", 28, 213, 180, heading: true)
        mode.addItems(withTitles: ["每輪相同", "依輪次設定"]); place(mode, 28, 237, 240)
        mode.target = self; mode.action = #selector(modeChanged)
        place(entries, 28, 274, 160); entries.target = self; entries.action = #selector(entryChanged)
        place(add, 278, 237, 175); add.target = self; add.action = #selector(addPrompt)
        place(remove, 463, 237, 175); remove.target = self; remove.action = #selector(removePrompt)
        let textScroll = NSScrollView(frame: NSRect(x: 196, y: 272, width: 812, height: 72))
        textScroll.hasVerticalScroller = true; textScroll.borderType = .bezelBorder
        editor.frame = NSRect(x: 0, y: 0, width: 792, height: 72)
        editor.isRichText = false; editor.isAutomaticQuoteSubstitutionEnabled = false; editor.isAutomaticDashSubstitutionEnabled = false
        editor.font = .systemFont(ofSize: 13); editor.delegate = self; editor.autoresizingMask = [.width]
        editor.isVerticallyResizable = true; editor.textContainer?.widthTracksTextView = true
        editor.setAccessibilityLabel("目前輪次提示詞"); textScroll.documentView = editor; root.addSubview(textScroll)
        place(repeatLast, 28, 346, 970); place(replace, 28, 372, 970)
        notice.frame = NSRect(x: 16, y: 410, width: 1008, height: 74)
        notice.font = .systemFont(ofSize: 12.5); notice.drawsBackground = true; notice.backgroundColor = .controlBackgroundColor; root.addSubview(notice)
        for (index, button) in [start, trial, pause, cancel].enumerated() {
            button.frame = NSRect(x: CGFloat(16 + index * 205), y: 490, width: 195, height: 34)
            button.bezelStyle = .rounded; button.target = self; root.addSubview(button)
        }
        start.bezelColor = .systemBlue
        start.action = #selector(startLoop); trial.action = #selector(trialLoop); pause.action = #selector(togglePause); cancel.action = #selector(cancelLoop)
        status.frame = NSRect(x: 20, y: 530, width: 1000, height: 68); status.font = .systemFont(ofSize: 12.5); root.addSubview(status)
    }

    private func languageChanged() {
        first.locale = Locale(identifier: L.language == "zh" ? "zh-Hant" : L.language)
        deadline.locale = first.locale
        for index in prompts.indices { entries.item(at: index)?.title = L.t("第 \(index + 1) 輪") }
        if input.input == nil { inputLabel.stringValue = L.t("尚未擷取") }
        if input.submit == nil { sendLabel.stringValue = L.t("尚未擷取") }
        refresh()
    }

    func textDidChange(_ notification: Notification) { if !loading { prompts[editingIndex] = editor.string } }
    private func refreshEntries(selected: Int) {
        loading = true; entries.removeAllItems()
        entries.addItems(withTitles: prompts.indices.map { L.t("第 \($0 + 1) 輪") }); entries.selectItem(at: selected)
        editingIndex = selected; editor.string = prompts[selected]; loading = false; refresh()
    }
    @objc private func modeChanged() { refreshEntries(selected: 0) }
    @objc private func entryChanged() { refreshEntries(selected: entries.indexOfSelectedItem) }
    @objc private func optionsChanged() { refresh() }
    @objc private func addPrompt() { prompts.append(""); refreshEntries(selected: prompts.count - 1) }
    @objc private func removePrompt() { if prompts.count > 1 { prompts.remove(at: editingIndex); refreshEntries(selected: min(editingIndex, prompts.count - 1)) } }
    @objc private func captureInput() { capture(1) }
    @objc private func captureSend() { capture(2) }
    private func capture(_ kind: Int) { captureKind = kind; captureDue = Self.mono + 3; refresh(); window.miniaturize(nil) }

    private func tick() {
        if captureKind != 0 && Self.mono >= captureDue {
            do {
                guard let point = MacMouse.currentLocation() else { throw loopError("無法讀取滑鼠位置。") }
                let target = try LoopTarget.capture(point)
                guard target.process != ProcessInfo.processInfo.processIdentifier else { throw loopError("請擷取外部目標視窗。") }
                let label = "X \(Int(point.x)) / Y \(Int(point.y))"
                if captureKind == 1 { input.input = target; inputLabel.stringValue = label }
                else { input.submit = target; sendLabel.stringValue = label }
                engine.stop("位置已擷取。")
            } catch { engine.stop(error.localizedDescription) }
            captureKind = 0; window.deminiaturize(nil); show()
        }
        engine.tick(wall: Date(), mono: Self.mono); refresh()
    }
    @objc private func startLoop() { arm(test: false) }
    @objc private func trialLoop() { arm(test: true) }
    @objc private func togglePause() {
        engine.togglePause(wall: Date(), mono: Self.mono); refresh()
        if engine.active && !engine.paused { window.miniaturize(nil) }
    }
    @objc private func cancelLoop() { captureKind = 0; stop("已取消排程。") }

    private func number(_ field: NSTextField, _ range: ClosedRange<Int>, _ name: String) throws -> Int {
        guard let value = Int(field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)), range.contains(value) else {
            throw loopError("\(name)須介於 \(range.lowerBound)–\(range.upperBound)。")
        }
        return value
    }
    private func arm(test: Bool) {
        do {
            window.makeFirstResponder(nil)
            let interval = try number(hours, 0...8760, "小時") * 3600 + number(minutes, 0...59, "分鐘") * 60 + number(seconds, 0...59, "秒數")
            var plan = LoopPlan(firstTime: test ? Date().addingTimeInterval(5) : first.dateValue, interval: TimeInterval(interval),
                stepDelay: TimeInterval(try number(wait, 1...10, "步驟等待")),
                maxRounds: test ? 1 : (countBound.state == .on ? try number(count, 1...10000, "輪次") : nil),
                deadline: test ? nil : (timeBound.state == .on ? deadline.dateValue : nil), prompts: prompts,
                sequence: mode.indexOfSelectedItem == 1, repeatLast: repeatLast.state == .on, replaceDraft: replace.state == .on)
            try input.prepare()
            if let error = plan.validate(now: Date()) { throw loopError(error) }
            let formatter = DateFormatter(); formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            let bounds = (plan.maxRounds.map { "\($0) 輪" } ?? "不限輪數") + (plan.deadline.map { "；截止 " + formatter.string(from: $0) } ?? "")
            let alert = NSAlert(); alert.messageText = "確認循環操作"
            alert.informativeText = (test ? "試跑：確認後 5 秒執行一輪。" : "首次：\(formatter.string(from: plan.firstTime))\n間隔：\(interval) 秒（每輪結束後起算）\n停止：\(bounds)")
                + "\n提示詞：" + (plan.sequence ? "依輪次設定（\(prompts.count) 筆）" + (plan.repeatLast ? "重複最後一筆" : "用完即停") : "每輪相同")
                + "\n輸入框：\(inputLabel.stringValue)；送出鈕：\(sendLabel.stringValue)"
                + "\n\n將真的輸入並點擊送出，會覆寫剪貼簿。\n" + (plan.replaceDraft ? "會取代輸入框原有文字。" : "會在游標位置插入，請先檢查草稿。")
                + "\n請保持目標視窗／聊天不變。未驗證 AI 狀態或送達。"
            alert.messageText = L.t(alert.messageText); alert.informativeText = L.t(alert.informativeText)
            alert.addButton(withTitle: L.t("啟動")); alert.addButton(withTitle: L.t("取消"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            guard AXIsProcessTrustedWithOptions(options) else { throw loopError("請在系統設定授予輔助使用權限後重新啟動。") }
            installKeys()
            guard globalKey != nil, localKey != nil else { throw loopError("F8 監聽不可用，請檢查輔助使用權限。") }
            if test { plan.firstTime = Date().addingTimeInterval(5) }
            try engine.start(plan, wall: Date(), mono: Self.mono)
            refresh(); window.miniaturize(nil)
        } catch {
            removeKeys()
            let alert = NSAlert(); alert.messageText = L.t("無法啟動"); alert.informativeText = L.t(error.localizedDescription); alert.addButton(withTitle: L.t("確定")); alert.runModal()
        }
    }
    private func refresh() {
        let busy = engine.active || captureKind != 0
        controls.forEach { $0.isEnabled = !busy }; editor.isEditable = !busy
        let sequence = mode.indexOfSelectedItem == 1
        entries.isEnabled = !busy && sequence; add.isEnabled = !busy && sequence && prompts.count < 10000
        remove.isEnabled = !busy && sequence && prompts.count > 1; repeatLast.isEnabled = !busy && sequence
        count.isEnabled = !busy && countBound.state == .on; deadline.isEnabled = !busy && timeBound.state == .on
        start.isEnabled = !busy; trial.isEnabled = !busy; pause.isEnabled = engine.active; cancel.isEnabled = busy
        pause.title = L.t(engine.paused ? "恢復" : (engine.betweenRounds ? "暫停" : "停止本輪"))
        let left = engine.active && !engine.paused ? "；下個步驟剩 \(Int(max(0, engine.remaining(wall: Date(), mono: Self.mono).rounded(.up)))) 秒" : ""
        status.stringValue = captureKind != 0 ? "請把滑鼠移到目標位置，倒數 \(Int(max(0, (captureDue - Self.mono).rounded(.up)))) 秒。" : "已執行送出點擊 \(engine.completed) 輪\(left)\n\(engine.status)" + (engine.active ? " F8（或 Fn+F8）可停止。" : "")
        status.stringValue = L.t(status.stringValue)
        if !engine.active { removeKeys() }
        if lastBusy != busy { lastBusy = busy; onBusyChanged?() }
    }
    private func installKeys() {
        removeKeys()
        globalKey = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 100 { self?.stop("已用 F8 緊急停止。") }
        }
        localKey = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 100 else { return event }
            self?.stop("已用 F8 緊急停止。"); return nil
        }
    }
    private func removeKeys() {
        if let globalKey { NSEvent.removeMonitor(globalKey) }; globalKey = nil
        if let localKey { NSEvent.removeMonitor(localKey) }; localKey = nil
    }

    // No native input: exercise editor state and render both appearances in CI.
    func smokeTest(screenshot: String?, switchMode: (Bool) -> Bool) -> Bool {
        mode.selectItem(at: 1); modeChanged()
        addPrompt(); editor.string = "第二輪：繼續\n保留進度 😀"; textDidChange(Notification(name: NSText.didChangeNotification))
        mode.selectItem(at: 0); modeChanged()
        editor.string = "第一輪提示"; textDidChange(Notification(name: NSText.didChangeNotification))
        guard prompts.count == 2, prompts[0] == "第一輪提示", prompts[1].hasPrefix("第二輪"), !entries.isEnabled else { return false }
        mode.selectItem(at: 1); modeChanged(); entries.selectItem(at: 1); entryChanged()
        guard editor.string.hasPrefix("第二輪"), entries.isEnabled, add.isEnabled, !pause.isEnabled, !cancel.isEnabled else { return false }
        let originalLanguage = L.language
        let originalSize = window.frame.size
        let prompt = editor.string
        editor.setSelectedRange(NSRange(location: 1, length: 2))
        for code in L.codes {
            L.select(code)
            guard editor.string == prompt, editor.selectedRange() == NSRange(location: 1, length: 2), entries.indexOfSelectedItem == 1 else { return false }
            window.setFrame(NSRect(origin: window.frame.origin, size: window.minSize), display: true)
            guard notice.superview === view, view.bounds.contains(notice.frame), controls.allSatisfy({ view.bounds.contains($0.frame) }) else { return false }
            let required = NSAttributedString(string: notice.stringValue, attributes: [.font: notice.font!]).boundingRect(with: NSSize(width: notice.bounds.width - 6, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading]).height
            guard required + 4 <= notice.bounds.height else { return false }
            window.setFrame(NSRect(origin: window.frame.origin, size: originalSize), display: true)
        }
        L.select(originalLanguage)
        let windowNumber = window.windowNumber
        guard switchMode(false), switchMode(true), window.windowNumber == windowNumber, editor.string == prompt else { return false }
        do {
            try engine.start(LoopPlan(firstTime: Date().addingTimeInterval(600), interval: 60, maxRounds: 1, prompts: ["test"]), wall: Date(), mono: Self.mono)
        } catch { return false }
        refresh()
        guard !switchMode(false), engine.active else { return false }
        stop("已用 F8 緊急停止。")
        guard switchMode(false), switchMode(true), timer?.isValid == true, editor.string == prompt else { return false }
        guard let screenshot else { return true }
        guard let content = window.contentView, let bitmap = content.bitmapImageRepForCachingDisplay(in: content.bounds) else { return false }
        content.cacheDisplay(in: content.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return false }
        do { try data.write(to: URL(fileURLWithPath: screenshot), options: .atomic); return true }
        catch { return false }
    }
}
