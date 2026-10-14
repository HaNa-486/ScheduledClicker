using System;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using ScheduledClicker;

internal static class LanguagePickerTests
{
    [DllImport("user32.dll")] private static extern IntPtr SendMessage(IntPtr window, int message, IntPtr wparam, IntPtr lparam);
    private static T Field<T>(object item, string name) { return (T)item.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(item); }
    private static void Check(bool condition, string message) { if (!condition) throw new Exception(message); }
    private static void Pump(int milliseconds)
    {
        var watch = Stopwatch.StartNew();
        while (watch.ElapsedMilliseconds < milliseconds) { Application.DoEvents(); Thread.Sleep(10); }
    }
    [STAThread] private static void Main()
    {
        try
        {
            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException);
            typeof(Program).GetMethod("EnableBestDpiAwareness", BindingFlags.Static | BindingFlags.NonPublic).Invoke(null, null);
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
            L.Select("zh");
            using (var shell = new MainForm())
            {
                shell.Opacity = 0; shell.ShowInTaskbar = false; shell.Show(); Pump(150);
                var picker = Field<ComboBox>(shell, "language");
                var clock = Field<Label>(shell, "clockLabel");
                var loop = Field<LoopForm>(shell, "loopForm");
                var editor = Field<TextBox>(loop, "editor"); editor.Text = "Keep this prompt 中文 😀";
                foreach (bool loopMode in new[] { false, true, false })
                {
                    Check(shell.SwitchMode(loopMode), "Mode switch failed"); Pump(150);
                    for (int index = 0; index < L.Codes.Length; index++)
                    {
                        picker.Focus();
                        // Exercise the native arrow click, not a direct SelectedIndex assignment.
                        IntPtr point = new IntPtr(((picker.Height / 2) << 16) | (picker.Width - 10));
                        SendMessage(picker.Handle, 0x201, new IntPtr(1), point);
                        SendMessage(picker.Handle, 0x202, IntPtr.Zero, point);
                        Check(picker.DroppedDown, "Language list did not open");
                        string before = clock.Text;
                        // A sibling relayout must not resize/close the native list either.
                        picker.Parent.PerformLayout(); picker.Parent.Parent.PerformLayout(); Pump(300);
                        Check(picker.DroppedDown, "Language list closed during clock/header layout: loop=" + loopMode + " index=" + index);
                        Check(clock.Text != before, "Clock stopped while list was open");
                        SendMessage(picker.Handle, 0x100, new IntPtr(0x24), IntPtr.Zero); // Home
                        for (int step = 0; step < index; step++) SendMessage(picker.Handle, 0x100, new IntPtr(0x28), IntPtr.Zero);
                        SendMessage(picker.Handle, 0x100, new IntPtr(13), IntPtr.Zero); Pump(30);
                        Check(L.Language == L.Codes[index] && picker.SelectedIndex == index, "Native language selection failed");
                        Check(Field<Button>(shell, "simpleModeButton").Text == L.T("簡單模式"), "Header translation failed");
                        Check(Field<Button>(shell, "armButton").Text == L.T("啟動排程"), "Simple translation failed");
                        Check(Field<Button>(loop, "start").Text == L.T("啟動循環"), "Loop translation failed");
                        Check(editor.Text == "Keep this prompt 中文 😀", "Prompt changed during selection");
                    }
                }
                shell.Close();
            }
            Console.WriteLine("PASS: 15 native language-list interactions across both modes; list survives clock/layout, clock advances, all five languages apply and prompt is retained.");
        }
        catch (Exception ex) { Console.WriteLine("FAIL: " + ex); Environment.ExitCode = 1; }
    }
}
