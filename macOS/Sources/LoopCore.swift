import Foundation

struct LoopPlan {
    var firstTime: Date
    var interval: TimeInterval
    var stepDelay: TimeInterval = 1
    var maxRounds: Int?
    var deadline: Date?
    var prompts: [String]
    var sequence = false
    var repeatLast = false
    var replaceDraft = false

    func validate(now: Date) -> String? {
        if firstTime <= now || firstTime > now.addingTimeInterval(365 * 86400) { return "首次時間須在未來 365 天內。" }
        if !interval.isFinite || interval < 10 || interval > 365 * 86400 { return "間隔須介於 10 秒與 365 天。" }
        if !stepDelay.isFinite || stepDelay < 1 || stepDelay > 10 { return "步驟等待須介於 1–10 秒。" }
        if maxRounds == nil && deadline == nil { return "請設定執行次數或截止時間。" }
        if let maxRounds, !(1...10000).contains(maxRounds) { return "執行次數須介於 1–10000。" }
        if let deadline, deadline <= firstTime || deadline > now.addingTimeInterval(365 * 86400) { return "截止時間須晚於首次時間，且在未來 365 天內。" }
        if prompts.isEmpty { return "請輸入提示詞。" }
        for prompt in (sequence ? prompts : Array(prompts.prefix(1))) {
            if prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || prompt.utf16.count > 20000 || prompt.contains("\0") {
                return "每筆提示詞須為 1–20000 字元，且不可空白或含空字元。"
            }
        }
        return nil
    }

    func prompt(at round: Int) -> String? {
        if !sequence { return prompts.first }
        if round < prompts.count { return prompts[round] }
        return repeatLast ? prompts.last : nil
    }
}

protocol LoopActions: AnyObject {
    func focusInput() throws
    func paste(_ prompt: String, replaceDraft: Bool) throws
    func send() throws
}

// Owned and ticked by the main thread; cancellation removes every future step.
final class LoopEngine {
    private let actions: LoopActions
    private let completionClock: () -> TimeInterval
    private var plan: LoopPlan!
    private var stage = 0
    private var due: TimeInterval = 0
    private var first = true
    private var pausedRemaining: TimeInterval = 0
    private(set) var active = false
    private(set) var paused = false
    private(set) var completed = 0
    private(set) var status = "等待設定。"
    var betweenRounds: Bool { stage == 0 }

    init(actions: LoopActions, completionClock: @escaping () -> TimeInterval) { self.actions = actions; self.completionClock = completionClock }

    func start(_ newPlan: LoopPlan, wall: Date, mono: TimeInterval) throws {
        if let error = newPlan.validate(now: wall) {
            throw NSError(domain: "Loop", code: 1, userInfo: [NSLocalizedDescriptionKey: error])
        }
        plan = newPlan
        stage = 0; completed = 0; first = true; active = true; paused = false
        due = mono + plan.firstTime.timeIntervalSince(wall)
        status = "等待首次執行。"
    }

    func stop(_ reason: String) {
        active = false; paused = false
        status = reason + (stage == 0 ? "" : " 本輪可能留下草稿，重新啟動前請檢查。已發生的操作無法撤回。")
    }

    func togglePause(wall: Date, mono: TimeInterval) {
        guard active else { return }
        if let deadline = plan.deadline, wall >= deadline { stop("已到截止時間。"); return }
        if stage != 0 { stop("已停止進行中的本輪。"); return }
        if paused { due = mono + pausedRemaining; first = false; paused = false; status = "已恢復等待。" }
        else { pausedRemaining = max(0, remaining(wall: wall, mono: mono)); paused = true; status = "已暫停；截止時間仍有效。" }
    }

    func remaining(wall: Date, mono: TimeInterval) -> TimeInterval {
        first && stage == 0 ? plan.firstTime.timeIntervalSince(wall) : due - mono
    }

    func tick(wall: Date, mono: TimeInterval) {
        guard active else { return }
        if let deadline = plan.deadline, wall >= deadline { stop("已到截止時間。"); return }
        if paused { return }
        let left = remaining(wall: wall, mono: mono)
        if left > 0 { return }
        if left < -5 { stop("已錯過步驟超過 5 秒，排程停止，不補送。"); return }
        do {
            if stage == 0 {
                try actions.focusInput()
                first = false; stage = 1; due = completionClock() + plan.stepDelay
                status = "已點輸入框，等待貼上。"
            } else if stage == 1 {
                try actions.paste(plan.prompt(at: completed)!, replaceDraft: plan.replaceDraft)
                stage = 2; due = completionClock() + plan.stepDelay
                status = "已貼上，等待點擊送出。"
            } else {
                try actions.send()
                completed += 1; stage = 0
                if (plan.maxRounds.map { completed >= $0 } ?? false) || plan.prompt(at: completed) == nil {
                    stop("已完成設定的操作輪次；未驗證訊息是否送達。"); return
                }
                due = completionClock() + plan.interval
                status = "本輪已執行送出點擊；未驗證送達，等待下一輪。"
            }
        } catch { stop("執行失敗，已停止且不重試：" + error.localizedDescription) }
    }
}
