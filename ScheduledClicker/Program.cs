using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
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

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr windowHandle, int id, uint modifiers, uint virtualKey);

        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr windowHandle, int id);

        internal MainForm()
        {
            Text = "定時滑鼠點擊器";
            Font = new Font("Microsoft JhengHei UI", 10F);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            ClientSize = new Size(570, 590);
            BackColor = Color.FromArgb(247, 249, 252);

            BuildInterface();
            UpdateModeState();
            UpdateClock();

            clockTimer.Interval = 100;
            clockTimer.Tick += delegate { UpdateClock(); UpdateCountdownStatus(); };
            clockTimer.Start();

            captureTimer.Interval = 1000;
            captureTimer.Tick += CaptureTimerTick;

            schedule.Executed += delegate(ClickPlan plan) { PostToUi(delegate { SetCompleted(plan); }); };
            schedule.Failed += delegate(Exception ex) { PostToUi(delegate { SetFailed(ex); }); };
            FormClosing += delegate { closing = true; schedule.Dispose(); };
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
            var title = new Label { Text = "定時滑鼠點擊器", Font = new Font(Font.FontFamily, 18F, FontStyle.Bold), ForeColor = Color.FromArgb(28, 45, 70), AutoSize = true, Location = new Point(24, 20) };
            clockLabel.Font = new Font("Consolas", 16F, FontStyle.Bold);
            clockLabel.ForeColor = Color.FromArgb(32, 106, 196);
            clockLabel.AutoSize = true;
            clockLabel.Location = new Point(26, 62);
            Controls.Add(title);
            Controls.Add(clockLabel);

            var timeGroup = NewGroup("1. 選擇執行時間", 24, 108, 522, 172);
            absoluteMode.Text = "指定時間";
            absoluteMode.Checked = true;
            absoluteMode.Location = new Point(18, 31);
            absoluteMode.AutoSize = true;
            absoluteMode.CheckedChanged += delegate { UpdateModeState(); };
            targetTime.Format = DateTimePickerFormat.Custom;
            targetTime.CustomFormat = "yyyy/MM/dd  HH:mm:ss";
            targetTime.ShowUpDown = true;
            targetTime.Width = 235;
            targetTime.Location = new Point(145, 28);
            targetTime.Value = DateTime.Now.AddMinutes(1);

            delayMode.Text = "倒數延遲";
            delayMode.Location = new Point(18, 82);
            delayMode.AutoSize = true;
            delayHours.Minimum = 0; delayHours.Maximum = 168; delayHours.Width = 58; delayHours.Location = new Point(145, 79);
            delayMinutes.Minimum = 0; delayMinutes.Maximum = 59; delayMinutes.Width = 58; delayMinutes.Location = new Point(240, 79);
            delaySeconds.Minimum = 0; delaySeconds.Maximum = 59; delaySeconds.Value = 10; delaySeconds.Width = 58; delaySeconds.Location = new Point(335, 79);
            timeGroup.Controls.Add(absoluteMode); timeGroup.Controls.Add(targetTime); timeGroup.Controls.Add(delayMode);
            timeGroup.Controls.Add(delayHours); timeGroup.Controls.Add(NewLabel("時", 207, 84));
            timeGroup.Controls.Add(delayMinutes); timeGroup.Controls.Add(NewLabel("分", 302, 84));
            timeGroup.Controls.Add(delaySeconds); timeGroup.Controls.Add(NewLabel("秒", 397, 84));
            timeGroup.Controls.Add(NewLabel("倒數最短 1 秒，最長 168 小時。", 145, 119));

            var pointGroup = NewGroup("2. 選擇位置與點擊方式", 24, 294, 522, 133);
            captureButton.Text = "3 秒後擷取滑鼠位置";
            captureButton.Size = new Size(205, 39);
            captureButton.Location = new Point(18, 32);
            captureButton.Click += StartCapture;
            positionLabel.Text = "尚未選擇位置";
            positionLabel.AutoSize = true;
            positionLabel.ForeColor = Color.FromArgb(94, 101, 115);
            positionLabel.Location = new Point(240, 42);
            clickKind.DropDownStyle = ComboBoxStyle.DropDownList;
            clickKind.Items.Add("單擊");
            clickKind.Items.Add("雙擊");
            clickKind.SelectedIndex = 0;
            clickKind.Location = new Point(112, 86);
            clickKind.Width = 111;
            pointGroup.Controls.Add(captureButton); pointGroup.Controls.Add(positionLabel);
            pointGroup.Controls.Add(NewLabel("點擊方式", 18, 91)); pointGroup.Controls.Add(clickKind);

            armButton.Text = "啟動排程";
            armButton.Font = new Font(Font.FontFamily, 11F, FontStyle.Bold);
            armButton.BackColor = Color.FromArgb(42, 116, 214);
            armButton.ForeColor = Color.White;
            armButton.FlatStyle = FlatStyle.Flat;
            armButton.FlatAppearance.BorderSize = 0;
            armButton.Size = new Size(250, 48);
            armButton.Location = new Point(24, 447);
            armButton.Click += ArmSchedule;
            cancelButton.Text = "取消排程";
            cancelButton.Size = new Size(250, 48);
            cancelButton.Location = new Point(296, 447);
            cancelButton.Enabled = false;
            cancelButton.Click += delegate { CancelSchedule("排程已取消。", false); };
            Controls.Add(armButton); Controls.Add(cancelButton);

            statusLabel.Text = "等待設定。排程啟動後可按 F8 緊急停止。";
            statusLabel.AutoEllipsis = true;
            statusLabel.Size = new Size(522, 55);
            statusLabel.Location = new Point(24, 514);
            statusLabel.Padding = new Padding(12, 10, 12, 8);
            statusLabel.BackColor = Color.White;
            statusLabel.ForeColor = Color.FromArgb(57, 66, 82);
            Controls.Add(statusLabel);
        }

        private GroupBox NewGroup(string text, int x, int y, int width, int height)
        {
            var group = new GroupBox { Text = text, Location = new Point(x, y), Size = new Size(width, height), BackColor = Color.White };
            Controls.Add(group);
            return group;
        }

        private static Label NewLabel(string text, int x, int y)
        {
            return new Label { Text = text, AutoSize = true, Location = new Point(x, y), ForeColor = Color.FromArgb(75, 84, 99) };
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
            statusLabel.Text = "請在 3 秒內將滑鼠移到要點擊的位置…";
            WindowState = FormWindowState.Minimized;
            captureTimer.Start();
        }

        private void CaptureTimerTick(object sender, EventArgs e)
        {
            captureCountdown--;
            if (captureCountdown > 0)
            {
                statusLabel.Text = "請在 " + captureCountdown + " 秒內將滑鼠移到要點擊的位置…";
                return;
            }

            captureTimer.Stop();
            capturedPoint = Cursor.Position;
            positionLabel.Text = "X: " + capturedPoint.Value.X + "   Y: " + capturedPoint.Value.Y;
            positionLabel.ForeColor = Color.FromArgb(32, 106, 196);
            captureButton.Enabled = true;
            WindowState = FormWindowState.Normal;
            Activate();
            statusLabel.Text = "位置已擷取。確認時間後即可啟動排程。";
        }

        private void ArmSchedule(object sender, EventArgs e)
        {
            if (!capturedPoint.HasValue)
            {
                MessageBox.Show(this, "請先擷取要點擊的滑鼠位置。", "尚未選擇位置", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            DateTime now = DateTime.Now;
            DateTime runAt;
            if (absoluteMode.Checked)
            {
                runAt = targetTime.Value;
            }
            else
            {
                int totalSeconds = (int)(delayHours.Value * 3600 + delayMinutes.Value * 60 + delaySeconds.Value);
                if (totalSeconds < 1)
                {
                    MessageBox.Show(this, "倒數延遲至少要 1 秒。", "時間無效", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                runAt = now.AddSeconds(totalSeconds);
            }

            var kind = clickKind.SelectedIndex == 1 ? ClickKind.Double : ClickKind.Single;
            var plan = new ClickPlan(runAt, capturedPoint.Value, kind);
            string error = PlanValidator.Validate(plan, now, SystemInformation.VirtualScreen);
            if (error != null)
            {
                MessageBox.Show(this, error, "無法啟動", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string summary = string.Format("時間：{0:yyyy/MM/dd HH:mm:ss}\n位置：X {1}, Y {2}\n方式：{3}\n\n確定啟動嗎？", plan.TargetTime, plan.TargetPoint.X, plan.TargetPoint.Y, kind == ClickKind.Double ? "雙擊" : "單擊");
            if (MessageBox.Show(this, summary, "確認排程", MessageBoxButtons.OKCancel, MessageBoxIcon.Question) != DialogResult.OK) return;

            schedule.Arm(plan);
            hotkeyRegistered = RegisterHotKey(Handle, HotkeyId, 0, (uint)Keys.F8);
            armButton.Enabled = false;
            cancelButton.Enabled = true;
            SetInputsEnabled(false);
            statusLabel.ForeColor = Color.FromArgb(32, 106, 196);
            statusLabel.Tag = plan;
            UpdateCountdownStatus();
        }

        private void UpdateCountdownStatus()
        {
            var plan = statusLabel.Tag as ClickPlan;
            if (!schedule.IsArmed || plan == null) return;
            TimeSpan remaining = plan.TargetTime - DateTime.Now;
            if (remaining < TimeSpan.Zero) remaining = TimeSpan.Zero;
            string stopHint = hotkeyRegistered ? "按 F8 可停止。" : "F8 被占用，請用取消排程按鈕。";
            statusLabel.Text = string.Format("已排程：{0:HH:mm:ss} 執行，剩餘 {1:00}:{2:00}:{3:00}。{4}", plan.TargetTime, (int)remaining.TotalHours, remaining.Minutes, remaining.Seconds, stopHint);
        }

        private void CancelSchedule(string message, bool emergency)
        {
            CancelResult cancelResult = schedule.Cancel();
            ReleaseHotkey();
            if (cancelResult == CancelResult.Executing)
            {
                statusLabel.ForeColor = Color.FromArgb(190, 99, 35);
                statusLabel.Text = "點擊已開始執行，現在取消已來不及。";
                return;
            }
            statusLabel.Tag = null;
            armButton.Enabled = true;
            cancelButton.Enabled = false;
            SetInputsEnabled(true);
            statusLabel.ForeColor = emergency ? Color.FromArgb(190, 55, 55) : Color.FromArgb(57, 66, 82);
            statusLabel.Text = message;
        }

        private void SetCompleted(ClickPlan plan)
        {
            ReleaseHotkey();
            statusLabel.Tag = null;
            armButton.Enabled = true;
            cancelButton.Enabled = false;
            SetInputsEnabled(true);
            statusLabel.ForeColor = Color.FromArgb(32, 130, 83);
            statusLabel.Text = string.Format("已於 {0:HH:mm:ss.fff} 完成{1}。", DateTime.Now, plan.ClickKind == ClickKind.Double ? "雙擊" : "單擊");
        }

        private void SetFailed(Exception exception)
        {
            ReleaseHotkey();
            statusLabel.Tag = null;
            armButton.Enabled = true;
            cancelButton.Enabled = false;
            SetInputsEnabled(true);
            statusLabel.ForeColor = Color.FromArgb(190, 55, 55);
            statusLabel.Text = "執行失敗：" + exception.Message;
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
