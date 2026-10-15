using System;

namespace ScheduledClicker
{
    internal sealed class LoopPlan
    {
        internal DateTime FirstTime;
        internal TimeSpan Interval;
        internal TimeSpan StepDelay = TimeSpan.FromSeconds(1);
        internal int? MaxRounds;
        internal DateTime? Deadline;
        internal string[] Prompts;
        internal bool Sequence;
        internal bool RepeatLast;
        internal bool ReplaceDraft;

        internal string Validate(DateTime now)
        {
            if (FirstTime <= now || FirstTime > now.AddDays(365)) return "首次時間須在未來 365 天內。";
            if (Interval.TotalSeconds < 10 || Interval.TotalDays > 365) return "間隔須介於 10 秒與 365 天。";
            if (StepDelay.TotalSeconds < 1 || StepDelay.TotalSeconds > 10) return "步驟等待須介於 1–10 秒。";
            if (!MaxRounds.HasValue && !Deadline.HasValue) return "請設定執行次數或截止時間。";
            if (MaxRounds.HasValue && (MaxRounds < 1 || MaxRounds > 10000)) return "執行次數須介於 1–10000。";
            if (Deadline.HasValue && (Deadline <= FirstTime || Deadline > now.AddDays(365))) return "截止時間須晚於首次時間，且在未來 365 天內。";
            if (Prompts == null || Prompts.Length == 0) return "請輸入提示詞。";
            int used = Sequence ? Prompts.Length : 1;
            for (int i = 0; i < used; i++)
                if (String.IsNullOrWhiteSpace(Prompts[i]) || Prompts[i].Length > 20000 || Prompts[i].IndexOf('\0') >= 0)
                    return "每筆提示詞須為 1–20000 字元，且不可空白或含空字元。";
            return null;
        }

        internal string PromptAt(int round)
        {
            if (!Sequence) return Prompts[0];
            if (round < Prompts.Length) return Prompts[round];
            return RepeatLast ? Prompts[Prompts.Length - 1] : null;
        }

        internal LoopPlan Snapshot()
        {
            var copy = (LoopPlan)MemberwiseClone();
            copy.Prompts = (string[])Prompts.Clone();
            return copy;
        }
    }

    internal interface ILoopActions
    {
        void FocusInput();
        void Paste(string prompt, bool replaceDraft);
        void Send();
    }

    // Called only on the UI thread. Each tick performs at most one atomic input step;
    // timers never queue an entire round, so cancel invalidates every later step.
    internal sealed class LoopEngine
    {
        private readonly ILoopActions actions;
        private readonly Func<double> completionClock;
        private LoopPlan plan;
        private int stage;
        private double due;
        private bool first;
        private double pausedRemaining;
        internal bool Active { get; private set; }
        internal bool Paused { get; private set; }
        internal int Completed { get; private set; }
        internal string Status { get; private set; }
        internal bool BetweenRounds { get { return stage == 0; } }

        internal LoopEngine(ILoopActions actions, Func<double> completionClock)
        { this.actions = actions; this.completionClock = completionClock; Status = "等待設定。"; }

        internal void Start(LoopPlan newPlan, DateTime wall, double mono)
        {
            string error = newPlan.Validate(wall);
            if (error != null) throw new ArgumentException(error);
            plan = newPlan.Snapshot();
            stage = 0; Completed = 0; first = true; Active = true; Paused = false;
            due = mono + (plan.FirstTime - wall).TotalSeconds;
            Status = "等待首次執行。";
        }

        internal void Stop(string reason)
        {
            Active = false; Paused = false;
            Status = reason + (stage == 0 ? "" : " 本輪可能留下草稿，重新啟動前請檢查。已發生的操作無法撤回。");
        }

        internal void TogglePause(DateTime wall, double mono)
        {
            if (!Active) return;
            if (plan.Deadline.HasValue && wall >= plan.Deadline.Value) { Stop("已到截止時間。"); return; }
            if (stage != 0) { Stop("已停止進行中的本輪。"); return; }
            if (Paused) { due = mono + pausedRemaining; first = false; Paused = false; Status = "已恢復等待。"; }
            else { pausedRemaining = Math.Max(0, Remaining(wall, mono)); Paused = true; Status = "已暫停；截止時間仍有效。"; }
        }

        internal double Remaining(DateTime wall, double mono)
        {
            return first && stage == 0 ? (plan.FirstTime - wall).TotalSeconds : due - mono;
        }

        internal void Tick(DateTime wall, double mono)
        {
            if (!Active) return;
            if (plan.Deadline.HasValue && wall >= plan.Deadline.Value) { Stop("已到截止時間。"); return; }
            if (Paused) return;
            double remaining = Remaining(wall, mono);
            if (remaining > 0) return;
            if (remaining < -5) { Stop("已錯過步驟超過 5 秒，排程停止，不補送。"); return; }
            try
            {
                if (stage == 0)
                {
                    actions.FocusInput();
                    first = false; stage = 1; due = completionClock() + plan.StepDelay.TotalSeconds;
                    Status = "已點輸入框，等待貼上。";
                }
                else if (stage == 1)
                {
                    actions.Paste(plan.PromptAt(Completed), plan.ReplaceDraft);
                    stage = 2; due = completionClock() + plan.StepDelay.TotalSeconds;
                    Status = "已貼上，等待點擊送出。";
                }
                else
                {
                    actions.Send();
                    Completed++; stage = 0;
                    if ((plan.MaxRounds.HasValue && Completed >= plan.MaxRounds.Value) || plan.PromptAt(Completed) == null)
                    { Stop("已完成設定的操作輪次；未驗證訊息是否送達。"); return; }
                    due = completionClock() + plan.Interval.TotalSeconds;
                    Status = "本輪已執行送出點擊；未驗證送達，等待下一輪。";
                }
            }
            catch (Exception ex) { Stop("執行失敗，已停止且不重試：" + ex.Message); }
        }
    }
}
