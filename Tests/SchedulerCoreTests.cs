using System;
using System.Drawing;
using System.Diagnostics;
using ScheduledClicker;

internal static class SchedulerCoreTests
{
    private static int failures;

    private static void Main()
    {
        DateTime now = new DateTime(2026, 8, 26, 12, 0, 0);
        Rectangle screen = new Rectangle(-1920, 0, 3840, 1080);
        Expect(null, PlanValidator.Validate(new ClickPlan(now.AddSeconds(1), new Point(0, 0), ClickKind.Single), now, screen), "valid single click");
        Expect(null, PlanValidator.Validate(new ClickPlan(now.AddDays(365), new Point(-1920, 0), ClickKind.Double), now, screen), "valid boundary and secondary monitor");
        Expect("執行時間必須晚於現在。", PlanValidator.Validate(new ClickPlan(now, new Point(0, 0), ClickKind.Single), now, screen), "reject current time");
        Expect("執行時間最多可設定在 365 天內。", PlanValidator.Validate(new ClickPlan(now.AddDays(366), new Point(0, 0), ClickKind.Single), now, screen), "reject far future");
        Expect("點擊位置不在目前可用的螢幕範圍內。", PlanValidator.Validate(new ClickPlan(now.AddSeconds(1), new Point(1920, 0), ClickKind.Single), now, screen), "reject outside screen");
        Expect("點擊類型無效。", PlanValidator.Validate(new ClickPlan(now.AddSeconds(1), new Point(0, 0), (ClickKind)3), now, screen), "reject invalid click type");
        using (var service = new ScheduleService())
        {
            service.Arm(new ClickPlan(DateTime.Now.AddMinutes(1), new Point(0, 0), ClickKind.Single));
            ExpectCancel(CancelResult.Canceled, service.Cancel(), "cancel armed schedule");
            ExpectCancel(CancelResult.NothingScheduled, service.Cancel(), "cancel idle schedule");
        }
        long clockStart = 1000;
        var monotonicPlan = new ClickPlan(now.AddSeconds(10), new Point(0, 0), ClickKind.Single, clockStart + Stopwatch.Frequency * 10L);
        ExpectNear(10, monotonicPlan.Remaining(now.AddHours(5), clockStart).TotalSeconds, "delay ignores forward wall-clock jump");
        ExpectNear(5, monotonicPlan.Remaining(now.AddHours(-5), clockStart + Stopwatch.Frequency * 5L).TotalSeconds, "delay follows elapsed monotonic time");
        Console.WriteLine(failures == 0 ? "PASS: 10 tests" : "FAIL: " + failures + " test(s)");
        Environment.ExitCode = failures == 0 ? 0 : 1;
    }

    private static void Expect(string expected, string actual, string name)
    {
        if (expected == actual) return;
        failures++;
        Console.WriteLine("FAIL " + name + ": expected [" + expected + "] actual [" + actual + "]");
    }

    private static void ExpectCancel(CancelResult expected, CancelResult actual, string name)
    {
        if (expected == actual) return;
        failures++;
        Console.WriteLine("FAIL " + name + ": expected [" + expected + "] actual [" + actual + "]");
    }

    private static void ExpectNear(double expected, double actual, string name)
    {
        if (Math.Abs(expected - actual) < 0.001) return;
        failures++;
        Console.WriteLine("FAIL " + name + ": expected [" + expected + "] actual [" + actual + "]");
    }
}
