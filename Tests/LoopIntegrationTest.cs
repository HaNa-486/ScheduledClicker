using System;
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;
using ScheduledClicker;

internal sealed class LoopIntegrationTest : Form
{
    private readonly TextBox editor = new TextBox { Multiline = true, Location = new Point(20, 20), Size = new Size(430, 120) };
    private readonly Button send = new Button { Text = "Disposable local test — send", Location = new Point(20, 160), Size = new Size(430, 50) };
    private readonly Timer timer = new Timer { Interval = 50 };
    private readonly NativeLoopInput native = new NativeLoopInput();
    private readonly LoopEngine engine;
    private readonly string[] prompts = { "中文第一輪\r\nline 2 😀", "第二輪 independent" };
    private double expires;
    private int received;
    private IDataObject clipboard;
    private static double Mono { get { return Stopwatch.GetTimestamp() / (double)Stopwatch.Frequency; } }
    [STAThread] private static void Main() { Application.EnableVisualStyles(); Application.Run(new LoopIntegrationTest()); }
    private LoopIntegrationTest()
    {
        Text = "ScheduledClicker disposable input test"; ClientSize = new Size(470, 235); StartPosition = FormStartPosition.CenterScreen; TopMost = true;
        engine = new LoopEngine(native, delegate { return Mono; }); Controls.Add(editor); Controls.Add(send);
        send.Click += delegate
        {
            if (received >= prompts.Length || editor.Text != prompts[received]) { Finish(false, "received text differs from configured prompt"); return; }
            received++; editor.Text = "draft to replace";
            if (received == 2) Finish(true, "native input, multiline Unicode, replace draft, send and second round reached disposable target");
        };
        Shown += delegate
        {
            try
            {
                clipboard = Clipboard.GetDataObject();
                editor.Text = "original draft";
                native.Input = LoopTarget.Capture(editor.PointToScreen(new Point(40, 40)));
                native.Submit = LoopTarget.Capture(send.PointToScreen(new Point(40, 25)));
                native.Prepare();
                engine.Start(new LoopPlan { FirstTime = DateTime.Now.AddSeconds(1), Interval = TimeSpan.FromSeconds(10), MaxRounds = 2, Prompts = prompts, Sequence = true, ReplaceDraft = true }, DateTime.Now, Mono);
                expires = Mono + 22; timer.Start();
            }
            catch (Exception ex) { Finish(false, ex.Message); }
        };
        timer.Tick += delegate
        {
            engine.Tick(DateTime.Now, Mono);
            if (!engine.Active && engine.Completed < 2) Finish(false, engine.Status);
            else if (Mono > expires) Finish(false, "timed out without confirmed local delivery");
        };
        FormClosed += delegate { timer.Stop(); engine.Stop("closed"); if (clipboard != null) { try { Clipboard.SetDataObject(clipboard, true); } catch { } } };
    }
    private void Finish(bool passed, string text) { timer.Stop(); Console.WriteLine((passed ? "PASS: " : "FAIL: ") + text); Environment.ExitCode = passed ? 0 : 1; Close(); }
}
