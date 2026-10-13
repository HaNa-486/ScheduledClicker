using System;
using System.Collections.Generic;
using System.Drawing;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;
using ScheduledClicker;

internal static class LoopUiTests
{
    private static T Field<T>(object item, string name) { return (T)item.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(item); }
    private static void Set(object item, string name, object value) { item.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).SetValue(item, value); }
    private static void Call(object item, string name, params object[] values) { item.GetType().GetMethod(name, BindingFlags.Instance | BindingFlags.NonPublic).Invoke(item, values); }
    private static void Check(bool condition, string message) { if (!condition) throw new Exception(message); }
    [STAThread] private static void Main(string[] args)
    {
        try
        {
            L.Select("zh"); Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException); Application.EnableVisualStyles();
            using (var shell = new MainForm())
            {
                shell.Opacity = 0; shell.ShowInTaskbar = false; shell.Show(); Application.DoEvents();
                IntPtr handle = shell.Handle; Rectangle bounds = shell.Bounds;
                var loop = Field<LoopForm>(shell, "loopForm"); var engine = Field<LoopEngine>(loop, "engine");
                Check(Application.OpenForms.Count == 1, "More than one top-level window");
                Check(shell.SwitchMode(true), "Cannot enter loop"); Application.DoEvents();
                var editor = Field<TextBox>(loop, "editor"); var mode = Field<ComboBox>(loop, "mode");
                mode.SelectedIndex = 1; Field<Button>(loop, "add").PerformClick(); editor.Text = "第二輪：繼續\r\n保留進度 😀";
                mode.SelectedIndex = 0; editor.Text = "第一輪提示"; mode.SelectedIndex = 1; Field<ListBox>(loop, "entries").SelectedIndex = 1;
                Check(Field<List<string>>(loop, "prompts").Count == 2 && editor.Text.Contains("第二輪"), "Prompt sequence lost");
                editor.Select(2, 3);
                for (int i = 0; i < 3; i++)
                {
                    Check(shell.SwitchMode(false) && shell.SwitchMode(true), "Mode switching failed");
                    Check(shell.Handle == handle && shell.Bounds == bounds && Application.OpenForms.Count == 1, "Mode switch changed window");
                    Check(editor.Text.Contains("第二輪") && editor.SelectionStart == 2 && editor.SelectionLength == 3, "Mode switch lost editor state");
                }
                string before = Field<Label>(shell, "clockLabel").Text;
                Thread.Sleep(150); Application.DoEvents(); Check(Field<Label>(shell, "clockLabel").Text != before, "Shared clock stopped");
                engine.Start(new LoopPlan { FirstTime = DateTime.Now.AddHours(1), Interval = TimeSpan.FromMinutes(1), MaxRounds = 1, Prompts = new[] { "fixture" } }, DateTime.Now, 0);
                Application.DoEvents(); Check(!shell.SwitchMode(false) && engine.Active, "Switch hid or cancelled active work");
                Message hotkey = Message.Create(loop.Handle, 0x312, new IntPtr(0x4C50), IntPtr.Zero);
                Call(loop, "WndProc", hotkey); Check(!engine.Active, "Embedded loop F8 route failed");
                Set(loop, "captureKind", 1); Set(loop, "captureDue", double.MaxValue);
                Check(!shell.SwitchMode(false), "Switch allowed during capture"); Field<Button>(loop, "cancel").Enabled = true; Field<Button>(loop, "cancel").PerformClick();
                Check(shell.SwitchMode(false), "Switch unavailable after cancelling capture");
                var service = Field<ScheduleService>(shell, "schedule");
                service.Arm(new ClickPlan(DateTime.Now.AddHours(1), new Point(1, 1), ClickKind.Single));
                Check(!shell.SwitchMode(true), "Switch allowed during simple schedule"); Call(shell, "CancelSchedule", "排程已取消。", false);
                Check(shell.SwitchMode(true), "Cannot switch after cancelling simple schedule");
                engine.Start(new LoopPlan { FirstTime = DateTime.Now.AddHours(1), Interval = TimeSpan.FromMinutes(1), MaxRounds = 1, Prompts = new[] { "fixture" } }, DateTime.Now, 0);
                shell.Close(); Check(!engine.Active && loop.IsDisposed, "Closing shell left loop alive");
            }
            Console.WriteLine("PASS: one window, retained mode state, shared clock, busy/capture guards, embedded F8 routing and close cancellation.");
        }
        catch (Exception ex) { Console.WriteLine("FAIL: " + ex); Environment.ExitCode = 1; }
    }
}
