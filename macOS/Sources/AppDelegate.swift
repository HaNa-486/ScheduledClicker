import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private let engine = ScheduleEngine()
    private var clockTimer: Timer?
    private var capturedPoint: CGPoint?
    private var captureRemaining = 0
    private var activePlan: ScheduledClickPlan?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?

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
        buildMenu()
        buildWindow()
        installEmergencyKeyMonitors()
        statusLabel.stringValue = "等待設定。\(emergencyStopHint())"

        engine.onExecuted = { [weak self] plan in self?.setCompleted(plan) }
        engine.onFailed = { [weak self] error in self?.setFailed(error) }

        updateClockAndStatus()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateClockAndStatus()
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if CommandLine.arguments.contains("--ui-smoke-test") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self, self.validateUserInterface() else {
                    fputs("macOS UI smoke test failed: unreadable appearance or invalid mode visibility.\n", stderr)
                    exit(1)
                }
                print("macOS UI smoke test passed for \(self.window.effectiveAppearance.name.rawValue).")
                NSApp.terminate(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        _ = engine.cancel()
        clockTimer?.invalidate()
        if let globalKeyMonitor { NSEvent.removeMonitor(globalKeyMonitor) }
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    private func buildMenu() {
        let mainMenu = NSMenu()
        let applicationItem = NSMenuItem()
        mainMenu.addItem(applicationItem)
        let applicationMenu = NSMenu()
        applicationMenu.addItem(withTitle: "結束 ScheduledClicker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        applicationItem.submenu = applicationMenu
        NSApp.mainMenu = mainMenu
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 720),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScheduledClicker — 定時滑鼠點擊器"
        window.center()
        window.isReleasedWhenClosed = false
        // Never combine a fixed light background with dynamic system text colors.
        // Semantic colors keep the entire window readable in both Aqua and Dark Aqua.
        window.backgroundColor = .windowBackgroundColor

        guard let content = window.contentView else { return }
        let title = label("定時滑鼠點擊器", frame: NSRect(x: 32, y: 654, width: 616, height: 34), size: 26, bold: true)
        let subtitle = label("在指定時間安全地執行一次滑鼠單擊或雙擊", frame: NSRect(x: 32, y: 625, width: 616, height: 22), color: .secondaryLabelColor)
        let clockCaption = label("目前時間", frame: NSRect(x: 34, y: 590, width: 100, height: 20), size: 12, bold: true, color: .secondaryLabelColor)
        clockLabel.frame = NSRect(x: 32, y: 552, width: 616, height: 34)
        clockLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 23, weight: .semibold)
        clockLabel.textColor = .systemBlue
        clockLabel.accessibilityLabel = "目前時間"
        content.addSubview(title)
        content.addSubview(subtitle)
        content.addSubview(clockCaption)
        content.addSubview(clockLabel)

        content.addSubview(groupBox(frame: NSRect(x: 24, y: 344, width: 632, height: 194)))
        content.addSubview(label("1. 何時執行？", frame: NSRect(x: 48, y: 493, width: 300, height: 24), size: 16, bold: true))
        content.addSubview(label("選擇明確時間，或從現在開始倒數。", frame: NSRect(x: 48, y: 468, width: 420, height: 20), size: 13, color: .secondaryLabelColor))

        timeMode.frame = NSRect(x: 48, y: 423, width: 250, height: 30)
        timeMode.selectedSegment = 0
        timeMode.target = self
        timeMode.action = #selector(modeChanged(_:))
        timeMode.accessibilityLabel = "時間模式"
        content.addSubview(timeMode)

        targetDate.frame = NSRect(x: 326, y: 421, width: 292, height: 30)
        targetDate.datePickerStyle = .textFieldAndStepper
        targetDate.datePickerElements = [.yearMonthDay, .hourMinuteSecond]
        targetDate.dateValue = Date().addingTimeInterval(60)
        targetDate.accessibilityLabel = "指定執行時間"
        content.addSubview(targetDate)

        configureNumericField(delayHours, frame: NSRect(x: 326, y: 421, width: 56, height: 30), label: "倒數小時")
        configureNumericField(delayMinutes, frame: NSRect(x: 421, y: 421, width: 56, height: 30), label: "倒數分鐘")
        configureNumericField(delaySeconds, frame: NSRect(x: 516, y: 421, width: 56, height: 30), label: "倒數秒數")
        content.addSubview(delayHours)
        content.addSubview(delayMinutes)
        content.addSubview(delaySeconds)
        let hoursLabel = label("時", frame: NSRect(x: 388, y: 426, width: 24, height: 20))
        let minutesLabel = label("分", frame: NSRect(x: 483, y: 426, width: 24, height: 20))
        let secondsLabel = label("秒", frame: NSRect(x: 578, y: 426, width: 24, height: 20))
        let delayHint = label("可設定 1 秒至 168 小時。", frame: NSRect(x: 326, y: 382, width: 292, height: 20), size: 12, color: .secondaryLabelColor)
        [hoursLabel, minutesLabel, secondsLabel, delayHint].forEach { content.addSubview($0) }
        delayViews = [delayHours, delayMinutes, delaySeconds, hoursLabel, minutesLabel, secondsLabel, delayHint]

        content.addSubview(groupBox(frame: NSRect(x: 24, y: 190, width: 632, height: 136)))
        content.addSubview(label("2. 要點哪裡？", frame: NSRect(x: 48, y: 281, width: 300, height: 24), size: 16, bold: true))
        content.addSubview(label("擷取位置後，選擇單擊或雙擊。", frame: NSRect(x: 48, y: 256, width: 350, height: 20), size: 13, color: .secondaryLabelColor))
        captureButton.frame = NSRect(x: 44, y: 211, width: 220, height: 34)
        captureButton.bezelStyle = .rounded
        captureButton.target = self
        captureButton.action = #selector(startCapture(_:))
        captureButton.toolTip = "按下後視窗會縮小，請在三秒內把滑鼠移到目標位置"
        positionLabel.frame = NSRect(x: 282, y: 218, width: 175, height: 22)
        positionLabel.textColor = .secondaryLabelColor
        content.addSubview(captureButton)
        content.addSubview(positionLabel)
        clickType.frame = NSRect(x: 468, y: 213, width: 150, height: 30)
        clickType.selectedSegment = 0
        clickType.accessibilityLabel = "點擊方式"
        content.addSubview(clickType)

        armButton.frame = NSRect(x: 24, y: 125, width: 406, height: 46)
        armButton.bezelStyle = .rounded
        armButton.keyEquivalent = "\r"
        armButton.target = self
        armButton.action = #selector(armSchedule(_:))
        armButton.toolTip = "檢查設定並啟動一次性排程"
        cancelButton.frame = NSRect(x: 446, y: 125, width: 210, height: 46)
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelSchedule(_:))
        cancelButton.isEnabled = false
        content.addSubview(armButton)
        content.addSubview(cancelButton)

        let statusBox = groupBox(frame: NSRect(x: 24, y: 24, width: 632, height: 82))
        content.addSubview(statusBox)
        content.addSubview(label("狀態", frame: NSRect(x: 48, y: 72, width: 80, height: 20), size: 12, bold: true, color: .secondaryLabelColor))
        statusLabel.frame = NSRect(x: 48, y: 38, width: 584, height: 34)
        statusLabel.font = NSFont.systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.accessibilityLabel = "排程狀態"
        content.addSubview(statusLabel)
        updateModeState()
    }

    private func groupBox(frame: NSRect) -> NSBox {
        let box = NSBox(frame: frame)
        box.boxType = .custom
        box.titlePosition = .noTitle
        box.borderType = .lineBorder
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
        field.accessibilityLabel = label
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
        statusLabel.stringValue = "請在 3 秒內將滑鼠移到要點擊的位置…"
        window.miniaturize(nil)
        runCaptureCountdown()
    }

    private func runCaptureCountdown() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            self.captureRemaining -= 1
            if self.captureRemaining > 0 {
                self.statusLabel.stringValue = "請在 \(self.captureRemaining) 秒內將滑鼠移到要點擊的位置…"
                self.runCaptureCountdown()
                return
            }

            self.capturedPoint = MacMouse.currentLocation()
            if let point = self.capturedPoint {
                self.positionLabel.stringValue = "X: \(Int(point.x.rounded()))   Y: \(Int(point.y.rounded()))"
                self.positionLabel.textColor = .systemBlue
                self.statusLabel.stringValue = "位置已擷取。確認時間後即可啟動排程。"
            } else {
                self.statusLabel.stringValue = "無法讀取滑鼠位置，請再試一次。"
            }
            self.captureButton.isEnabled = true
            self.window.deminiaturize(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func armSchedule(_ sender: Any?) {
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
        confirmation.addButton(withTitle: "啟動")
        confirmation.addButton(withTitle: "取消")
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
            statusLabel.stringValue = "點擊已開始執行，現在取消已來不及。"
            return
        }
        activePlan = nil
        setInputsEnabled(true)
        statusLabel.textColor = emergency ? .systemRed : .secondaryLabelColor
        statusLabel.stringValue = message
    }

    private func setCompleted(_ plan: ScheduledClickPlan) {
        activePlan = nil
        setInputsEnabled(true)
        statusLabel.textColor = .systemGreen
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        statusLabel.stringValue = "已於 \(formatter.string(from: Date())) 完成\(plan.clickType.displayName)。"
    }

    private func setFailed(_ error: Error) {
        activePlan = nil
        setInputsEnabled(true)
        statusLabel.textColor = .systemRed
        statusLabel.stringValue = "執行失敗：\(error.localizedDescription)"
    }

    private func setInputsEnabled(_ enabled: Bool) {
        timeMode.isEnabled = enabled
        captureButton.isEnabled = enabled
        clickType.isEnabled = enabled
        armButton.isEnabled = enabled
        cancelButton.isEnabled = !enabled
        if enabled { updateModeState() }
        else {
            targetDate.isEnabled = false
            delayHours.isEnabled = false
            delayMinutes.isEnabled = false
            delaySeconds.isEnabled = false
        }
    }

    private func updateClockAndStatus() {
        let clockFormatter = DateFormatter()
        clockFormatter.dateFormat = "yyyy/MM/dd  HH:mm:ss.SSS"
        clockLabel.stringValue = clockFormatter.string(from: Date())

        guard let plan = activePlan, engine.isArmed, let remaining = engine.remainingNow() else { return }
        let safeRemaining = max(0, Int(remaining.rounded(.up)))
        let hours = safeRemaining / 3600
        let minutes = safeRemaining % 3600 / 60
        let seconds = safeRemaining % 60
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        statusLabel.stringValue = String(
            format: "已排程：%@ 執行，剩餘 %02d:%02d:%02d。%@",
            timeFormatter.string(from: plan.targetDate), hours, minutes, seconds, emergencyStopHint()
        )
    }

    private func installEmergencyKeyMonitors() {
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 100 else { return }
            DispatchQueue.main.async { self?.cancelSchedule(message: "已用 F8 緊急停止。", emergency: true) }
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 100 else { return event }
            self?.cancelSchedule(message: "已用 F8 緊急停止。", emergency: true)
            return nil
        }
    }

    private func emergencyStopHint() -> String {
        if globalKeyMonitor != nil || localKeyMonitor != nil {
            return "可按 F8（部分鍵盤需 Fn+F8）或取消排程停止。"
        }
        return "F8 監聽不可用，請用取消排程按鈕停止。"
    }

    private func validateUserInterface() -> Bool {
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
        return absoluteModeIsValid && delayModeIsValid && readable
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
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.runModal()
    }
}
