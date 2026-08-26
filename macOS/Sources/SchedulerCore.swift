import Cocoa

enum ScheduledClickType: Int {
    case single = 1
    case double = 2

    var displayName: String {
        self == .double ? "雙擊" : "單擊"
    }
}

enum ScheduleCancelResult: Equatable {
    case canceled
    case executing
    case nothingScheduled
}

struct ScheduledClickPlan {
    let targetDate: Date
    let point: CGPoint
    let clickType: ScheduledClickType
    let displaySnapshot: DisplaySnapshot?
    private let monotonicDeadline: TimeInterval?

    init(
        targetDate: Date,
        point: CGPoint,
        clickType: ScheduledClickType,
        displaySnapshot: DisplaySnapshot? = nil,
        monotonicDeadline: TimeInterval? = nil
    ) {
        self.targetDate = targetDate
        self.point = point
        self.clickType = clickType
        self.displaySnapshot = displaySnapshot
        self.monotonicDeadline = monotonicDeadline
    }

    static func afterDelay(
        _ delay: TimeInterval,
        wallNow: Date,
        uptimeNow: TimeInterval,
        point: CGPoint,
        clickType: ScheduledClickType,
        displaySnapshot: DisplaySnapshot? = nil
    ) -> ScheduledClickPlan {
        ScheduledClickPlan(
            targetDate: wallNow.addingTimeInterval(delay),
            point: point,
            clickType: clickType,
            displaySnapshot: displaySnapshot,
            monotonicDeadline: uptimeNow + delay
        )
    }

    func remaining(wallNow: Date, uptimeNow: TimeInterval) -> TimeInterval {
        if let monotonicDeadline {
            return monotonicDeadline - uptimeNow
        }
        return targetDate.timeIntervalSince(wallNow)
    }
}

enum PlanValidator {
    static func validate(_ plan: ScheduledClickPlan, now: Date, displayBounds: [CGRect]) -> String? {
        if plan.targetDate <= now {
            return "執行時間必須晚於現在。"
        }
        if plan.targetDate > now.addingTimeInterval(365 * 24 * 60 * 60) {
            return "執行時間最多可設定在 365 天內。"
        }
        if !displayBounds.contains(where: { $0.contains(plan.point) }) {
            return "點擊位置不在目前可用的螢幕範圍內。"
        }
        return nil
    }
}

struct DisplaySnapshot: Equatable {
    struct Entry: Equatable {
        let id: CGDirectDisplayID
        let bounds: CGRect
    }

    let entries: [Entry]

    var bounds: [CGRect] { entries.map(\.bounds) }

    func contains(_ point: CGPoint) -> Bool {
        entries.contains(where: { $0.bounds.contains(point) })
    }
}

enum ActiveDisplays {
    static func snapshot() -> DisplaySnapshot? {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else { return nil }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        var actualCount: UInt32 = 0
        guard CGGetActiveDisplayList(count, &displays, &actualCount) == .success else { return nil }
        let entries = displays.prefix(Int(actualCount))
            .map { DisplaySnapshot.Entry(id: $0, bounds: CGDisplayBounds($0)) }
            .sorted { $0.id < $1.id }
        return DisplaySnapshot(entries: entries)
    }

    static func bounds() -> [CGRect] {
        snapshot()?.bounds ?? []
    }

    static func contains(_ point: CGPoint) -> Bool {
        snapshot()?.contains(point) ?? false
    }
}

enum MacMouse {
    static func currentLocation() -> CGPoint? {
        CGEvent(source: nil)?.location
    }

    static func makeClickEvents(at point: CGPoint, clickType: ScheduledClickType) throws -> [CGEvent] {
        guard ActiveDisplays.contains(point) else {
            throw NSError(
                domain: "ScheduledClicker",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "螢幕配置已改變，原先位置已不在可用螢幕上，已取消點擊。"]
            )
        }

        guard let source = CGEventSource(stateID: .hidSystemState),
              let move = CGEvent(mouseEventSource: source, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left),
              let firstDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let firstUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            throw NSError(
                domain: "ScheduledClicker",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "macOS 無法建立滑鼠事件。"]
            )
        }

        firstDown.setIntegerValueField(.mouseEventClickState, value: 1)
        firstUp.setIntegerValueField(.mouseEventClickState, value: 1)
        var events = [move, firstDown, firstUp]

        if clickType == .double {
            guard let secondDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
                  let secondUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
                throw NSError(
                    domain: "ScheduledClicker",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "macOS 無法建立雙擊事件。"]
                )
            }
            secondDown.setIntegerValueField(.mouseEventClickState, value: 2)
            secondUp.setIntegerValueField(.mouseEventClickState, value: 2)
            events.append(contentsOf: [secondDown, secondUp])
        }
        return events
    }

    static func click(at point: CGPoint, clickType: ScheduledClickType) throws {
        guard AXIsProcessTrusted() else {
            throw NSError(
                domain: "ScheduledClicker",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "尚未授予『輔助使用』權限，macOS 已阻止滑鼠控制。"]
            )
        }

        let events = try makeClickEvents(at: point, clickType: clickType)
        for (index, event) in events.enumerated() {
            event.post(tap: .cghidEventTap)
            if clickType == .double && index == 2 {
                Thread.sleep(forTimeInterval: 0.08)
            }
        }
    }
}

