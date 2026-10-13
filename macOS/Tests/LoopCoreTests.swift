import Foundation

final class FakeActions: LoopActions {
    var events: [String] = []
    var fail: String?
    var after: (() -> Void)?
    func record(_ step: String) throws {
        events.append(step)
        if fail == step { throw NSError(domain: "test", code: 1) }
        after?()
    }
    func focusInput() throws { try record("focus") }
    func paste(_ prompt: String, replaceDraft: Bool) throws { try record("paste:\(prompt):\(replaceDraft)") }
    func send() throws { try record("send") }
}

let wall = Date(timeIntervalSince1970: 2_000_000_000)
var checks = 0
var failures = 0
var clock: TimeInterval = 100
func plan() -> LoopPlan { LoopPlan(firstTime: wall.addingTimeInterval(10), interval: 60, maxRounds: 2, prompts: ["中文\nline 2 😀", "B"]) }
func check(_ value: Bool, _ name: String) { checks += 1; if !value { failures += 1; print("FAIL: \(name)") } }
func start(_ actions: FakeActions, _ plan: LoopPlan) -> LoopEngine {
    clock = 100
    let engine = LoopEngine(actions: actions, completionClock: { clock })
    do { try engine.start(plan, wall: wall, mono: 100) } catch { fatalError("Invalid test plan: \(error)") }
    return engine
}
func tick(_ engine: LoopEngine, _ seconds: Double) { clock = 100 + seconds; engine.tick(wall: wall.addingTimeInterval(seconds), mono: clock) }
func round(_ engine: LoopEngine, _ at: Double) { tick(engine, at); tick(engine, at + 1); tick(engine, at + 2) }

var p = plan(); check(p.validate(now: wall) == nil, "valid multiline unicode plan")
p.maxRounds = nil; check(p.validate(now: wall) != nil, "requires stop bound")
p.deadline = wall.addingTimeInterval(11); check(p.validate(now: wall) == nil, "deadline-only accepted")
p.deadline = p.firstTime; check(p.validate(now: wall) != nil, "deadline must follow first")
p = plan(); p.prompts[0] = " "; check(p.validate(now: wall) != nil, "blank rejected")
p.prompts[0] = "a\0b"; check(p.validate(now: wall) != nil, "NUL rejected")
p.prompts[0] = String(repeating: "x", count: 20001); check(p.validate(now: wall) != nil, "oversize rejected")
p = plan(); p.interval = 9; check(p.validate(now: wall) != nil, "short interval rejected")
p = plan(); p.maxRounds = 0; check(p.validate(now: wall) != nil, "zero count rejected")
p = plan(); p.sequence = true; p.repeatLast = true
check(p.prompt(at: 0) != p.prompt(at: 1) && p.prompt(at: 2) == "B", "repeat final opt-in")

var a = FakeActions(); var e = start(a, plan())
tick(e, 9); check(a.events.isEmpty, "nothing before first")
tick(e, 10); check(a.events == ["focus"], "focus only first step")
tick(e, 10.5); check(a.events.count == 1, "wait before paste")
tick(e, 11); check(a.events.last == "paste:中文\nline 2 😀:false", "unicode intact")
tick(e, 12); check(e.completed == 1 && e.active && a.events.last == "send", "count after click")
tick(e, 71); check(a.events.count == 3, "interval from completion")
round(e, 72); check(!e.active && e.completed == 2 && a.events[4] == a.events[1], "same prompt and count stop")
tick(e, 1000); check(a.events.count == 6, "no events after stop")
p = plan(); p.sequence = true; p.maxRounds = 10
a = FakeActions(); e = start(a, p); round(e, 10); round(e, 72)
check(!e.active && e.completed == 2 && a.events[4] == "paste:B:false", "sequence exhaustion")
p = plan(); p.sequence = true; p.repeatLast = true; p.maxRounds = 3; p.replaceDraft = true
a = FakeActions(); e = start(a, p); round(e, 10); round(e, 72); round(e, 134)
check(!e.active && e.completed == 3 && a.events[7] == "paste:B:true", "repeat final bounded and replace")
for stage in 0..<3 {
    a = FakeActions(); e = start(a, plan())
    if stage > 0 { tick(e, 10) }; if stage > 1 { tick(e, 11) }
    e.stop("cancel"); tick(e, 12); tick(e, 100)
    check(a.events.count == stage && e.completed == 0, "cancel stage \(stage)")
}
a = FakeActions(); a.fail = "paste:中文\nline 2 😀:false"; e = start(a, plan()); round(e, 10); tick(e, 100)
check(!e.active && a.events.count == 2 && e.status.contains("草稿"), "paste failure no retry or send")
a = FakeActions(); a.fail = "send"; e = start(a, plan()); round(e, 10)
check(!e.active && e.completed == 0, "failed send not counted")
p = plan(); p.deadline = wall.addingTimeInterval(11.5); a = FakeActions(); e = start(a, p); round(e, 10)
check(!e.active && a.events.count == 2, "deadline mid-round")
p = plan(); p.deadline = wall.addingTimeInterval(15); a = FakeActions(); e = start(a, p)
e.togglePause(wall: wall.addingTimeInterval(1), mono: 101); tick(e, 15)
check(!e.active && a.events.isEmpty, "deadline while paused")
a = FakeActions(); e = start(a, plan()); e.togglePause(wall: wall.addingTimeInterval(4), mono: 104); tick(e, 20)
check(e.paused && a.events.isEmpty, "pause holds")
e.togglePause(wall: wall.addingTimeInterval(20), mono: 120); tick(e, 25); check(a.events.isEmpty, "resume remaining delay")
round(e, 26); check(e.completed == 1, "resume once")
a = FakeActions(); e = start(a, plan()); tick(e, 10); e.togglePause(wall: wall.addingTimeInterval(10.5), mono: 110.5); tick(e, 11)
check(!e.active && a.events.count == 1, "mid-round pause stops")
a = FakeActions(); e = start(a, plan()); tick(e, 16); check(!e.active && a.events.isEmpty, "late first stops")
a = FakeActions(); e = start(a, plan()); tick(e, 10); tick(e, 17); check(!e.active && a.events.count == 1, "late step stops")
a = FakeActions(); e = start(a, plan()); round(e, 10)
e.tick(wall: wall.addingTimeInterval(3600), mono: 130); check(a.events.count == 3, "forward wall change")
clock = 172; e.tick(wall: wall.addingTimeInterval(-3600), mono: clock); check(a.events.count == 4, "monotonic interval")
p = plan(); a = FakeActions(); e = start(a, p); p.prompts[0] = "changed"; p.maxRounds = 99
round(e, 10); round(e, 72); check(!e.active && a.events[1].contains("中文"), "snapshot edits")
a = FakeActions(); a.after = { clock += 4 }; e = start(a, plan())
tick(e, 10); tick(e, 14.5); check(a.events.count == 1, "slow focus retains full delay")
tick(e, 15); tick(e, 19.5); check(a.events.count == 2, "slow paste retains full delay")
tick(e, 20); tick(e, 83.5); check(a.events.count == 3, "interval after slow send")
tick(e, 84); check(a.events.count == 4, "next round completion clock")
print("RESULT: \(checks - failures) passed, \(failures) failed")
exit(failures == 0 ? 0 : 1)
