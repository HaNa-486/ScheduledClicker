import Cocoa

private var passed = 0
private var failed = 0

private func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    if condition() {
        passed += 1
        print("PASS: \(name)")
    } else {
        failed += 1
        print("FAIL: \(name)")
    }
}

let now = Date(timeIntervalSince1970: 2_000_000_000)
let screen = CGRect(x: -1000, y: 0, width: 3000, height: 1200)
let validPoint = CGPoint(x: 100, y: 100)

let validPlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(10), point: validPoint, clickType: .single)
check(PlanValidator.validate(validPlan, now: now, displayBounds: [screen]) == nil, "valid plan")

let pastPlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(-1), point: validPoint, clickType: .single)
check(PlanValidator.validate(pastPlan, now: now, displayBounds: [screen]) != nil, "past time rejected")

let farPlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(366 * 24 * 60 * 60), point: validPoint, clickType: .single)
check(PlanValidator.validate(farPlan, now: now, displayBounds: [screen]) != nil, "more than 365 days rejected")

let offscreenPlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(10), point: CGPoint(x: 5000, y: 5000), clickType: .single)
check(PlanValidator.validate(offscreenPlan, now: now, displayBounds: [screen]) != nil, "off-screen point rejected")

let negativePointPlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(10), point: CGPoint(x: -500, y: 100), clickType: .double)
check(PlanValidator.validate(negativePointPlan, now: now, displayBounds: [screen]) == nil, "negative multi-display coordinate accepted")

let delayedPlan = ScheduledClickPlan.afterDelay(60, wallNow: now, uptimeNow: 100, point: validPoint, clickType: .single)
check(abs(delayedPlan.remaining(wallNow: now, uptimeNow: 120) - 40) < 0.001, "delay uses monotonic clock")
check(abs(delayedPlan.remaining(wallNow: now.addingTimeInterval(600), uptimeNow: 120) - 40) < 0.001, "wall-clock jump does not change delay")

let absolutePlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(60), point: validPoint, clickType: .single)
check(abs(absolutePlan.remaining(wallNow: now.addingTimeInterval(10), uptimeNow: 999) - 50) < 0.001, "absolute schedule follows wall clock")

check(ScheduledClickType.single.displayName == "單擊", "single-click label")
check(ScheduledClickType.double.displayName == "雙擊", "double-click label")

let snapshotA = DisplaySnapshot(entries: [.init(id: 1, bounds: screen)])
let snapshotACopy = DisplaySnapshot(entries: [.init(id: 1, bounds: screen)])
let snapshotB = DisplaySnapshot(entries: [.init(id: 1, bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080))])
check(snapshotA == snapshotACopy, "identical display snapshots match")
check(snapshotA != snapshotB, "changed display geometry is detected")

var engineNow = now
var engineUptime: TimeInterval = 500
var clickCount = 0
var executedCount = 0
var failedCount = 0
let engine = ScheduleEngine(
    now: { engineNow },
    uptime: { engineUptime },
    pointIsActive: { _ in true },
    displaySnapshot: { snapshotA },
    click: { _, _ in clickCount += 1 }
)
engine.onExecuted = { _ in executedCount += 1 }
engine.onFailed = { _ in failedCount += 1 }
let duePlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(1), point: validPoint, clickType: .single, displaySnapshot: snapshotA)
engine.arm(duePlan, scheduleAutomatically: false)
check(engine.isArmed, "engine arms a plan")
engineNow = now.addingTimeInterval(2)
engine.evaluateNowForTesting()
check(clickCount == 1 && executedCount == 1 && failedCount == 0, "due plan executes once and reports success")
check(!engine.isArmed && !engine.isExecuting, "engine clears state after success")

let cancelEngine = ScheduleEngine(
    now: { now },
    uptime: { 100 },
    pointIsActive: { _ in true },
    displaySnapshot: { snapshotA },
    click: { _, _ in }
)
cancelEngine.arm(duePlan, scheduleAutomatically: false)
check(cancelEngine.cancel() == .canceled && !cancelEngine.isArmed, "cancel disarms pending plan")
check(cancelEngine.cancel() == .nothingScheduled, "second cancel reports nothing scheduled")

var lateNow = now
var lateFailures = 0
var lateClicks = 0
let lateEngine = ScheduleEngine(
    now: { lateNow },
    uptime: { 100 },
    pointIsActive: { _ in true },
    displaySnapshot: { snapshotA },
    click: { _, _ in lateClicks += 1 }
)
lateEngine.onFailed = { _ in lateFailures += 1 }
lateEngine.arm(duePlan, scheduleAutomatically: false)
lateNow = now.addingTimeInterval(7)
lateEngine.evaluateNowForTesting()
check(lateFailures == 1 && lateClicks == 0, "plan more than five seconds late fails closed")

var changedNow = now
var changedFailures = 0
var changedClicks = 0
let changedDisplayEngine = ScheduleEngine(
    now: { changedNow },
    uptime: { 100 },
    pointIsActive: { _ in true },
    displaySnapshot: { snapshotB },
    click: { _, _ in changedClicks += 1 }
)
changedDisplayEngine.onFailed = { _ in changedFailures += 1 }
changedDisplayEngine.arm(duePlan, scheduleAutomatically: false)
changedNow = now.addingTimeInterval(2)
changedDisplayEngine.evaluateNowForTesting()
check(changedFailures == 1 && changedClicks == 0, "display configuration change fails closed")

var errorNow = now
var clickFailures = 0
let clickFailureEngine = ScheduleEngine(
    now: { errorNow },
    uptime: { 100 },
    pointIsActive: { _ in true },
    displaySnapshot: { snapshotA },
    click: { _, _ in throw NSError(domain: "test", code: 9) }
)
clickFailureEngine.onFailed = { _ in clickFailures += 1 }
clickFailureEngine.arm(duePlan, scheduleAutomatically: false)
errorNow = now.addingTimeInterval(2)
clickFailureEngine.evaluateNowForTesting()
check(clickFailures == 1 && !clickFailureEngine.isArmed, "native click failure reports error and clears plan")

let replacementEngine = ScheduleEngine(
    now: { now },
    uptime: { 100 },
    pointIsActive: { _ in true },
    displaySnapshot: { snapshotA },
    click: { _, _ in }
)
let laterPlan = ScheduledClickPlan(targetDate: now.addingTimeInterval(20), point: validPoint, clickType: .double, displaySnapshot: snapshotA)
replacementEngine.arm(duePlan, scheduleAutomatically: false)
replacementEngine.arm(laterPlan, scheduleAutomatically: false)
check(replacementEngine.currentPlan?.targetDate == laterPlan.targetDate, "rearming replaces the previous plan")

print("RESULT: \(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