final class ScheduleEngine {
    private let now: () -> Date
    private let uptime: () -> TimeInterval
    private let pointIsActive: (CGPoint) -> Bool
    private let displaySnapshot: () -> DisplaySnapshot?
    private let click: (CGPoint, ScheduledClickType) throws -> Void
    private var workItem: DispatchWorkItem?
    private var generation = 0
    private(set) var currentPlan: ScheduledClickPlan?
    private(set) var isExecuting = false

    var onExecuted: ((ScheduledClickPlan) -> Void)?
    var onFailed: ((Error) -> Void)?

    init(
        now: @escaping () -> Date = Date.init,
        uptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        pointIsActive: @escaping (CGPoint) -> Bool = { ActiveDisplays.contains($0) },
        displaySnapshot: @escaping () -> DisplaySnapshot? = { ActiveDisplays.snapshot() },
        click: @escaping (CGPoint, ScheduledClickType) throws -> Void = { point, clickType in
            try MacMouse.click(at: point, clickType: clickType)
        }
    ) {
        self.now = now
        self.uptime = uptime
        self.pointIsActive = pointIsActive
        self.displaySnapshot = displaySnapshot
        self.click = click
    }

    var isArmed: Bool { currentPlan != nil }

    func arm(_ plan: ScheduledClickPlan) {
        arm(plan, scheduleAutomatically: true)
    }

    func arm(_ plan: ScheduledClickPlan, scheduleAutomatically: Bool) {
        _ = cancel()
        currentPlan = plan
        generation += 1
        if scheduleAutomatically {
            scheduleNext(expectedGeneration: generation)
        }
    }

    @discardableResult
    func cancel() -> ScheduleCancelResult {
        let result: ScheduleCancelResult
        if currentPlan != nil {
            result = .canceled
        } else if isExecuting {
            result = .executing
        } else {
            result = .nothingScheduled
        }

        generation += 1
        currentPlan = nil
        workItem?.cancel()
        workItem = nil
        return result
    }

    func remainingNow() -> TimeInterval? {
        currentPlan?.remaining(wallNow: now(), uptimeNow: uptime())
    }

    func evaluateNowForTesting() {
        guard let plan = currentPlan else { return }
        let remaining = plan.remaining(wallNow: now(), uptimeNow: uptime())
        guard remaining <= 0 else { return }
        execute(plan, expectedGeneration: generation)
    }

    private func scheduleNext(expectedGeneration: Int) {
        guard let plan = currentPlan, expectedGeneration == generation else { return }
        let remaining = plan.remaining(wallNow: now(), uptimeNow: uptime())
        if remaining <= 0 {
            execute(plan, expectedGeneration: expectedGeneration)
            return
        }

        let delay: TimeInterval
        if remaining <= 2 { delay = 0.02 }
        else if remaining <= 30 { delay = 0.25 }
        else { delay = 1.0 }

        let item = DispatchWorkItem { [weak self] in
            self?.scheduleNext(expectedGeneration: expectedGeneration)
        }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + min(delay, remaining), execute: item)
    }

    private func execute(_ plan: ScheduledClickPlan, expectedGeneration: Int) {
        guard expectedGeneration == generation, currentPlan != nil else { return }
        currentPlan = nil
        workItem = nil
        isExecuting = true

        do {
            let lateness = -plan.remaining(wallNow: now(), uptimeNow: uptime())
            if lateness > 5 {
                throw NSError(
                    domain: "ScheduledClicker",
                    code: 5,
                    userInfo: [NSLocalizedDescriptionKey: "已錯過預定時間超過 5 秒，為避免誤點擊已取消。"]
                )
            }
            if let expectedSnapshot = plan.displaySnapshot {
                guard let currentSnapshot = displaySnapshot(), currentSnapshot == expectedSnapshot else {
                    throw NSError(
                        domain: "ScheduledClicker",
                        code: 7,
                        userInfo: [NSLocalizedDescriptionKey: "螢幕配置已變更，為避免點到不同內容已取消點擊。"]
                    )
                }
            }
            guard pointIsActive(plan.point) else {
                throw NSError(
                    domain: "ScheduledClicker",
                    code: 6,
                    userInfo: [NSLocalizedDescriptionKey: "螢幕配置已改變，原先位置已不在可用螢幕上，已取消點擊。"]
                )
            }
            try click(plan.point, plan.clickType)
            isExecuting = false
            onExecuted?(plan)
        } catch {
            isExecuting = false
            onFailed?(error)
        }
    }
}
