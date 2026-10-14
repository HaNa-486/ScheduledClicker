using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal sealed class LoopForm : UserControl
    {
        private readonly NativeLoopInput input = new NativeLoopInput();
        private readonly LoopEngine engine;
        private readonly Timer timer = new Timer { Interval = 50 };
        private readonly TableLayoutPanel settings = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 2, ColumnCount = 1, Padding = new Padding(0), Margin = new Padding(0) };
        private readonly DateTimePicker first = DatePicker(DateTime.Now.AddMinutes(1));
        private readonly DateTimePicker deadline = DatePicker(DateTime.Now.AddDays(1));
        private readonly NumericUpDown hours = Number(0, 8760, 5);
        private readonly NumericUpDown minutes = Number(0, 59, 10);
        private readonly NumericUpDown seconds = Number(0, 59, 0);
        private readonly NumericUpDown wait = Number(1, 10, 1);
        private readonly NumericUpDown count = Number(1, 10000, 3);
        private readonly CheckBox countBound = new CheckBox { Text = "最多輪次", Checked = true, AutoSize = true };
        private readonly CheckBox timeBound = new CheckBox { Text = "截止時間", AutoSize = true };
        private readonly CheckBox repeatLast = new CheckBox { Text = "序列用完後，重複最後一筆", AutoSize = true };
        private readonly CheckBox replace = new CheckBox { Text = "取代輸入框原有文字（預設保留並插入）", AutoSize = true };
        private readonly ComboBox mode = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 210 };
        private readonly ListBox entries = new ListBox { Width = 135, Height = 132 };
        private readonly TextBox editor = new TextBox { Multiline = true, AcceptsReturn = true, ScrollBars = ScrollBars.Vertical, Width = 445, Height = 132, MaxLength = 20000 };
        private readonly List<string> prompts = new List<string> { L.T("繼續") };
        private readonly Button add = Button("新增一輪");
        private readonly Button remove = Button("刪除此輪");
        private readonly Button captureInput = Button("擷取輸入框（3 秒）");
        private readonly Button captureSend = Button("擷取送出鈕（3 秒）");
        private readonly Label inputLabel = Label("尚未擷取");
        private readonly Label sendLabel = Label("尚未擷取");
        private readonly Button start = Button("啟動循環");
        private readonly Button trial = Button("試跑一輪");
        private readonly Button pause = Button("暫停");
        private readonly Button cancel = Button("取消 / 停止");
        private readonly Label status = new Label { Dock = DockStyle.Bottom, Height = 74, Padding = new Padding(12, 6, 12, 4), BackColor = Color.White };
        internal event Action BusyChanged;
        internal bool Busy { get { return engine.Active || captureKind != 0; } }
        private bool lastBusy;
        private readonly Label notice = Label("執行時保持喚醒、不鎖屏，目標視窗與聊天固定。\n使用剪貼簿貼上，會覆寫剪貼簿；不判斷 AI 狀態或送達結果。\n試跑會真的輸入並點送出。中途停止後請檢查草稿，避免重複。\n兩個停止條件同時勾選時，先達到者停止。關閉本視窗也會取消。");
        private readonly LocalizedView localized;
        private int captureKind;
        private double captureDue;
        private bool registered;
        private bool loading;
        private const int Hotkey = 0x4C50;
        [DllImport("user32.dll")] private static extern bool RegisterHotKey(IntPtr window, int id, uint modifiers, uint key);
        [DllImport("user32.dll")] private static extern bool UnregisterHotKey(IntPtr window, int id);
        private static double Mono { get { return Stopwatch.GetTimestamp() / (double)Stopwatch.Frequency; } }

        internal LoopForm()
        {
            engine = new LoopEngine(input, delegate { return Mono; });
            Dock = DockStyle.Fill; Font = new Font("Microsoft JhengHei UI", 10);
            BackColor = Ui.Background; Padding = new Padding(16, 0, 16, 8);
            Controls.Add(settings);
            var actions = Row(start, trial, pause, cancel); actions.Dock = DockStyle.Bottom; actions.Height = 42;
            Ui.Primary(start);
            notice.Tag = Ui.Role.Notice; status.Tag = Ui.Role.Surface;
            notice.AutoSize = false; notice.Dock = DockStyle.Bottom; notice.Padding = new Padding(10, 4, 10, 4); notice.BackColor = Ui.Notice;
            Controls.Add(notice); Controls.Add(actions); Controls.Add(status);
            settings.RowStyles.Add(new RowStyle(SizeType.Absolute, 200));
            settings.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            var top = Ui.Columns(60, 40);
            var timing = Ui.Card("首次時間與循環間隔");
            var positions = Ui.Card("位置擷取");
            top.Controls.Add(timing, 0, 0); top.Controls.Add(positions, 1, 0); settings.Controls.Add(top, 0, 0);
            var times = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 5, Padding = new Padding(8, 4, 8, 4) };
            times.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize)); times.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            foreach (int i in new int[5]) times.RowStyles.Add(new RowStyle(SizeType.Percent, 20));
            first.Width = deadline.Width = 248;
            hours.Width = minutes.Width = seconds.Width = 58;
            times.Controls.Add(Label("首次執行"), 0, 0); times.Controls.Add(first, 1, 0);
            times.Controls.Add(Label("每輪結束後等"), 0, 1); times.Controls.Add(Row(hours, Label("時"), minutes, Label("分"), seconds, Label("秒")), 1, 1);
            times.Controls.Add(Label("點擊／貼上之間等待"), 0, 2); times.Controls.Add(Row(wait, Label("秒（1–10）")), 1, 2);
            times.Controls.Add(countBound, 0, 3); times.Controls.Add(Row(count, Label("輪")), 1, 3);
            times.Controls.Add(timeBound, 0, 4); times.Controls.Add(deadline, 1, 4); timing.Controls.Add(times);
            var points = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 3, Padding = new Padding(10, 3, 10, 6) };
            points.RowStyles.Add(new RowStyle(SizeType.Absolute, 28)); points.RowStyles.Add(new RowStyle(SizeType.Percent, 50)); points.RowStyles.Add(new RowStyle(SizeType.Percent, 50));
            var hint = Label("請擷取同一視窗內的兩個位置"); hint.Dock = DockStyle.Fill; hint.AutoSize = false;
            points.Controls.Add(hint, 0, 0);
            var inputRow = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, Margin = new Padding(0) };
            inputRow.Controls.Add(captureInput); inputRow.Controls.Add(inputLabel);
            var sendRow = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, Margin = new Padding(0) };
            sendRow.Controls.Add(captureSend); sendRow.Controls.Add(sendLabel);
            points.Controls.Add(inputRow, 0, 1); points.Controls.Add(sendRow, 0, 2); positions.Controls.Add(points);
            var promptCard = Ui.Card("提示詞"); settings.Controls.Add(promptCard, 0, 1);
            var promptLayout = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 4, ColumnCount = 1, Padding = new Padding(8, 0, 8, 2) };
            promptLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 36)); promptLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            promptLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 25)); promptLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 25));
            mode.Items.AddRange(new object[] { "每輪相同", "依輪次設定" }); mode.SelectedIndex = 0;
            promptLayout.Controls.Add(Row(mode, add, remove), 0, 0);
            var editRow = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 1, Margin = new Padding(0) };
            editRow.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            editRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 140)); editRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            entries.Dock = editor.Dock = DockStyle.Fill; entries.IntegralHeight = false;
            editRow.Controls.Add(entries, 0, 0); editRow.Controls.Add(editor, 1, 0);
            promptLayout.Controls.Add(editRow, 0, 1); promptLayout.Controls.Add(repeatLast, 0, 2); promptLayout.Controls.Add(replace, 0, 3);
            promptCard.Controls.Add(promptLayout);
            entries.SelectedIndexChanged += delegate { LoadPrompt(); };
            editor.TextChanged += delegate { if (!loading && entries.SelectedIndex >= 0) prompts[entries.SelectedIndex] = editor.Text; };
            mode.SelectedIndexChanged += delegate { if (!loading) { entries.SelectedIndex = 0; UpdatePromptMode(); } };
            add.Click += delegate { prompts.Add(""); RefreshEntries(prompts.Count - 1); };
            remove.Click += delegate { if (prompts.Count > 1) { int i = entries.SelectedIndex; prompts.RemoveAt(i); RefreshEntries(Math.Min(i, prompts.Count - 1)); } };
            countBound.CheckedChanged += delegate { UpdatePromptMode(); };
            timeBound.CheckedChanged += delegate { UpdatePromptMode(); };
            captureInput.Click += delegate { BeginCapture(1); }; captureSend.Click += delegate { BeginCapture(2); };
            start.Click += delegate { Arm(false); }; trial.Click += delegate { Arm(true); };
            pause.Click += delegate { engine.TogglePause(DateTime.Now, Mono); RefreshStatus(); if (engine.Active && !engine.Paused) FindForm().WindowState = FormWindowState.Minimized; };
            cancel.Click += delegate { captureKind = 0; engine.Stop("已取消排程。"); RefreshStatus(); };
            timer.Tick += delegate { Tick(); }; timer.Start();
            localized = new LocalizedView(this, status, inputLabel, sendLabel, pause);
            L.Changed += LanguageChanged;
            Resize += delegate { LayoutNotice(); };
            RefreshEntries(0); LanguageChanged();
        }

        protected override void OnVisibleChanged(EventArgs e)
        {
            base.OnVisibleChanged(e);
            if (engine != null) { if (Visible) timer.Start(); else if (!Busy) timer.Stop(); RefreshStatus(); }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) { captureKind = 0; engine.Stop("程式已結束。"); L.Changed -= LanguageChanged; if (localized != null) localized.Dispose(); timer.Stop(); timer.Dispose(); ReleaseKey(); }
            base.Dispose(disposing);
        }

        private static NumericUpDown Number(int min, int max, int value) { return new NumericUpDown { Minimum = min, Maximum = max, Value = value, Width = 65 }; }
        private static DateTimePicker DatePicker(DateTime value) { return new DateTimePicker { Format = DateTimePickerFormat.Custom, CustomFormat = "yyyy/MM/dd HH:mm:ss", ShowUpDown = true, Width = 250, Value = value }; }
        private static Button Button(string text) { return Ui.Button(text); }
        private static Label Label(string text) { return Label(text, false); }
        private static Label Label(string text, bool bold) { return new Label { Text = text, AutoSize = true, Margin = new Padding(3, 4, 3, 2), Font = new Font("Microsoft JhengHei UI", bold ? 12 : 10, bold ? FontStyle.Bold : FontStyle.Regular) }; }
        private static FlowLayoutPanel Row(params Control[] controls)
        {
            var row = new FlowLayoutPanel { AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink, WrapContents = false, Margin = new Padding(0) };
            row.Controls.AddRange(controls); return row;
        }
        private void LayoutNotice()
        {
            int width = Math.Max(100, ClientSize.Width - Padding.Horizontal - notice.Padding.Horizontal);
            notice.Height = TextRenderer.MeasureText(notice.Text, notice.Font, new Size(width, Int32.MaxValue), TextFormatFlags.WordBreak | TextFormatFlags.TextBoxControl).Height + notice.Padding.Vertical + 4;
        }
        private void LanguageChanged()
        {
            loading = true;
            int selectedMode = mode.SelectedIndex;
            // Replace item captions in place: do not fire mode changes or rewrite prompt text.
            mode.Items[0] = L.T("每輪相同"); mode.Items[1] = L.T("依輪次設定");
            mode.SelectedIndex = selectedMode;
            loading = true;
            int selected = entries.SelectedIndex;
            for (int i = 0; i < entries.Items.Count; i++) entries.Items[i] = L.T("第 " + (i + 1) + " 輪");
            entries.SelectedIndex = selected; loading = false;
            if (input.Input == null) inputLabel.Text = L.T("尚未擷取");
            if (input.Submit == null) sendLabel.Text = L.T("尚未擷取");
            LayoutNotice(); RefreshStatus();
        }
        private void RefreshEntries(int selected)
        {
            loading = true; entries.Items.Clear();
            for (int i = 0; i < prompts.Count; i++) entries.Items.Add(L.T("第 " + (i + 1) + " 輪"));
            entries.SelectedIndex = selected; loading = false; LoadPrompt(); UpdatePromptMode();
        }
        private void LoadPrompt() { if (loading || entries.SelectedIndex < 0) return; loading = true; editor.Text = prompts[entries.SelectedIndex]; loading = false; }
        private void UpdatePromptMode()
        {
            bool sequence = mode.SelectedIndex == 1;
            entries.Enabled = sequence; add.Enabled = sequence && prompts.Count < 10000; remove.Enabled = sequence && prompts.Count > 1;
            repeatLast.Enabled = sequence; count.Enabled = countBound.Checked; deadline.Enabled = timeBound.Checked;
        }
        private void BeginCapture(int kind)
        {
            captureKind = kind; captureDue = Mono + 3; RefreshStatus(); FindForm().WindowState = FormWindowState.Minimized;
        }
        private void Tick()
        {
            if (captureKind != 0 && Mono >= captureDue)
            {
                try
                {
                    var target = LoopTarget.Capture(Cursor.Position);
                    if (target.Process == (uint)Process.GetCurrentProcess().Id) throw new InvalidOperationException("請擷取外部目標視窗。");
                    string text = "X " + target.Point.X + " / Y " + target.Point.Y;
                    if (captureKind == 1) { input.Input = target; inputLabel.Text = text; }
                    else { input.Submit = target; sendLabel.Text = text; }
                    engine.Stop("位置已擷取。");
                }
                catch (Exception ex) { engine.Stop(ex.Message); }
                captureKind = 0; FindForm().WindowState = FormWindowState.Normal; FindForm().Activate();
            }
            engine.Tick(DateTime.Now, Mono); RefreshStatus();
        }
        private void Arm(bool test)
        {
            try
            {
                ValidateChildren();
                var plan = new LoopPlan { FirstTime = test ? DateTime.Now.AddSeconds(5) : first.Value,
                    Interval = TimeSpan.FromSeconds((double)(hours.Value * 3600 + minutes.Value * 60 + seconds.Value)),
                    StepDelay = TimeSpan.FromSeconds((double)wait.Value), MaxRounds = test ? 1 : (countBound.Checked ? (int?)count.Value : null),
                    Deadline = test ? null : (timeBound.Checked ? (DateTime?)deadline.Value : null),
                    Prompts = prompts.ToArray(), Sequence = mode.SelectedIndex == 1, RepeatLast = repeatLast.Checked, ReplaceDraft = replace.Checked };
                input.Prepare();
                string error = plan.Validate(DateTime.Now); if (error != null) throw new InvalidOperationException(error);
                string bounds = (plan.MaxRounds.HasValue ? plan.MaxRounds + " 輪" : "不限輪數") + (plan.Deadline.HasValue ? "；截止 " + plan.Deadline.Value.ToString("yyyy/MM/dd HH:mm:ss") : "");
                string message = (test ? "試跑：確認後 5 秒執行一輪。" : "首次：" + plan.FirstTime.ToString("yyyy/MM/dd HH:mm:ss") + "\n間隔：" + plan.Interval + "（每輪結束後起算）\n停止：" + bounds)
                    + "\n提示詞：" + (plan.Sequence ? "依輪次設定（" + prompts.Count + " 筆）" + (plan.RepeatLast ? "，重複最後一筆" : "，用完即停") : "每輪相同")
                    + "\n輸入框：" + input.Input.Point + "；送出鈕：" + input.Submit.Point
                    + "\n\n將真的輸入並點擊送出，會覆寫剪貼簿。\n" + (plan.ReplaceDraft ? "會取代輸入框原有文字。" : "會在游標位置插入，請先檢查草稿。")
                    + "\n請保持目標視窗／聊天不變。未驗證 AI 狀態或送達。";
                if (LocalizedDialog.Show(FindForm(), message, "確認循環操作", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning) != DialogResult.OK) return;
                if (test) plan.FirstTime = DateTime.Now.AddSeconds(5);
                registered = RegisterHotKey(Handle, Hotkey, 0, (uint)Keys.F8);
                if (!registered) throw new InvalidOperationException("F8 已被占用，請先釋放快捷鍵後再啟動。");
                engine.Start(plan, DateTime.Now, Mono); RefreshStatus(); FindForm().WindowState = FormWindowState.Minimized;
            }
            catch (Exception ex) { ReleaseKey(); LocalizedDialog.Show(FindForm(), ex.Message, "無法啟動", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
        }
        private void RefreshStatus()
        {
            bool busy = engine.Active || captureKind != 0;
            settings.Enabled = !busy; start.Enabled = trial.Enabled = !busy; pause.Enabled = engine.Active; cancel.Enabled = busy;
            pause.Text = L.T(engine.Paused ? "恢復" : (engine.BetweenRounds ? "暫停" : "停止本輪"));
            string left = engine.Active && !engine.Paused ? "；下個步驟剩 " + Math.Max(0, Math.Ceiling(engine.Remaining(DateTime.Now, Mono))) + " 秒" : "";
            status.Text = captureKind != 0 ? "請把滑鼠移到目標位置，倒數 " + Math.Max(0, Math.Ceiling(captureDue - Mono)) + " 秒。" : "已執行送出點擊 " + engine.Completed + " 輪" + left + "\n" + engine.Status + (engine.Active ? " F8 可停止。" : "");
            status.Text = L.T(status.Text);
            if (!engine.Active) ReleaseKey();
            if (lastBusy != busy) { lastBusy = busy; if (BusyChanged != null) BusyChanged(); }
        }
        private void ReleaseKey() { if (registered) UnregisterHotKey(Handle, Hotkey); registered = false; }
        protected override void WndProc(ref Message message)
        {
            if (message.Msg == 0x312 && message.WParam.ToInt32() == Hotkey) { engine.Stop("已用 F8 緊急停止。"); RefreshStatus(); return; }
            base.WndProc(ref message);
        }
    }
}
