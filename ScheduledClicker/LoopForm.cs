using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal sealed class LoopForm : Form
    {
        private readonly NativeLoopInput input = new NativeLoopInput();
        private readonly LoopEngine engine;
        private readonly Timer timer = new Timer { Interval = 50 };
        private readonly FlowLayoutPanel settings = new FlowLayoutPanel { Dock = DockStyle.Fill, AutoScroll = true, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(16) };
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
        private readonly Button back = Button("返回簡單模式");
        private readonly Label clockLabel = new Label { AutoSize = true, Font = new Font("Consolas", 16F, FontStyle.Bold), ForeColor = Color.FromArgb(32, 106, 196), Location = new Point(16, 28) };
        private readonly Label status = new Label { Dock = DockStyle.Bottom, Height = 85, Padding = new Padding(16, 8, 16, 4), BackColor = Color.White };
        private readonly ComboBox language = L.Picker();
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
            Text = "循環輸入與點擊"; Font = new Font("Microsoft JhengHei UI", 10);
            ClientSize = new Size(800, 800); MinimumSize = new Size(800, 660); StartPosition = FormStartPosition.CenterParent;
            Controls.Add(settings);
            var actions = Row(start, trial, pause, cancel); actions.Dock = DockStyle.Bottom; actions.Height = 44; actions.Padding = new Padding(12, 0, 0, 0);
            notice.AutoSize = false; notice.Dock = DockStyle.Bottom; notice.Padding = new Padding(16, 8, 16, 6); notice.BackColor = Color.FromArgb(255, 249, 230);
            Controls.Add(notice); Controls.Add(actions); Controls.Add(status);
            var header = new Panel { Dock = DockStyle.Top, Height = 100, Width = ClientSize.Width };
            var caption = Label("目前時間"); caption.Location = new Point(16, 3);
            back.AutoSize = false; back.Size = new Size(280, 36); back.Location = new Point(504, 12); back.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            var languageCaption = Label("語言"); languageCaption.Location = new Point(16, 61);
            language.Location = new Point(125, 64);
            header.Controls.Add(languageCaption); header.Controls.Add(language);
            header.Controls.Add(caption); header.Controls.Add(clockLabel); header.Controls.Add(back); Controls.Add(header);
            back.Click += delegate { Close(); };
            settings.Controls.Add(Label("首次時間與循環間隔", true));
            settings.Controls.Add(Row(Label("首次執行"), first));
            settings.Controls.Add(Row(Label("每輪結束後等"), hours, Label("時"), minutes, Label("分"), seconds, Label("秒")));
            settings.Controls.Add(Row(Label("點擊／貼上之間等待"), wait, Label("秒（1–10）")));
            settings.Controls.Add(Row(countBound, count, Label("輪")));
            settings.Controls.Add(Row(timeBound, deadline));
            settings.Controls.Add(Label("提示詞", true));
            mode.Items.AddRange(new object[] { "每輪相同", "依輪次設定" }); mode.SelectedIndex = 0;
            settings.Controls.Add(Row(mode, add, remove));
            settings.Controls.Add(Row(entries, editor));
            settings.Controls.Add(repeatLast); settings.Controls.Add(replace);
            settings.Controls.Add(Label("位置：請擷取同一視窗內的兩個位置", true));
            settings.Controls.Add(Row(captureInput, inputLabel));
            settings.Controls.Add(Row(captureSend, sendLabel));
            settings.Controls.Add(new Panel { Width = 10, Height = 20 });
            entries.SelectedIndexChanged += delegate { LoadPrompt(); };
            editor.TextChanged += delegate { if (!loading && entries.SelectedIndex >= 0) prompts[entries.SelectedIndex] = editor.Text; };
            mode.SelectedIndexChanged += delegate { if (!loading) { entries.SelectedIndex = 0; UpdatePromptMode(); } };
            add.Click += delegate { prompts.Add(""); RefreshEntries(prompts.Count - 1); };
            remove.Click += delegate { if (prompts.Count > 1) { int i = entries.SelectedIndex; prompts.RemoveAt(i); RefreshEntries(Math.Min(i, prompts.Count - 1)); } };
            countBound.CheckedChanged += delegate { UpdatePromptMode(); };
            timeBound.CheckedChanged += delegate { UpdatePromptMode(); };
            captureInput.Click += delegate { BeginCapture(1); }; captureSend.Click += delegate { BeginCapture(2); };
            start.Click += delegate { Arm(false); }; trial.Click += delegate { Arm(true); };
            pause.Click += delegate { engine.TogglePause(DateTime.Now, Mono); RefreshStatus(); if (engine.Active && !engine.Paused) WindowState = FormWindowState.Minimized; };
            cancel.Click += delegate { captureKind = 0; engine.Stop("已取消排程。"); RefreshStatus(); };
            timer.Tick += delegate { Tick(); }; timer.Start();
            FormClosed += delegate { captureKind = 0; timer.Stop(); engine.Stop("已返回簡單模式；循環已停止。"); ReleaseKey(); };
            localized = new LocalizedView(this, status, clockLabel, inputLabel, sendLabel, back, pause, language);
            L.Changed += LanguageChanged;
            Resize += delegate { LayoutNotice(); };
            RefreshEntries(0); LanguageChanged();
        }

        protected override void OnVisibleChanged(EventArgs e)
        {
            base.OnVisibleChanged(e);
            if (Visible) { timer.Start(); RefreshStatus(); }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) { L.Changed -= LanguageChanged; if (localized != null) localized.Dispose(); timer.Stop(); timer.Dispose(); ReleaseKey(); }
            base.Dispose(disposing);
        }

        private static NumericUpDown Number(int min, int max, int value) { return new NumericUpDown { Minimum = min, Maximum = max, Value = value, Width = 65 }; }
        private static DateTimePicker DatePicker(DateTime value) { return new DateTimePicker { Format = DateTimePickerFormat.Custom, CustomFormat = "yyyy/MM/dd HH:mm:ss", ShowUpDown = true, Width = 250, Value = value }; }
        private static Button Button(string text) { return new Button { Text = text, AutoSize = true, Height = 34, Padding = new Padding(5, 2, 5, 2) }; }
        private static Label Label(string text) { return Label(text, false); }
        private static Label Label(string text, bool bold) { return new Label { Text = text, AutoSize = true, Margin = new Padding(3, 8, 3, 6), Font = new Font("Microsoft JhengHei UI", bold ? 12 : 10, bold ? FontStyle.Bold : FontStyle.Regular) }; }
        private static FlowLayoutPanel Row(params Control[] controls)
        {
            var row = new FlowLayoutPanel { AutoSize = true, WrapContents = false, Margin = new Padding(0, 3, 0, 3) };
            row.Controls.AddRange(controls); return row;
        }
        private void LayoutNotice()
        {
            int width = Math.Max(100, ClientSize.Width - notice.Padding.Horizontal);
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
            captureKind = kind; captureDue = Mono + 3; RefreshStatus(); WindowState = FormWindowState.Minimized;
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
                captureKind = 0; WindowState = FormWindowState.Normal; Activate();
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
                if (LocalizedDialog.Show(this, message, "確認循環操作", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning) != DialogResult.OK) return;
                if (test) plan.FirstTime = DateTime.Now.AddSeconds(5);
                registered = RegisterHotKey(Handle, Hotkey, 0, (uint)Keys.F8);
                if (!registered) throw new InvalidOperationException("F8 已被占用，請先釋放快捷鍵後再啟動。");
                engine.Start(plan, DateTime.Now, Mono); RefreshStatus(); WindowState = FormWindowState.Minimized;
            }
            catch (Exception ex) { ReleaseKey(); LocalizedDialog.Show(this, ex.Message, "無法啟動", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
        }
        private void RefreshStatus()
        {
            clockLabel.Text = DateTime.Now.ToString("yyyy/MM/dd  HH:mm:ss.fff");
            bool busy = engine.Active || captureKind != 0;
            back.Text = L.T(busy ? "停止並返回簡單模式" : "返回簡單模式");
            settings.Enabled = !busy; start.Enabled = trial.Enabled = !busy; pause.Enabled = engine.Active; cancel.Enabled = busy;
            pause.Text = L.T(engine.Paused ? "恢復" : (engine.BetweenRounds ? "暫停" : "停止本輪"));
            string left = engine.Active && !engine.Paused ? "；下個步驟剩 " + Math.Max(0, Math.Ceiling(engine.Remaining(DateTime.Now, Mono))) + " 秒" : "";
            status.Text = captureKind != 0 ? "請把滑鼠移到目標位置，倒數 " + Math.Max(0, Math.Ceiling(captureDue - Mono)) + " 秒。" : "已執行送出點擊 " + engine.Completed + " 輪" + left + "\n" + engine.Status + (engine.Active ? " F8 可停止。" : "");
            status.Text = L.T(status.Text);
            if (!engine.Active) ReleaseKey();
        }
        private void ReleaseKey() { if (registered) UnregisterHotKey(Handle, Hotkey); registered = false; }
        protected override void WndProc(ref Message message)
        {
            if (message.Msg == 0x312 && message.WParam.ToInt32() == Hotkey) { engine.Stop("已用 F8 緊急停止。"); RefreshStatus(); return; }
            base.WndProc(ref message);
        }
    }
}
