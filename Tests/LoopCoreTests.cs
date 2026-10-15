using System;
using System.Collections.Generic;
using ScheduledClicker;

internal sealed class FakeActions : ILoopActions
{
    internal readonly List<string> Events = new List<string>();
    internal string Fail;
    internal Action After;
    private void Record(string step) { Events.Add(step); if (Fail == step) throw new Exception("test failure"); if (After != null) After(); }
    public void FocusInput() { Record("focus"); }
    public void Paste(string prompt, bool replaceDraft) { Record("paste:" + prompt + ":" + replaceDraft); }
    public void Send() { Record("send"); }
}

internal static class LoopCoreTests
{
    private static readonly DateTime Wall = new DateTime(2026, 10, 13, 12, 0, 0);
    private static int checks;
    private static int failures;
    private static double clock;
    private static LoopPlan Plan() { return new LoopPlan { FirstTime = Wall.AddSeconds(10), Interval = TimeSpan.FromSeconds(60), MaxRounds = 2, Prompts = new[] { "中文\nline 2 😀", "B" } }; }
    private static void Check(bool value, string name) { checks++; if (!value) { failures++; Console.WriteLine("FAIL: " + name); } }
    private static LoopEngine Start(FakeActions actions, LoopPlan plan) { clock = 100; var e = new LoopEngine(actions, delegate { return clock; }); e.Start(plan, Wall, clock); return e; }
    private static void Tick(LoopEngine e, double seconds) { clock = 100 + seconds; e.Tick(Wall.AddSeconds(seconds), clock); }
    private static void Round(LoopEngine e, double at) { Tick(e, at); Tick(e, at + 1); Tick(e, at + 2); }
    private static void Main()
    {
        var p = Plan(); Check(p.Validate(Wall) == null, "valid multiline unicode plan");
        p.MaxRounds = null; Check(p.Validate(Wall) != null, "requires stop bound");
        p.Deadline = Wall.AddSeconds(11); Check(p.Validate(Wall) == null, "deadline-only accepted");
        p.Deadline = p.FirstTime; Check(p.Validate(Wall) != null, "deadline must follow first");
        p = Plan(); p.Prompts[0] = " "; Check(p.Validate(Wall) != null, "blank prompt rejected");
        p.Prompts[0] = "a\0b"; Check(p.Validate(Wall) != null, "NUL rejected");
        p.Prompts[0] = new string('x', 20001); Check(p.Validate(Wall) != null, "oversize rejected");
        p = Plan(); p.Interval = TimeSpan.FromSeconds(9); Check(p.Validate(Wall) != null, "short interval rejected");
        p = Plan(); p.MaxRounds = 0; Check(p.Validate(Wall) != null, "zero count rejected");
        p = Plan(); p.Sequence = true; p.RepeatLast = true;
        Check(p.PromptAt(0) != p.PromptAt(1) && p.PromptAt(2) == "B", "sequence repeats final when opted in");

        var a = new FakeActions(); var e = Start(a, Plan());
        Tick(e, 9); Check(a.Events.Count == 0, "nothing before first time");
        Tick(e, 10); Check(a.Events.Count == 1 && a.Events[0] == "focus", "first step only focus");
        Tick(e, 10.5); Check(a.Events.Count == 1, "wait before paste");
        Tick(e, 11); Check(a.Events[1] == "paste:中文\nline 2 😀:False", "unicode passed intact");
        Tick(e, 12); Check(e.Completed == 1 && e.Active && a.Events[2] == "send", "first round counted after click");
        Tick(e, 71); Check(a.Events.Count == 3, "interval from round completion");
        Round(e, 72); Check(!e.Active && e.Completed == 2 && a.Events[4] == a.Events[1], "same prompt and count stop");
        Tick(e, 1000); Check(a.Events.Count == 6, "no events after completion");

        p = Plan(); p.Sequence = true; p.MaxRounds = 10;
        a = new FakeActions(); e = Start(a, p); Round(e, 10); Round(e, 72);
        Check(!e.Active && e.Completed == 2 && a.Events[4] == "paste:B:False", "sequence exhaustion stops below count cap");
        p = Plan(); p.Sequence = true; p.RepeatLast = true; p.MaxRounds = 3; p.ReplaceDraft = true;
        a = new FakeActions(); e = Start(a, p); Round(e, 10); Round(e, 72); Round(e, 134);
        Check(!e.Active && e.Completed == 3 && a.Events[7] == "paste:B:True", "repeat last honors count and replace option");

        for (int stage = 0; stage < 3; stage++)
        {
            a = new FakeActions(); e = Start(a, Plan());
            if (stage > 0) Tick(e, 10); if (stage > 1) Tick(e, 11);
            e.Stop("cancel"); Tick(e, 12); Tick(e, 100);
            Check(a.Events.Count == stage && e.Completed == 0, "cancel blocks later steps at stage " + stage);
        }
        a = new FakeActions { Fail = "paste:中文\nline 2 😀:False" }; e = Start(a, Plan()); Round(e, 10); Tick(e, 100);
        Check(!e.Active && a.Events.Count == 2 && e.Status.Contains("草稿"), "paste failure stops without retry or send");
        a = new FakeActions { Fail = "send" }; e = Start(a, Plan()); Round(e, 10);
        Check(!e.Active && e.Completed == 0, "failed send not counted or retried");

        p = Plan(); p.Deadline = Wall.AddSeconds(11.5); a = new FakeActions(); e = Start(a, p); Round(e, 10);
        Check(!e.Active && a.Events.Count == 2, "deadline aborts mid-round before send");
        p = Plan(); p.Deadline = Wall.AddSeconds(15); a = new FakeActions(); e = Start(a, p);
        e.TogglePause(Wall.AddSeconds(1), 101); Tick(e, 15);
        Check(!e.Active && a.Events.Count == 0, "deadline expires while paused");
        a = new FakeActions(); e = Start(a, Plan()); e.TogglePause(Wall.AddSeconds(4), 104); Tick(e, 20);
        Check(e.Paused && a.Events.Count == 0, "pause holds pending round");
        e.TogglePause(Wall.AddSeconds(20), 120); Tick(e, 25); Check(a.Events.Count == 0, "resume preserves remaining delay");
        Round(e, 26); Check(e.Completed == 1, "resume runs once after remaining delay");
        a = new FakeActions(); e = Start(a, Plan()); Tick(e, 10); e.TogglePause(Wall.AddSeconds(10.5), 110.5); Tick(e, 11);
        Check(!e.Active && a.Events.Count == 1, "pause mid-round stops, never silently replays");

        a = new FakeActions(); e = Start(a, Plan()); Tick(e, 16); Check(!e.Active && a.Events.Count == 0, "missed first time stops no catch-up");
        a = new FakeActions(); e = Start(a, Plan()); Tick(e, 10); Tick(e, 17); Check(!e.Active && a.Events.Count == 1, "missed intermediate step stops");
        a = new FakeActions(); e = Start(a, Plan()); Round(e, 10);
        e.Tick(Wall.AddHours(1), 130); Check(a.Events.Count == 3, "interval ignores forward wall-clock changes");
        clock = 172; e.Tick(Wall.AddHours(-1), clock); Check(a.Events.Count == 4, "interval follows monotonic clock");
        p = Plan(); a = new FakeActions(); e = Start(a, p); p.Prompts[0] = "changed"; p.MaxRounds = 99;
        Round(e, 10); Round(e, 72); Check(!e.Active && a.Events[1].Contains("中文"), "active plan snapshots edits");
        a = new FakeActions { After = delegate { clock += 4; } }; e = Start(a, Plan());
        Tick(e, 10); Tick(e, 14.5); Check(a.Events.Count == 1, "slow focus retains full settle delay");
        Tick(e, 15); Tick(e, 19.5); Check(a.Events.Count == 2, "slow paste retains full settle delay");
        Tick(e, 20); Tick(e, 83.5); Check(a.Events.Count == 3, "interval begins after slow send completes");
        Tick(e, 84); Check(a.Events.Count == 4, "next round follows completion clock");
        Console.WriteLine("RESULT: " + (checks - failures) + " passed, " + failures + " failed"); Environment.ExitCode = failures == 0 ? 0 : 1;
    }
}
