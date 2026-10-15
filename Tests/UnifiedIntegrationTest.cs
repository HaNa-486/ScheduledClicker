using System;
using System.Diagnostics;
using System.Drawing;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using ScheduledClicker;

// Runs only on request against its own disposable local input/send controls.
internal sealed class UnifiedIntegrationTest : Form
{
    [DllImport("user32.dll")] private static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr wparam, IntPtr lparam);
    private readonly TextBox editor = new TextBox { Multiline = true, Location = new Point(20, 20), Size = new Size(430, 120), Text = "draft to replace" };
    private readonly Button send = new Button { Text = "Disposable local test: send", Location = new Point(20, 160), Size = new Size(430, 50) };
    private readonly Timer timer = new Timer { Interval = 50 };
    private readonly MainForm shell = new MainForm();
    private LoopForm loop;
    private LoopEngine engine;
    private double expires;
    private int phase;
    private bool received;
    private IDataObject clipboard;
    private const string Prompt = "local fixture 中文\r\nsecond line 😀";
    private static double Mono { get { return Stopwatch.GetTimestamp() / (double)Stopwatch.Frequency; } }
    private static T Field<T>(object item, string name) { return (T)item.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(item); }
    private static void Check(bool value, string message) { if (!value) throw new Exception(message); }
    [STAThread] private static void Main()
    {
        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException); Application.EnableVisualStyles();
        try { Application.Run(new UnifiedIntegrationTest()); }
        catch (Exception ex) { Console.WriteLine("FAIL: " + ex); Environment.ExitCode = 1; }
    }
    private UnifiedIntegrationTest()
    {
        L.Select("en"); Text = "ScheduledClicker disposable unified-window test";
        ClientSize = new Size(470, 235); StartPosition = FormStartPosition.CenterScreen; TopMost = true;
        Controls.Add(editor); Controls.Add(send);
        send.Click += delegate { Check(editor.Text == Prompt, "Native prompt differs"); received = true; };
        Shown += delegate
        {
            try
            {
                clipboard = Clipboard.GetDataObject();
                shell.Opacity = 0; shell.ShowInTaskbar = false; shell.Show(); shell.SwitchMode(true);
                loop = Field<LoopForm>(shell, "loopForm"); engine = Field<LoopEngine>(loop, "engine");
                var native = Field<NativeLoopInput>(loop, "input");
                // Inject only this fixture's coordinates; no user application is targeted.
                Activate(); native.Input = LoopTarget.Capture(editor.PointToScreen(new Point(40, 40)));
                native.Submit = LoopTarget.Capture(send.PointToScreen(new Point(40, 25)));
                Field<TextBox>(loop, "editor").Text = Prompt; Field<CheckBox>(loop, "replace").Checked = true;
                ArmTrial();
                Check(shell.WindowState == FormWindowState.Minimized && engine.Active && Field<bool>(loop, "registered"), "Shared host did not minimize/register F8");
                Check(!shell.SwitchMode(false), "Active host allowed mode switch");
                Check(PostMessage(loop.Handle, 0x312, new IntPtr(0x4C50), IntPtr.Zero), "Could not queue F8 message");
                expires = Mono + 25; timer.Start();
            }
            catch (Exception ex) { Finish(false, ex.Message); }
        };
        timer.Tick += delegate
        {
            try
            {
                if (Mono > expires) { Finish(false, "Timed out: " + engine.Status); return; }
                if (phase == 0)
                {
                    Check(!engine.Active && !Field<bool>(loop, "registered") && !received, "Queued F8 did not cancel before input");
                    timer.Stop(); shell.WindowState = FormWindowState.Normal; ArmTrial(); Activate(); phase = 1; timer.Start();
                }
                else if (phase == 1 && !engine.Active)
                {
                    Check(received && engine.Completed == 1, "Trial did not reach disposable target: " + engine.Status);
                    timer.Stop(); phase = 2; shell.WindowState = FormWindowState.Normal;
                    Check(shell.SwitchMode(false) && shell.SwitchMode(true), "Modes unavailable after completion");
                    ArmTrial(); shell.Close();
                    Check(!engine.Active && loop.IsDisposed, "Close left active loop");
                    Finish(true, "unified host trial, native Unicode paste/replace/send, hotkey registration/queued F8 cancellation, mode reuse and close cancellation");
                }
            }
            catch (Exception ex) { Finish(false, ex.Message); }
        };
        FormClosed += delegate { timer.Stop(); shell.Dispose(); if (clipboard != null) { try { Clipboard.SetDataObject(clipboard, true); } catch { } } };
    }
    private void ArmTrial()
    {
        string unexpected = null;
        using (var confirm = new Timer { Interval = 50 })
        {
            confirm.Tick += delegate
            {
                Form dialog = null;
                foreach (Form open in Application.OpenForms) if (open != shell && open != this) { dialog = open; break; }
                if (dialog == null) return;
                confirm.Stop();
                if (dialog.Text != L.T("確認循環操作")) unexpected = dialog.Text;
                dialog.DialogResult = unexpected == null ? DialogResult.OK : DialogResult.Cancel;
            };
            confirm.Start();
            typeof(LoopForm).GetMethod("Arm", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(loop, new object[] { true });
        }
        Check(unexpected == null && engine.Active, "Could not arm fixture trial: " + unexpected);
    }
    private void Finish(bool passed, string message)
    {
        timer.Stop(); Console.WriteLine((passed ? "PASS: " : "FAIL: ") + message); Environment.ExitCode = passed ? 0 : 1; Close();
    }
}
