import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow!
    private let engine = ScheduleEngine()
    private var clockTimer: Timer?
    private var capturedPoint: CGPoint?
    private var captureRemaining = 0
    private var activePlan: ScheduledClickPlan?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var smokeClockFractions = Set<String>()
    private var loopWindow: LoopWindow?
    private let simpleContent = ModeContentView(frame: NSRect(x: 0, y: 0, width: 1040, height: 600))
    private let modeSelector = NSSegmentedControl(labels: ["簡單模式", "循環模式"], trackingMode: .selectOne, target: nil, action: nil)
    private let themeButton = NSButton(title: "", target: nil, action: nil)
    private let switchHint = NSTextField(wrappingLabelWithString: "")
    private var loopSelected = false
    private var closing = false
    private let language = LanguagePicker()
    private var localized: LocalizedView?
    private var languageObserver: NSObjectProtocol?
    private var statusSource = "等待設定。"
    private static let clockRefreshInterval: TimeInterval = 1.0 / 30.0

    private lazy var clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd  HH:mm:ss.SSS"
        return formatter
    }()

    private lazy var statusTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private let clockLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(wrappingLabelWithString: "等待設定。")
    private let positionLabel = NSTextField(labelWithString: "尚未選擇位置")
    private let timeMode = NSSegmentedControl(labels: ["指定時間", "倒數延遲"], trackingMode: .selectOne, target: nil, action: nil)
    private let targetDate = NSDatePicker()
    private let delayHours = NSTextField(string: "0")
    private let delayMinutes = NSTextField(string: "0")
    private let delaySeconds = NSTextField(string: "10")
    private let clickType = NSSegmentedControl(labels: ["單擊", "雙擊"], trackingMode: .selectOne, target: nil, action: nil)
    private let captureButton = NSButton(title: "3 秒後擷取滑鼠位置", target: nil, action: nil)
    private let armButton = NSButton(title: "啟動排程", target: nil, action: nil)
    private let cancelButton = NSButton(title: "取消排程", target: nil, action: nil)
    private var delayViews: [NSView] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Snapshot the current system appearance at launch; manual choice lasts this session.
        NSApp.appearance = NSAppearance(named: NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? .darkAqua : .aqua)
        buildMenu()
        buildWindow()
        localized = LocalizedView(window: window, excluding: [clockLabel, statusLabel, positionLabel, language.view, switchHint, themeButton, loopWindow!.view])
        languageObserver = NotificationCenter.default.addObserver(forName: L.changed, object: nil, queue: .main) { [weak self] _ in self?.languageChanged() }
        languageChanged()
        installEmergencyKeyMonitors()
        setStatus("等待設定。 \(emergencyStopHint())")

        engine.onExecuted = { [weak self] plan in self?.setCompleted(plan) }
        engine.onFailed = { [weak self] error in self?.setFailed(error) }

        updateClockAndStatus()
        let timer = Timer(timeInterval: Self.clockRefreshInterval, repeats: true) { [weak self] _ in
            self?.updateClockAndStatus()
        }
        timer.tolerance = 0.005
        RunLoop.main.add(timer, forMode: .common)
        clockTimer = timer

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if CommandLine.arguments.contains("--loop-ui-smoke-test") {
            _ = switchMode(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                let args = CommandLine.arguments
                let index = args.firstIndex(of: "--screenshot")
                let path = index.flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil }
                guard let self, self.loopWindow?.smokeTest(screenshot: path, switchMode: { self.switchMode($0) }) == true else {
                    fputs("macOS loop UI smoke test failed.\n", stderr); exit(1)
                }
                print("macOS loop UI smoke test passed."); NSApp.terminate(nil)
            }
        }

        if CommandLine.arguments.contains("--ui-smoke-test") {
            runSimpleSmoke(deadline: Date().addingTimeInterval(5))
        }
    }

    // Wait for observable clock samples instead of assuming a loaded CI host updates within 0.5 s.
    private func runSimpleSmoke(deadline: Date) {
        if Set(smokeClockFractions.map { String($0.suffix(2)) }).count < 2, Date() < deadline {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.runSimpleSmoke(deadline: deadline) }
            return
        }
        let valid = validateUserInterface()
        let rendered = saveSmokeScreenshotIfRequested()
        guard valid, rendered else {
            fputs("macOS UI smoke test failed; see preceding diagnostics.\n", stderr); exit(1)
        }
        print("macOS UI smoke test passed for \(window.effectiveAppearance.name.rawValue).")
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let languageObserver { NotificationCenter.default.removeObserver(languageObserver) }
        loopWindow?.shutdown()
        _ = engine.cancel()
        clockTimer?.invalidate()
        if let globalKeyMonitor { NSEvent.removeMonitor(globalKeyMonitor) }
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
    }

    func windowWillClose(_ notification: Notification) {
        closing = true; captureRemaining = 0; loopWindow?.shutdown(); _ = engine.cancel(); clockTimer?.invalidate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func buildMenu() {
        let mainMenu = NSMenu()
        let applicationItem = NSMenuItem()
        mainMenu.addItem(applicationItem)
        let applicationMenu = NSMenu()
        applicationMenu.addItem(withTitle: L.t("結束 ScheduledClicker"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        applicationItem.submenu = applicationMenu
        NSApp.mainMenu = mainMenu
    }

    private func buildWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 680), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "ScheduledClicker — 定時滑鼠點擊器"; window.isReleasedWhenClosed = false; window.delegate = self
        window.contentMinSize = NSSize(width: 1040, height: 680); window.center(); window.backgroundColor = .windowBackgroundColor
        let content = AppearanceBackgroundView(frame: window.contentView?.bounds ?? .zero); window.contentView = content
        content.addSubview(simpleContent)
        loopWindow = LoopWindow(window: window); content.addSubview(loopWindow!.view)
        loopWindow?.onBusyChanged = { [weak self] in self?.updateNavigation() }
        content.addSubview(label("目前時間", frame: NSRect(x: 18, y: 651, width: 230, height: 20), size: 12, color: .secondaryLabelColor))
        clockLabel.frame = NSRect(x: 18, y: 619, width: 335, height: 28); clockLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        clockLabel.textColor = .systemBlue; clockLabel.setAccessibilityLabel("目前時間"); content.addSubview(clockLabel)
        modeSelector.frame = NSRect(x: 365, y: 625, width: 412, height: 34); modeSelector.selectedSegment = 0
        modeSelector.target = self; modeSelector.action = #selector(changeMode); content.addSubview(modeSelector)
        themeButton.frame = NSRect(x: 790, y: 616, width: 34, height: 34); themeButton.bezelStyle = .inline; themeButton.isBordered = false; themeButton.imagePosition = .imageOnly
        themeButton.target = self; themeButton.action = #selector(toggleAppearance); content.addSubview(themeButton)
        switchHint.frame = NSRect(x: 365, y: 601, width: 420, height: 20); switchHint.maximumNumberOfLines = 2; switchHint.font = .systemFont(ofSize: 11); switchHint.textColor = .secondaryLabelColor; content.addSubview(switchHint)
        content.addSubview(label("語言", frame: NSRect(x: 835, y: 651, width: 180, height: 20), size: 12, color: .secondaryLabelColor))
        language.view.frame = NSRect(x: 835, y: 619, width: 185, height: 28); content.addSubview(language.view)
        let root = simpleContent
        root.addSubview(NativeUI.card("", frame: NSRect(x: 16, y: 0, width: 596, height: 402)))
        root.addSubview(NativeUI.card("", frame: NSRect(x: 624, y: 0, width: 400, height: 402)))
        root.addSubview(NativeUI.label("1. 選擇執行時間", frame: NSRect(x: 28, y: 7, width: 565, height: 22), heading: true))
        root.addSubview(NativeUI.label("2. 選擇位置與點擊方式", frame: NSRect(x: 636, y: 7, width: 370, height: 22), heading: true))
        timeMode.frame = NSRect(x: 28, y: 40, width: 410, height: 30); timeMode.selectedSegment = 0; timeMode.target = self; timeMode.action = #selector(modeChanged(_:))
        timeMode.setAccessibilityLabel("時間模式"); root.addSubview(timeMode)
        targetDate.frame = NSRect(x: 28, y: 88, width: 340, height: 30); targetDate.datePickerStyle = .textFieldAndStepper
        targetDate.datePickerElements = [.yearMonthDay, .hourMinuteSecond]; targetDate.dateValue = Date().addingTimeInterval(60)
        targetDate.setAccessibilityLabel("指定執行時間"); root.addSubview(targetDate)
        configureNumericField(delayHours, frame: NSRect(x: 28, y: 88, width: 56, height: 30), label: "倒數小時")
        configureNumericField(delayMinutes, frame: NSRect(x: 158, y: 88, width: 56, height: 30), label: "倒數分鐘")
        configureNumericField(delaySeconds, frame: NSRect(x: 288, y: 88, width: 56, height: 30), label: "倒數秒數")
        let hoursLabel = NativeUI.label("時", frame: NSRect(x: 90, y: 94, width: 60, height: 22))
        let minutesLabel = NativeUI.label("分", frame: NSRect(x: 220, y: 94, width: 60, height: 22))
        let secondsLabel = NativeUI.label("秒", frame: NSRect(x: 350, y: 94, width: 60, height: 22))
        let delayHint = NativeUI.label("可設定 1 秒至 168 小時。", frame: NSRect(x: 28, y: 137, width: 550, height: 22))
        delayViews = [delayHours, delayMinutes, delaySeconds, hoursLabel, minutesLabel, secondsLabel, delayHint]; delayViews.forEach { root.addSubview($0) }
        captureButton.frame = NSRect(x: 636, y: 40, width: 285, height: 34); captureButton.bezelStyle = .rounded
        captureButton.target = self; captureButton.action = #selector(startCapture(_:)); captureButton.toolTip = "按下後視窗會縮小，請在三秒內把滑鼠移到目標位置"; root.addSubview(captureButton)
        positionLabel.frame = NSRect(x: 640, y: 89, width: 350, height: 24); positionLabel.textColor = .systemBlue; root.addSubview(positionLabel)
        root.addSubview(NativeUI.label("點擊方式", frame: NSRect(x: 640, y: 139, width: 340, height: 22)))
        clickType.frame = NSRect(x: 636, y: 165, width: 370, height: 30); clickType.selectedSegment = 0; clickType.setAccessibilityLabel("點擊方式"); root.addSubview(clickType)
        let note = NSTextField(wrappingLabelWithString: "在指定時間安全地執行一次滑鼠單擊或雙擊\n請保持目標視窗／聊天不變。未驗證 AI 狀態或送達。\n等待設定。排程啟動後可按 F8 緊急停止。")
        note.frame = NSRect(x: 16, y: 410, width: 1008, height: 74); note.font = .systemFont(ofSize: 12.5); note.drawsBackground = true; note.backgroundColor = .controlBackgroundColor; root.addSubview(note)
        armButton.frame = NSRect(x: 16, y: 490, width: 195, height: 34); armButton.bezelStyle = .rounded; armButton.bezelColor = .systemBlue
        armButton.target = self; armButton.action = #selector(armSchedule(_:)); root.addSubview(armButton)
        cancelButton.frame = NSRect(x: 221, y: 490, width: 195, height: 34); cancelButton.bezelStyle = .rounded
        cancelButton.target = self; cancelButton.action = #selector(cancelSchedule(_:)); cancelButton.isEnabled = false; root.addSubview(cancelButton)
        statusLabel.frame = NSRect(x: 20, y: 530, width: 1000, height: 68); statusLabel.font = .systemFont(ofSize: 12.5); statusLabel.setAccessibilityLabel("排程狀態"); root.addSubview(statusLabel)
        updateModeState(); updateNavigation()
    }

    private func groupBox(frame: NSRect) -> NSBox {
        let box = NSBox(frame: frame)
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.borderColor = .separatorColor
        box.borderWidth = 1
        box.cornerRadius = 12
        box.fillColor = .controlBackgroundColor
        return box
    }

    private func label(_ text: String, frame: NSRect, size: CGFloat = 14, bold: Bool = false, color: NSColor = .labelColor) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.frame = frame
        field.font = bold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
        field.textColor = color
        return field
    }

    private func configureNumericField(_ field: NSTextField, frame: NSRect, label: String) {
        field.frame = frame
        field.alignment = .right
        field.setAccessibilityLabel(label)
    }

    @objc private func modeChanged(_ sender: NSSegmentedControl) {
        updateModeState()
    }

    private func updateModeState() {
        let useAbsoluteTime = timeMode.selectedSegment == 0
        targetDate.isHidden = !useAbsoluteTime
        targetDate.isEnabled = useAbsoluteTime
        delayViews.forEach { $0.isHidden = useAbsoluteTime }
        delayHours.isEnabled = !useAbsoluteTime
        delayMinutes.isEnabled = !useAbsoluteTime
        delaySeconds.isEnabled = !useAbsoluteTime
    }

    @objc private func startCapture(_ sender: Any?) {
        captureRemaining = 3
        captureButton.isEnabled = false
        setStatus("請在 3 秒內將滑鼠移到要點擊的位置…")
        window.miniaturize(nil)
        runCaptureCountdown()
    }

    private func runCaptureCountdown() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self, !self.closing, self.captureRemaining > 0 else { return }
            self.captureRemaining -= 1
            if self.captureRemaining > 0 {
                self.setStatus("請在 \(self.captureRemaining) 秒內將滑鼠移到要點擊的位置…")
                self.runCaptureCountdown()
                return
            }

            self.capturedPoint = MacMouse.currentLocation()
            if let point = self.capturedPoint {
                self.positionLabel.stringValue = "X: \(Int(point.x.rounded()))   Y: \(Int(point.y.rounded()))"
                self.positionLabel.textColor = .systemBlue
                self.setStatus("位置已擷取。確認時間後即可啟動排程。")
            } else {
                self.setStatus("無法讀取滑鼠位置，請再試一次。")
            }
            self.captureButton.isEnabled = true
            self.window.deminiaturize(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func armSchedule(_ sender: Any?) {
        if loopSelected || loopWindow?.busy == true {
            showAlert(title: "循環模式已開啟", message: "請先停止目前操作，再切換模式。", style: .informational)
            return
        }
        guard let point = capturedPoint else {
            showAlert(title: "尚未選擇位置", message: "請先擷取要點擊的滑鼠位置。", style: .informational)
            return
        }

        let now = Date()
        let click = clickType.selectedSegment == 1 ? ScheduledClickType.double : .single
        let plan: ScheduledClickPlan
        var delay: TimeInterval?
        guard let currentSnapshot = ActiveDisplays.snapshot() else {
            showAlert(title: "無法讀取螢幕", message: "macOS 沒有回報可用的顯示器，請確認目前為已登入且未鎖定的桌面。", style: .warning)
            return
        }

        if timeMode.selectedSegment == 0 {
            plan = ScheduledClickPlan(targetDate: targetDate.dateValue, point: point, clickType: click, displaySnapshot: currentSnapshot)
        } else {
            guard let hours = boundedInteger(delayHours.stringValue, min: 0, max: 168),
                  let minutes = boundedInteger(delayMinutes.stringValue, min: 0, max: 59),
                  let seconds = boundedInteger(delaySeconds.stringValue, min: 0, max: 59) else {
                showAlert(title: "時間無效", message: "請輸入 0–168 小時、0–59 分鐘及 0–59 秒。", style: .warning)
                return
            }
            delay = TimeInterval(hours * 3600 + minutes * 60 + seconds)
            guard delay! >= 1, delay! <= 168 * 3600 else {
                showAlert(title: "時間無效", message: "倒數延遲必須介於 1 秒與 168 小時之間。", style: .warning)
                return
            }
            plan = ScheduledClickPlan.afterDelay(
                delay!,
                wallNow: now,
                uptimeNow: ProcessInfo.processInfo.systemUptime,
                point: point,
                clickType: click,
                displaySnapshot: currentSnapshot
            )
        }

        if let error = PlanValidator.validate(plan, now: now, displayBounds: currentSnapshot.bounds) {
            showAlert(title: "無法啟動", message: error, style: .warning)
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        let confirmation = NSAlert()
        confirmation.messageText = "確認排程"
        confirmation.informativeText = "時間：\(formatter.string(from: plan.targetDate))\n位置：X \(Int(point.x)), Y \(Int(point.y))\n方式：\(click.displayName)\n\n啟動後工具會自動縮小。請確認目標畫面不會移動。"
        confirmation.messageText = L.t(confirmation.messageText); confirmation.informativeText = L.t(confirmation.informativeText)
        confirmation.addButton(withTitle: L.t("啟動"))
        confirmation.addButton(withTitle: L.t("取消"))
        guard confirmation.runModal() == .alertFirstButtonReturn else { return }

        guard requestAccessibilityIfNeeded() else {
            showAlert(
                title: "需要輔助使用權限",
                message: "macOS 已開啟權限提示。請到「系統設定 → 隱私權與安全性 → 輔助使用」允許 ScheduledClicker，然後重新按啟動排程。",
                style: .warning
            )
            return
        }

        let confirmedAt = Date()
        guard let confirmedSnapshot = ActiveDisplays.snapshot() else {
            showAlert(title: "無法讀取螢幕", message: "macOS 沒有回報可用的顯示器。", style: .warning)
            return
        }
        let confirmedPlan = delay.map {
            ScheduledClickPlan.afterDelay(
                $0,
                wallNow: confirmedAt,
                uptimeNow: ProcessInfo.processInfo.systemUptime,
                point: point,
                clickType: click,
                displaySnapshot: confirmedSnapshot
            )
        } ?? ScheduledClickPlan(
            targetDate: plan.targetDate,
            point: point,
            clickType: click,
            displaySnapshot: confirmedSnapshot
        )
        if let error = PlanValidator.validate(confirmedPlan, now: confirmedAt, displayBounds: confirmedSnapshot.bounds) {
            showAlert(title: "無法啟動", message: error, style: .warning)
            return
        }

        activePlan = confirmedPlan
        engine.arm(confirmedPlan)
        setInputsEnabled(false)
        statusLabel.textColor = .systemBlue
        updateClockAndStatus()
        window.miniaturize(nil)
    }

    private func requestAccessibilityIfNeeded() -> Bool {
        if AXIsProcessTrusted() { return true }
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @objc private func cancelSchedule(_ sender: Any?) {
        cancelSchedule(message: "排程已取消。", emergency: false)
    }

    private func cancelSchedule(message: String, emergency: Bool) {
        let result = engine.cancel()
        if result == .executing {
            statusLabel.textColor = .systemOrange
            setStatus("點擊已開始執行，現在取消已來不及。")
            return
        }
        activePlan = nil
        setInputsEnabled(true)
        statusLabel.textColor = emergency ? .systemRed : .secondaryLabelColor
        setStatus(message)
    }

    private func setCompleted(_ plan: ScheduledClickPlan) {
        activePlan = nil
        setInputsEnabled(true)
        statusLabel.textColor = .systemGreen
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        setStatus("已於 \(formatter.string(from: Date())) 完成\(plan.clickType.displayName)。")
    }

    private func setFailed(_ error: Error) {
        activePlan = nil
        setInputsEnabled(true)
        statusLabel.textColor = .systemRed
        setStatus("執行失敗：\(error.localizedDescription)")
    }

    private func setInputsEnabled(_ enabled: Bool) {
        timeMode.isEnabled = enabled
        captureButton.isEnabled = enabled
        clickType.isEnabled = enabled
        armButton.isEnabled = enabled
        cancelButton.isEnabled = !enabled
        cancelButton.contentTintColor = enabled ? .secondaryLabelColor : .labelColor
        if enabled { updateModeState() }
        else {
            targetDate.isEnabled = false
            delayHours.isEnabled = false
            delayMinutes.isEnabled = false
            delaySeconds.isEnabled = false
        }
    }

    private func setStatus(_ source: String) { statusSource = source; statusLabel.stringValue = L.t(source) }
    @objc private func toggleAppearance() {
        let dark = window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        NSApp.appearance = NSAppearance(named: dark ? .aqua : .darkAqua)
        updateThemeButton(); window.contentView?.needsDisplay = true
    }
    private func updateThemeButton() {
        let dark = window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let caption = L.t(dark ? "切換為淺色模式" : "切換為深色模式")
        themeButton.title = ""
        themeButton.setAccessibilityLabel(caption); themeButton.toolTip = caption
        themeButton.image = NSImage(systemSymbolName: dark ? "sun.max" : "moon", accessibilityDescription: caption)
        themeButton.imagePosition = .imageOnly
    }
    private func languageChanged() {
        updateThemeButton()
        targetDate.locale = Locale(identifier: L.language == "zh" ? "zh-Hant" : L.language)
        if capturedPoint == nil { positionLabel.stringValue = L.t("尚未選擇位置") }
        setStatus(statusSource); buildMenu(); updateNavigation()
    }

    private func updateClockAndStatus() {
        updateNavigation()
        let clockText = clockFormatter.string(from: Date())
        clockLabel.stringValue = clockText
        if CommandLine.arguments.contains("--ui-smoke-test"), let fraction = clockText.split(separator: ".").last {
            smokeClockFractions.insert(String(fraction))
        }

        guard let plan = activePlan, engine.isArmed, let remaining = engine.remainingNow() else { return }
        let safeRemaining = max(0, Int(remaining.rounded(.up)))
        let hours = safeRemaining / 3600
        let minutes = safeRemaining % 3600 / 60
        let seconds = safeRemaining % 60
        setStatus(String(
            format: "已排程：%@ 執行，剩餘 %02d:%02d:%02d。%@",
            statusTimeFormatter.string(from: plan.targetDate), hours, minutes, seconds, emergencyStopHint()
        ))
    }

    private func installEmergencyKeyMonitors() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 100, self?.loopSelected == false else { return }
            DispatchQueue.main.async { self?.cancelSchedule(message: "已用 F8 緊急停止。", emergency: true) }
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 100, self?.loopSelected == false else { return event }
            self?.cancelSchedule(message: "已用 F8 緊急停止。", emergency: true)
            return nil
        }
    }

    @objc private func changeMode() {
        if !switchMode(modeSelector.selectedSegment == 1) { modeSelector.selectedSegment = loopSelected ? 1 : 0 }
    }
    @discardableResult private func switchMode(_ loop: Bool) -> Bool {
        if loopSelected == loop { return true }
        guard !engine.isArmed, !engine.isExecuting, captureRemaining == 0, loopWindow?.busy != true else { return false }
        window.makeFirstResponder(nil)
        loopSelected = loop; simpleContent.isHidden = loop
        if loop { loopWindow?.show() } else { loopWindow?.hide() }
        modeSelector.selectedSegment = loop ? 1 : 0; updateNavigation(); return true
    }
    private func updateNavigation() {
        let busy = engine.isArmed || engine.isExecuting || captureRemaining > 0 || loopWindow?.busy == true
        modeSelector.isEnabled = !busy
        switchHint.stringValue = busy ? L.t("請先停止目前操作，再切換模式。") : ""
    }

    private func emergencyStopHint() -> String {
        if globalKeyMonitor != nil || localKeyMonitor != nil {
            return "可按 F8（部分鍵盤需 Fn+F8）或取消排程停止。"
        }
        return "F8 監聽不可用，請用取消排程按鈕停止。"
    }

    private func validateUserInterface() -> Bool {
        guard !modeSelector.frame.intersects(themeButton.frame), !themeButton.frame.intersects(language.view.frame) else { print("FAIL: header overlap"); return false }
        let originalWindowNumber = window.windowNumber
        let originalFrame = window.frame
        guard switchMode(true), switchMode(false), window.windowNumber == originalWindowNumber, window.frame == originalFrame else { print("FAIL: shared window identity/frame"); return false }
        guard themeButton.image != nil, themeButton.title.isEmpty, themeButton.imagePosition == .imageOnly, themeButton.accessibilityLabel() == themeButton.toolTip else { print("FAIL: appearance icon semantics"); return false }
        let originalAppearance = window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        toggleAppearance()
        guard window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) != originalAppearance else { print("FAIL: appearance toggle"); return false }
        toggleAppearance()
        guard window.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == originalAppearance else { print("FAIL: appearance round trip"); return false }
        let originalLanguage = L.language
        let originalDate = targetDate.dateValue
        let originalClick = clickType.selectedSegment
        for code in L.codes {
            L.select(code)
            guard language.view.indexOfSelectedItem == L.codes.firstIndex(of: code), targetDate.dateValue == originalDate, clickType.selectedSegment == originalClick else { print("FAIL: language state \(code), picker=\(language.view.indexOfSelectedItem), date=\(targetDate.dateValue.timeIntervalSince1970), expected=\(originalDate.timeIntervalSince1970), click=\(clickType.selectedSegment)"); return false }
        }
        L.select(originalLanguage)
        let originalMode = timeMode.selectedSegment
        timeMode.selectedSegment = 0
        updateModeState()
        let absoluteModeIsValid = !targetDate.isHidden && delayViews.allSatisfy { $0.isHidden }
        timeMode.selectedSegment = 1
        updateModeState()
        let delayModeIsValid = targetDate.isHidden && delayViews.allSatisfy { !$0.isHidden }
        timeMode.selectedSegment = originalMode
        updateModeState()

        var readable = false
        window.effectiveAppearance.performAsCurrentDrawingAppearance {
            readable = contrastRatio(foreground: .labelColor, background: .windowBackgroundColor) >= 4.5
                && contrastRatio(foreground: .secondaryLabelColor, background: .windowBackgroundColor) >= 3.0
                && contrastRatio(foreground: .labelColor, background: .controlBackgroundColor) >= 4.5
        }
        let clockRefreshIsSmooth = (clockTimer?.timeInterval ?? 1) <= 0.04
        let changingSubHundredths = Set(smokeClockFractions.map { String($0.suffix(2)) }).count >= 2
        print("UI checks: absolute=\(absoluteModeIsValid), delay=\(delayModeIsValid), contrast=\(readable), refresh=\(clockRefreshIsSmooth), fractions=\(changingSubHundredths)")
        return absoluteModeIsValid && delayModeIsValid && readable && clockRefreshIsSmooth && changingSubHundredths
    }

    private func saveSmokeScreenshotIfRequested() -> Bool {
        guard let argumentIndex = CommandLine.arguments.firstIndex(of: "--screenshot"),
              CommandLine.arguments.indices.contains(argumentIndex + 1) else { return true }
        guard let contentView = window.contentView,
              let representation = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) else { return false }
        contentView.cacheDisplay(in: contentView.bounds, to: representation)
        guard let data = representation.representation(using: .png, properties: [:]) else { return false }
        do {
            try data.write(to: URL(fileURLWithPath: CommandLine.arguments[argumentIndex + 1]), options: .atomic)
            return true
        } catch {
            fputs("Unable to write UI smoke screenshot: \(error.localizedDescription)\n", stderr)
            return false
        }
    }

    private func contrastRatio(foreground: NSColor, background: NSColor) -> CGFloat {
        guard let foreground = foreground.usingColorSpace(.sRGB),
              let background = background.usingColorSpace(.sRGB) else { return 0 }
        let lighter = max(relativeLuminance(foreground), relativeLuminance(background))
        let darker = min(relativeLuminance(foreground), relativeLuminance(background))
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(_ color: NSColor) -> CGFloat {
        func component(_ value: CGFloat) -> CGFloat {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * component(color.redComponent)
            + 0.7152 * component(color.greenComponent)
            + 0.0722 * component(color.blueComponent)
    }

    private func boundedInteger(_ value: String, min: Int, max: Int) -> Int? {
        guard let number = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)), number >= min, number <= max else { return nil }
        return number
    }

    private func showAlert(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = L.t(title)
        alert.informativeText = L.t(message)
        alert.alertStyle = style
        alert.addButton(withTitle: L.t("確定"))
        alert.runModal()
    }
}

private final class AppearanceBackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)
    }
}
