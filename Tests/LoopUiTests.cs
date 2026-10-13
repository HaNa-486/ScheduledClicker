using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Reflection;
using System.Windows.Forms;
using ScheduledClicker;

internal static class LoopUiTests
{
    private static T Field<T>(object instance, string name) { return (T)instance.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(instance); }
    private static void Save(Form form, string path)
    {
        using (var bitmap = new Bitmap(form.Width, form.Height))
        { form.DrawToBitmap(bitmap, new Rectangle(Point.Empty, form.Size)); bitmap.Save(path, ImageFormat.Png); }
    }
    [STAThread] private static void Main(string[] args)
    {
        L.Select("zh");
        Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException);
        Application.EnableVisualStyles();
        using (var form = new LoopForm())
        using (var verifyClock = new Timer { Interval = 180 })
        {
            form.Opacity = 0; form.ShowInTaskbar = false;
            int visit = 0;
            string clockBefore = null;
            form.VisibleChanged += delegate
            {
                if (!form.Visible) return;
                try
                {
                    var mode = Field<ComboBox>(form, "mode"); var editor = Field<TextBox>(form, "editor");
                    var prompts = Field<List<string>>(form, "prompts");
                    if (visit == 0)
                    {
                        mode.SelectedIndex = 1;
                        Field<Button>(form, "add").PerformClick(); editor.Text = "第二輪：繼續\r\n保留進度 😀";
                        mode.SelectedIndex = 0; editor.Text = "第一輪提示";
                        if (prompts.Count != 2 || prompts[0] != "第一輪提示" || !prompts[1].Contains("第二輪")) throw new Exception("Prompt editing lost data");
                        mode.SelectedIndex = 1; Field<ListBox>(form, "entries").SelectedIndex = 1;
                    }
                    else
                    {
                        if (!editor.Text.Contains("第二輪") || prompts.Count != 2) throw new Exception("Navigation lost prompt settings");
                        if (Field<LoopEngine>(form, "engine").Active || Field<int>(form, "captureKind") != 0) throw new Exception("Navigation left active work");
                    }
                    clockBefore = Field<Label>(form, "clockLabel").Text;
                    verifyClock.Start();
                }
                catch (Exception ex) { Console.WriteLine("FAIL: " + ex.Message); Environment.ExitCode = 1; form.BeginInvoke(new Action(form.Close)); }
            };
            verifyClock.Tick += delegate
            {
                verifyClock.Stop();
                try
                {
                    var clock = Field<Label>(form, "clockLabel");
                    if (clock.Text == clockBefore || clock.Text.Length < 23) throw new Exception("Digital clock did not advance");
                    var settings = Field<FlowLayoutPanel>(form, "settings");
                    var back = Field<Button>(form, "back");
                    if (!back.Visible || !back.Parent.ClientRectangle.Contains(back.Bounds)) throw new Exception("Return button outside visible header");
                    settings.AutoScrollPosition = Point.Empty;
                    Save(form, args[0]);
                    settings.ScrollControlIntoView(settings.Controls[settings.Controls.Count - 1]);
                    if (!clock.Visible || clock.Parent == settings) throw new Exception("Clock scrolls with settings");
                    Save(form, args[0].Replace(".png", "-bottom.png"));
                    if (visit == 0)
                    {
                        Field<LoopEngine>(form, "engine").Start(new LoopPlan { FirstTime = DateTime.Now.AddMinutes(10), Interval = TimeSpan.FromMinutes(1), MaxRounds = 1, Prompts = new[] { "test" } }, DateTime.Now, 0);
                        typeof(LoopForm).GetMethod("RefreshStatus", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(form, null);
                        if (!Field<Button>(form, "back").Text.Contains("停止")) throw new Exception("Active return lacks stop label");
                    }
                    Field<Button>(form, "back").PerformClick();
                }
                catch (Exception ex) { Console.WriteLine("FAIL: " + ex.Message); Environment.ExitCode = 1; form.Close(); }
            };
            form.ShowDialog();
            if (Environment.ExitCode != 0) return;
            if (Field<LoopEngine>(form, "engine").Active) throw new Exception("Return did not cancel active loop");
            visit = 1;
            Field<FlowLayoutPanel>(form, "settings").AutoScrollPosition = Point.Empty;
            form.ShowDialog();
            if (Environment.ExitCode == 0) Console.WriteLine("PASS: prompt editing, live fixed clock, return cancels, reopen retains settings and timer, UI rendering");
        }
    }
}
