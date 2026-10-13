import Cocoa

final class LoopWindow: NSObject, NSWindowDelegate, NSTextViewDelegate {
    let window: NSWindow
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
    private let language = LanguagePicker()
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
    private let clockLabel = NSTextField(labelWithString: "")
    private var firstClockText: String?
    private let back = NSButton(title: "返回簡單模式", target: nil, action: nil)
    var onReturnToSimple: (() -> Void)?
    private let clockFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy/MM/dd  HH:mm:ss.SSS"; return formatter
    }()
    private static var mono: TimeInterval { ProcessInfo.processInfo.systemUptime }

    override init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 840, height: 800), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.title = "循環輸入與點擊"
        window.minSize = NSSize(width: 840, height: 680)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        build()
        localized = LocalizedView(window: window, excluding: [clockLabel, status, back, pause, inputLabel, sendLabel, entries, editor, language.view])
        languageObserver = NotificationCenter.default.addObserver(forName: L.changed, object: nil, queue: .main) { [weak self] _ in self?.languageChanged() }
        refreshEntries(selected: 0)
        startTimer()
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
    func show() { startTimer(); refresh(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    func windowWillClose(_ notification: Notification) {
        captureKind = 0; stop("已返回簡單模式；循環已停止。"); timer?.invalidate(); timer = nil
        onReturnToSimple?()
    }
    @objc private func returnToSimple() { window.close() }
    func stop(_ message: String) { engine.stop(message); refresh() }

    private func build() {
        guard let root = window.contentView else { return }
        let header = NSView(frame: NSRect(x: 0, y: 700, width: 840, height: 100))
        header.autoresizingMask = [.width, .minYMargin]
        let caption = NSTextField(labelWithString: "目前時間"); caption.frame = NSRect(x: 20, y: 76, width: 200, height: 20)
        caption.textColor = .secondaryLabelColor; header.addSubview(caption)
        clockLabel.frame = NSRect(x: 20, y: 40, width: 440, height: 30)
        clockLabel.font = .monospacedDigitSystemFont(ofSize: 22, weight: .semibold); clockLabel.textColor = .systemBlue
        clockLabel.setAccessibilityLabel("目前時間"); header.addSubview(clockLabel)
        back.frame = NSRect(x: 520, y: 50, width: 300, height: 34); back.autoresizingMask = [.minXMargin]
        back.bezelStyle = .rounded; back.target = self; back.action = #selector(returnToSimple); header.addSubview(back)
        let languageCaption = NSTextField(labelWithString: "語言"); languageCaption.frame = NSRect(x: 20, y: 5, width: 115, height: 24)
        language.view.frame = NSRect(x: 140, y: 2, width: 160, height: 30)
        header.addSubview(languageCaption); header.addSubview(language.view); root.addSubview(header)
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 275, width: 840, height: 425))
        scroll.autoresizingMask = [.width, .height]; scroll.hasVerticalScroller = true
        let doc = LoopFlippedView(frame: NSRect(x: 0, y: 0, width: 810, height: 635))
        scroll.documentView = doc; root.addSubview(scroll)
        func label(_ text: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 235) {
            let field = NSTextField(labelWithString: text); field.frame = NSRect(x: x, y: y, width: width, height: 24); doc.addSubview(field)
        }
        func place(_ control: NSControl, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat) {
            control.frame = NSRect(x: x, y: y, width: width, height: 30); doc.addSubview(control); controls.append(control)
        }
        label("首次時間與循環間隔", 20, 15, 500)
        for date in [first, deadline] { date.datePickerStyle = .textFieldAndStepper; date.datePickerElements = [.yearMonthDay, .hourMinuteSecond] }
        first.dateValue = Date().addingTimeInterval(60); deadline.dateValue = Date().addingTimeInterval(86400)
        first.setAccessibilityLabel("首次執行时间"); deadline.setAccessibilityLabel("截止時間")
        label("首次執行", 20, 50); place(first, 270, 45, 320)
        label("每輪結束後等", 20, 90); place(hours, 270, 85, 60); label("時", 335, 90, 50)
        place(minutes, 390, 85, 60); label("分", 455, 90, 50); place(seconds, 510, 85, 60); label("秒", 575, 90, 50)
        hours.setAccessibilityLabel("循環間隔小時"); minutes.setAccessibilityLabel("循環間隔分鐘"); seconds.setAccessibilityLabel("循環間隔秒數")
        label("點擊／貼上之間等待", 20, 130); place(wait, 270, 125, 60); label("秒（1–10）", 350, 130)
        wait.setAccessibilityLabel("步驟等待秒數")
        countBound.state = .on; place(countBound, 20, 165, 235); place(count, 270, 165, 80); label("輪", 365, 170)
        count.setAccessibilityLabel("最多執行輪次")
        place(timeBound, 20, 205, 235); place(deadline, 270, 205, 320)
        countBound.target = self; countBound.action = #selector(optionsChanged)
        timeBound.target = self; timeBound.action = #selector(optionsChanged)
        label("提示詞", 20, 250)
        mode.addItems(withTitles: ["每輪相同", "依輪次設定"]); place(mode, 270, 245, 260)
        mode.target = self; mode.action = #selector(modeChanged)
        place(entries, 20, 285, 165); entries.target = self; entries.action = #selector(entryChanged)
        place(add, 200, 285, 180); add.target = self; add.action = #selector(addPrompt)
        place(remove, 390, 285, 180); remove.target = self; remove.action = #selector(removePrompt)
        let textScroll = NSScrollView(frame: NSRect(x: 20, y: 330, width: 770, height: 140))
        textScroll.hasVerticalScroller = true; textScroll.borderType = .bezelBorder
        editor.frame = NSRect(x: 0, y: 0, width: 750, height: 140)
        editor.isRichText = false; editor.isAutomaticQuoteSubstitutionEnabled = false; editor.isAutomaticDashSubstitutionEnabled = false
        editor.font = .systemFont(ofSize: 14); editor.delegate = self; editor.autoresizingMask = [.width]
        editor.isVerticallyResizable = true; editor.textContainer?.widthTracksTextView = true
        editor.setAccessibilityLabel("目前輪次提示詞")
        textScroll.documentView = editor; doc.addSubview(textScroll)
        place(repeatLast, 20, 480, 770); place(replace, 20, 515, 770)
        let inputButton = NSButton(title: "擷取輸入框（3 秒）", target: self, action: #selector(captureInput))
        let sendButton = NSButton(title: "擷取送出鈕（3 秒）", target: self, action: #selector(captureSend))
        place(inputButton, 20, 555, 260); place(inputLabel, 295, 555, 480)
        place(sendButton, 20, 595, 260); place(sendLabel, 295, 595, 480)
        notice.frame = NSRect(x: 20, y: 135, width: 800, height: 130)
        notice.font = .systemFont(ofSize: 12.5); notice.autoresizingMask = [.width]
        notice.drawsBackground = true; notice.backgroundColor = .controlBackgroundColor
        root.addSubview(notice)
        for (index, button) in [start, trial, pause, cancel].enumerated() {
            button.frame = NSRect(x: CGFloat(20 + index * 205), y: 92, width: 190, height: 32)
            button.bezelStyle = .rounded; button.target = self; root.addSubview(button)
        }
        start.action = #selector(startLoop); trial.action = #selector(trialLoop); pause.action = #selector(togglePause); cancel.action = #selector(cancelLoop)
        status.frame = NSRect(x: 20, y: 10, width: 800, height: 76); status.autoresizingMask = [.width]; root.addSubview(status)
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
        clockLabel.stringValue = clockFormatter.string(from: Date())
        if firstClockText == nil { firstClockText = clockLabel.stringValue }
        let busy = engine.active || captureKind != 0
        back.title = L.t(busy ? "停止並返回簡單模式" : "返回簡單模式")
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
    func smokeTest(screenshot: String?) -> Bool {
        guard clockLabel.stringValue != firstClockText, back.superview?.bounds.contains(back.frame) == true else { return false }
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
            guard language.view.indexOfSelectedItem == L.codes.firstIndex(of: code) else { return false }
            window.setFrame(NSRect(origin: window.frame.origin, size: window.minSize), display: true)
            guard notice.superview === window.contentView, window.contentView?.bounds.contains(notice.frame) == true else { return false }
            let required = NSAttributedString(string: notice.stringValue, attributes: [.font: notice.font!]).boundingRect(with: NSSize(width: notice.bounds.width - 6, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading]).height
            guard required + 4 <= notice.bounds.height else { return false }
            window.setFrame(NSRect(origin: window.frame.origin, size: originalSize), display: true)
        }
        L.select(originalLanguage)
        var returned = false
        let originalReturn = onReturnToSimple
        onReturnToSimple = { returned = true }
        do {
            try engine.start(LoopPlan(firstTime: Date().addingTimeInterval(600), interval: 60, maxRounds: 1, prompts: ["test"]), wall: Date(), mono: Self.mono)
        } catch { return false }
        refresh()
        guard back.title == L.t("停止並返回簡單模式") else { return false }
        back.performClick(nil)
        onReturnToSimple = originalReturn
        guard returned, !engine.active, captureKind == 0, timer == nil else { return false }
        show()
        guard timer?.isValid == true, editor.string.hasPrefix("第二輪"), prompts.count == 2 else { return false }
        guard let screenshot else { return true }
        guard let content = window.contentView, let bitmap = content.bitmapImageRepForCachingDisplay(in: content.bounds) else { return false }
        content.cacheDisplay(in: content.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return false }
        do { try data.write(to: URL(fileURLWithPath: screenshot), options: .atomic); return true }
        catch { return false }
    }
}

private final class LoopFlippedView: NSView { override var isFlipped: Bool { true } }
