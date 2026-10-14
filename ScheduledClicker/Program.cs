using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal static class Program
    {
        [DllImport("user32.dll")]
        private static extern bool SetProcessDpiAwarenessContext(IntPtr dpiContext);

        [DllImport("user32.dll")]
        private static extern bool SetProcessDPIAware();

        [STAThread]
        private static void Main()
        {
            EnableBestDpiAwareness();
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }

        private static void EnableBestDpiAwareness()
        {
            try
            {
                if (SetProcessDpiAwarenessContext(new IntPtr(-4))) return;
            }
            catch (EntryPointNotFoundException) { }
            SetProcessDPIAware();
        }
    }

    internal sealed class MainForm : Form
    {
        private const int HotkeyId = 0x5343;
        private const int WmHotkey = 0x0312;
        private readonly ScheduleService schedule = new ScheduleService();
        private readonly Timer clockTimer = new Timer();
        private readonly Timer captureTimer = new Timer();
        private readonly Label clockLabel = new Label();
        private readonly Label positionLabel = new Label();
        private readonly Label statusLabel = new Label();
        private readonly DateTimePicker targetTime = new DateTimePicker();
        private readonly NumericUpDown delayHours = new NumericUpDown();
        private readonly NumericUpDown delayMinutes = new NumericUpDown();
        private readonly NumericUpDown delaySeconds = new NumericUpDown();
        private readonly RadioButton absoluteMode = new RadioButton();
        private readonly RadioButton delayMode = new RadioButton();
        private readonly ComboBox clickKind = new ComboBox();
        private readonly Button captureButton = new Button();
        private readonly Button armButton = new Button();
        private readonly Button cancelButton = new Button();
        private Point? capturedPoint;
        private int captureCountdown;
        private bool hotkeyRegistered;
        private bool closing;
        private readonly LoopForm loopForm = new LoopForm();
        private readonly Panel simpleContent = new Panel { Dock = DockStyle.Fill, Padding = new Padding(16, 0, 16, 8) };
        private readonly Button simpleModeButton = Ui.Button("簡單模式");
        private readonly Button loopModeButton = Ui.Button("循環模式");
        private readonly Label switchHint = new Label { AutoSize = true };
        private bool loopSelected;
        internal bool SwitchMode(bool loop)
        {
            if (loopSelected == loop) return true;
            if (schedule.IsArmed || schedule.IsExecuting || captureTimer.Enabled || loopForm.Busy) return false;
            loopSelected = loop;
            simpleContent.Visible = !loop; loopForm.Visible = loop;
            if (loop) loopForm.BringToFront(); else simpleContent.BringToFront();
            UpdateNavigation(); return true;
        }
        private void UpdateNavigation()
        {
            bool busy = schedule.IsArmed || schedule.IsExecuting || captureTimer.Enabled || loopForm.Busy;
            simpleModeButton.Enabled = !busy || !loopSelected; loopModeButton.Enabled = !busy || loopSelected;
            simpleModeButton.BackColor = !loopSelected ? Color.FromArgb(42, 116, 214) : Color.White;
            simpleModeButton.ForeColor = !loopSelected ? Color.White : ForeColor;
            loopModeButton.BackColor = loopSelected ? Color.FromArgb(42, 116, 214) : Color.White;
            loopModeButton.ForeColor = loopSelected ? Color.White : ForeColor;
            switchHint.Text = busy ? L.T("請先停止目前操作，再切換模式。") : "";
        }
        private LocalizedView localized;
        private readonly ComboBox language = L.Picker();
        private string statusSource = "等待設定。排程啟動後可按 F8 緊急停止。";

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr windowHandle, int id, uint modifiers, uint virtualKey);

        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr windowHandle, int id);

        internal MainForm()
        {
            Text = "定時滑鼠點擊器";
            Font = new Font("Microsoft JhengHei UI", 10F);
            StartPosition = FormStartPosition.CenterScreen;
            ClientSize = new Size(1040, 680);
            MinimumSize = Size;
            BackColor = Color.FromArgb(247, 249, 252);

            BuildInterface();
            localized = new LocalizedView(this, loopForm, clockLabel, positionLabel, statusLabel, language, switchHint);
            L.Changed += LanguageChanged; LanguageChanged();
            UpdateModeState();
            UpdateClock();

            clockTimer.Interval = 100;
            clockTimer.Tick += delegate { UpdateClock(); UpdateCountdownStatus(); UpdateNavigation(); };
            clockTimer.Start();

            captureTimer.Interval = 1000;
            captureTimer.Tick += CaptureTimerTick;

            schedule.Executed += delegate(ClickPlan plan) { PostToUi(delegate { SetCompleted(plan); }); };
            schedule.Failed += delegate(Exception ex) { PostToUi(delegate { SetFailed(ex); }); };
            FormClosing += delegate { closing = true; L.Changed -= LanguageChanged; localized.Dispose(); schedule.Dispose(); clockTimer.Dispose(); captureTimer.Dispose(); loopForm.Dispose(); };
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
        }

        protected override void OnHandleDestroyed(EventArgs e)
        {
            if (hotkeyRegistered) UnregisterHotKey(Handle, HotkeyId);
            base.OnHandleDestroyed(e);
        }

        protected override void WndProc(ref Message message)
        {
            if (message.Msg == WmHotkey && message.WParam.ToInt32() == HotkeyId)
            {
                CancelSchedule("已用 F8 緊急停止。", true);
                return;
            }
            base.WndProc(ref message);
        }

        private void BuildInterface()
        {
            Controls.Add(simpleContent); Controls.Add(loopForm); loopForm.Visible = false;
            loopForm.BusyChanged += UpdateNavigation;
            var header = new Panel { Dock = DockStyle.Top, Height = 80 };
            var caption = NewLabel("目前時間", 18, 9); header.Controls.Add(caption);
            clockLabel.Font = new Font("Consolas", 16F, FontStyle.Bold); clockLabel.ForeColor = Color.FromArgb(32, 106, 196);
            // Clock text changes every 100 ms; keep it from relaying out the header.
            clockLabel.AutoSize = false; clockLabel.SetBounds(18, 34, 335, 28); header.Controls.Add(clockLabel);
            simpleModeButton.AutoSize = loopModeButton.AutoSize = false;
            simpleModeButton.SetBounds(365, 16, 200, 36); loopModeButton.SetBounds(567, 16, 210, 36);
            simpleModeButton.Click += delegate { SwitchMode(false); }; loopModeButton.Click += delegate { SwitchMode(true); };
            header.Controls.Add(simpleModeButton); header.Controls.Add(loopModeButton);
            switchHint.Location = new Point(365, 55); switchHint.ForeColor = Color.FromArgb(140, 78, 15); header.Controls.Add(switchHint);
            var languageLabel = NewLabel("語言", 835, 9); languageLabel.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            // Anchor a host panel, not the native DropDownList: its actual height can differ
            // even from PreferredHeight. Reapplying cached anchor bounds closes its list.
            var languageHost = new Panel { Bounds = new Rectangle(835, 33, 185, 32), Anchor = AnchorStyles.Top | AnchorStyles.Right };
            language.Width = 185; languageHost.Controls.Add(language);
            header.Width = ClientSize.Width; header.Controls.Add(languageLabel); header.Controls.Add(languageHost); Controls.Add(header);

            var columns = Ui.Columns(60, 40); simpleContent.Controls.Add(columns);
            var timeGroup = Ui.Card("1. 選擇執行時間"); var pointGroup = Ui.Card("2. 選擇位置與點擊方式");
            columns.Controls.Add(timeGroup, 0, 0); columns.Controls.Add(pointGroup, 1, 0);
            absoluteMode.Text = "指定時間"; absoluteMode.Checked = true; absoluteMode.AutoSize = true; absoluteMode.Location = new Point(18, 36);
            absoluteMode.CheckedChanged += delegate { UpdateModeState(); };
            targetTime.Format = DateTimePickerFormat.Custom; targetTime.CustomFormat = "yyyy/MM/dd  HH:mm:ss"; targetTime.ShowUpDown = true;
            targetTime.SetBounds(210, 32, 250, 26); targetTime.Value = DateTime.Now.AddMinutes(1);
            delayMode.Text = "倒數延遲"; delayMode.AutoSize = true; delayMode.Location = new Point(18, 90);
            delayHours.Minimum = 0; delayHours.Maximum = 168; delayHours.SetBounds(210, 87, 58, 26);
            delayMinutes.Minimum = 0; delayMinutes.Maximum = 59; delayMinutes.SetBounds(328, 87, 58, 26);
            delaySeconds.Minimum = 0; delaySeconds.Maximum = 59; delaySeconds.Value = 10; delaySeconds.SetBounds(446, 87, 58, 26);
            timeGroup.Controls.AddRange(new Control[] { absoluteMode, targetTime, delayMode, delayHours, delayMinutes, delaySeconds,
                NewLabel("時", 274, 91), NewLabel("分", 392, 91), NewLabel("秒", 510, 91), NewLabel("倒數最短 1 秒，最長 168 小時。", 18, 142) });
            captureButton.Text = "3 秒後擷取滑鼠位置"; captureButton.SetBounds(16, 32, 340, 36); captureButton.Click += StartCapture;
            positionLabel.Text = "尚未選擇位置"; positionLabel.AutoSize = true; positionLabel.Location = new Point(18, 80);
            positionLabel.ForeColor = Color.FromArgb(32, 106, 196);
            clickKind.DropDownStyle = ComboBoxStyle.DropDownList; clickKind.Items.AddRange(new object[] { "單擊", "雙擊" }); clickKind.SelectedIndex = 0;
            clickKind.SetBounds(160, 120, 185, 28);
            pointGroup.Controls.AddRange(new Control[] { captureButton, positionLabel, NewLabel("點擊方式", 18, 125), clickKind });
            var note = new Label { Text = "在指定時間安全地執行一次滑鼠單擊或雙擊\n請保持目標視窗／聊天不變。未驗證 AI 狀態或送達。\n等待設定。排程啟動後可按 F8 緊急停止。", Dock = DockStyle.Bottom, Height = 84, Padding = new Padding(10, 4, 10, 4), BackColor = Ui.Notice };
            var actions = new FlowLayoutPanel { Dock = DockStyle.Bottom, Height = 42, WrapContents = false };
            armButton.Text = "啟動排程"; armButton.AutoSize = true; armButton.Padding = new Padding(12, 3, 12, 3); armButton.Height = 34;
            Ui.Primary(armButton); armButton.Click += ArmSchedule;
            cancelButton.Text = "取消排程"; cancelButton.AutoSize = true; cancelButton.Padding = new Padding(12, 3, 12, 3); cancelButton.Height = 34;
            cancelButton.Enabled = false; cancelButton.Click += delegate { CancelSchedule("排程已取消。", false); };
            actions.Controls.Add(armButton); actions.Controls.Add(cancelButton);
            SetStatus("等待設定。排程啟動後可按 F8 緊急停止。");
            statusLabel.Dock = DockStyle.Bottom; statusLabel.Height = 74; statusLabel.Padding = new Padding(12, 6, 12, 4); statusLabel.BackColor = Color.White;
            simpleContent.Controls.Add(note); simpleContent.Controls.Add(actions); simpleContent.Controls.Add(statusLabel);
            UpdateNavigation();
        }

        private static Label NewLabel(string text, int x, int y)
        {
            return new Label { Text = text, AutoSize = true, Location = new Point(x, y), ForeColor = Color.FromArgb(75, 84, 99) };
        }

        private void SetStatus(string source) { statusSource = source; statusLabel.Text = L.T(source); }
        private void LanguageChanged()
        {
            int selected = clickKind.SelectedIndex;
            clickKind.Items[0] = L.T("單擊"); clickKind.Items[1] = L.T("雙擊");
            clickKind.SelectedIndex = selected;
            if (!capturedPoint.HasValue) positionLabel.Text = L.T("尚未選擇位置");
            SetStatus(statusSource); UpdateNavigation();
        }

        private void UpdateClock()
        {
            clockLabel.Text = DateTime.Now.ToString("yyyy/MM/dd  HH:mm:ss.fff");
        }

        private void UpdateModeState()
        {
            targetTime.Enabled = absoluteMode.Checked;
            delayHours.Enabled = delayMode.Checked;
            delayMinutes.Enabled = delayMode.Checked;
            delaySeconds.Enabled = delayMode.Checked;
        }

        private void StartCapture(object sender, EventArgs e)
        {
            captureCountdown = 3;
            captureButton.Enabled = false;
            SetStatus("請在 3 秒內將滑鼠移到要點擊的位置…");
            WindowState = FormWindowState.Minimized;
            captureTimer.Start(); UpdateNavigation();
        }

        private void CaptureTimerTick(object sender, EventArgs e)
        {
            captureCountdown--;
            if (captureCountdown > 0)
            {
                SetStatus("請在 " + captureCountdown + " 秒內將滑鼠移到要點擊的位置…");
                return;
            }

            captureTimer.Stop();
            capturedPoint = Cursor.Position;
            positionLabel.Text = "X: " + capturedPoint.Value.X + "   Y: " + capturedPoint.Value.Y;
            positionLabel.ForeColor = Color.FromArgb(32, 106, 196);
            captureButton.Enabled = true;
            WindowState = FormWindowState.Normal;
            Activate();
            SetStatus("位置已擷取。確認時間後即可啟動排程。"); UpdateNavigation();
        }

        private void ArmSchedule(object sender, EventArgs e)
        {
            if (!capturedPoint.HasValue)
            {
                LocalizedDialog.Show(this, "請先擷取要點擊的滑鼠位置。", "尚未選擇位置", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            DateTime now = DateTime.Now;
            DateTime runAt;
            TimeSpan? requestedDelay = null;
            if (absoluteMode.Checked)
            {
                runAt = targetTime.Value;
            }
            else
            {
                int totalSeconds = (int)(delayHours.Value * 3600 + delayMinutes.Value * 60 + delaySeconds.Value);
                if (totalSeconds < 1)
                {
                    LocalizedDialog.Show(this, "倒數延遲至少要 1 秒。", "時間無效", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                requestedDelay = TimeSpan.FromSeconds(totalSeconds);
                runAt = now.Add(requestedDelay.Value);
            }

            var kind = clickKind.SelectedIndex == 1 ? ClickKind.Double : ClickKind.Single;
            var plan = new ClickPlan(runAt, capturedPoint.Value, kind);
            string error = PlanValidator.Validate(plan, now, SystemInformation.VirtualScreen);
            if (error != null)
            {
                LocalizedDialog.Show(this, error, "無法啟動", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string summary = string.Format("時間：{0:yyyy/MM/dd HH:mm:ss}\n位置：X {1}, Y {2}\n方式：{3}\n\n確定啟動嗎？", plan.TargetTime, plan.TargetPoint.X, plan.TargetPoint.Y, kind == ClickKind.Double ? "雙擊" : "單擊");
            if (LocalizedDialog.Show(this, summary, "確認排程", MessageBoxButtons.OKCancel, MessageBoxIcon.Question) != DialogResult.OK) return;

            DateTime confirmedAt = DateTime.Now;
            plan = requestedDelay.HasValue
                ? ClickPlan.FromDelay(confirmedAt, requestedDelay.Value, capturedPoint.Value, kind)
                : new ClickPlan(runAt, capturedPoint.Value, kind);
            error = PlanValidator.Validate(plan, confirmedAt, SystemInformation.VirtualScreen);
            if (error != null)
            {
                LocalizedDialog.Show(this, error, "無法啟動", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (loopSelected || loopForm.Busy) return;
            schedule.Arm(plan);
            hotkeyRegistered = RegisterHotKey(Handle, HotkeyId, 0, (uint)Keys.F8);
            armButton.Enabled = false;
            cancelButton.Enabled = true;
            SetInputsEnabled(false);
            statusLabel.ForeColor = Color.FromArgb(32, 106, 196);
            statusLabel.Tag = plan;
            UpdateCountdownStatus(); UpdateNavigation();
        }

        private void UpdateCountdownStatus()
        {
            var plan = statusLabel.Tag as ClickPlan;
            if (!schedule.IsArmed || plan == null) return;
            TimeSpan remaining = plan.RemainingNow();
            if (remaining < TimeSpan.Zero) remaining = TimeSpan.Zero;
            string stopHint = hotkeyRegistered ? "按 F8 可停止。" : "F8 被占用，請用取消排程按鈕。";
            SetStatus(string.Format("已排程：{0:HH:mm:ss} 執行，剩餘 {1:00}:{2:00}:{3:00}。{4}", plan.TargetTime, (int)remaining.TotalHours, remaining.Minutes, remaining.Seconds, stopHint));
        }

        private void CancelSchedule(string message, bool emergency)
        {
            CancelResult cancelResult = schedule.Cancel();
            ReleaseHotkey();
            if (cancelResult == CancelResult.Executing)
            {
                statusLabel.ForeColor = Color.FromArgb(190, 99, 35);
                SetStatus("點擊已開始執行，現在取消已來不及。");
                return;
            }
            statusLabel.Tag = null;
            armButton.Enabled = true;
            cancelButton.Enabled = false;
            SetInputsEnabled(true);
            statusLabel.ForeColor = emergency ? Color.FromArgb(190, 55, 55) : Color.FromArgb(57, 66, 82);
            SetStatus(message); UpdateNavigation();
        }

        private void SetCompleted(ClickPlan plan)
        {
            ReleaseHotkey();
            statusLabel.Tag = null;
            armButton.Enabled = true;
            cancelButton.Enabled = false;
            SetInputsEnabled(true);
            statusLabel.ForeColor = Color.FromArgb(32, 130, 83);
            SetStatus(string.Format("已於 {0:HH:mm:ss.fff} 完成{1}。", DateTime.Now, plan.ClickKind == ClickKind.Double ? "雙擊" : "單擊"));
        }

        private void SetFailed(Exception exception)
        {
            ReleaseHotkey();
            statusLabel.Tag = null;
            armButton.Enabled = true;
            cancelButton.Enabled = false;
            SetInputsEnabled(true);
            statusLabel.ForeColor = Color.FromArgb(190, 55, 55);
            SetStatus("執行失敗：" + exception.Message);
        }

        private void SetInputsEnabled(bool enabled)
        {
            absoluteMode.Enabled = enabled;
            delayMode.Enabled = enabled;
            captureButton.Enabled = enabled;
            clickKind.Enabled = enabled;
            if (enabled) UpdateModeState();
            else
            {
                targetTime.Enabled = false;
                delayHours.Enabled = false;
                delayMinutes.Enabled = false;
                delaySeconds.Enabled = false;
            }
        }

        private void ReleaseHotkey()
        {
            if (!hotkeyRegistered) return;
            UnregisterHotKey(Handle, HotkeyId);
            hotkeyRegistered = false;
        }

        private void PostToUi(Action action)
        {
            if (closing || IsDisposed || !IsHandleCreated) return;
            try
            {
                BeginInvoke(new Action(delegate
                {
                    if (!closing && !IsDisposed) action();
                }));
            }
            catch (InvalidOperationException) { }
        }
    }
}
