using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;
using ScheduledClicker;

internal static class AppearanceTests
{
    private static int checks;
    private static T Field<T>(object item, string name) { return (T)item.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(item); }
    private static void Check(bool condition, string message) { checks++; if (!condition) throw new Exception(message); }
    private static void Pump(int ms) { var t = Stopwatch.StartNew(); while (t.ElapsedMilliseconds < ms) { Application.DoEvents(); Thread.Sleep(10); } }
    private static void Save(Form form, string path) { using (var image = new Bitmap(form.Width, form.Height)) { form.DrawToBitmap(image, new Rectangle(Point.Empty, form.Size)); image.Save(path, ImageFormat.Png); } }
    private static double Component(byte value) { double n = value / 255.0; return n <= .04045 ? n / 12.92 : Math.Pow((n + .055) / 1.055, 2.4); }
    private static double Luminance(Color c) { return .2126 * Component(c.R) + .7152 * Component(c.G) + .0722 * Component(c.B); }
    private static double Contrast(Color a, Color b) { double x = Luminance(a), y = Luminance(b); return (Math.Max(x, y) + .05) / (Math.Min(x, y) + .05); }
    [STAThread] private static void Main(string[] args)
    {
        try
        {
            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException); Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
            Check(Ui.Dark == Ui.ReadSystemTheme(), "Startup did not use current system app theme");
            Check(Ui.ResolveTheme(0) && !Ui.ResolveTheme(1) && !Ui.ResolveTheme(null) && !Ui.ResolveTheme("bad"), "System theme mapping/fallback failed");
            using (var shell = new MainForm())
            {
                shell.Opacity = 0; shell.ShowInTaskbar = false; shell.Show(); Pump(100);
                var toggle = Field<Button>(shell, "themeButton"); var picker = Field<ComboBox>(shell, "language");
                var loop = Field<LoopForm>(shell, "loopForm"); var editor = Field<TextBox>(loop, "editor");
                editor.Text = "Unchanged prompt 中文 😀"; editor.Select(2, 4);
                var first = Field<DateTimeField>(loop, "first"); first.Value = DateTime.Now.AddHours(12); DateTime date = first.Value;
                IntPtr window = shell.Handle;
                foreach (string language in L.Codes)
                foreach (bool dark in new[] { false, true })
                {
                    L.Select(language);
                    if (Ui.Dark != dark) toggle.PerformClick(); Pump(50);
                    Check(Ui.Dark == dark && shell.BackColor == Ui.Background, "Theme button failed");
                    Check(toggle.Text == L.T(dark ? "切換為淺色模式" : "切換為深色模式"), "Theme caption not localized");
                    Check(((ModernButton)toggle).IconOnly && toggle.AccessibleName == toggle.Text && toggle.Width >= 32, "Theme icon missing accessible caption or hit area");
                    Check(Contrast(Ui.Text, Ui.Background) >= 4.5 && Contrast(Ui.Text, Ui.Surface) >= 4.5 && Contrast(Ui.Accent, Ui.Surface) >= 4.5, "Theme text contrast below 4.5:1");
                    var primary = Field<Button>(loop, "start");
                    Check(Contrast(primary.ForeColor, primary.FlatAppearance.MouseOverBackColor) >= 4.5 && Contrast(Ui.DisabledText, Ui.Surface) >= 4.5, "Hover/disabled text contrast too low");
                    var notice = Field<Label>(loop, "notice");
                    Check(Contrast(notice.ForeColor, notice.BackColor) >= 4.5, "Notice contrast too low");
                    foreach (bool loopMode in new[] { false, true })
                    {
                        Check(shell.SwitchMode(loopMode), "Mode switching failed"); Pump(100);
                        Check(shell.Handle == window && editor.Text == "Unchanged prompt 中文 😀" && editor.SelectionStart == 2 && editor.SelectionLength == 4 && first.Value == date, "Appearance/mode switch mutated settings");
                        Check(picker.Items.Count == 5 && picker.SelectedIndex == Array.IndexOf(L.Codes, language), "Language selection changed");
                        picker.Focus(); picker.DroppedDown = true; picker.Parent.Parent.PerformLayout(); Pump(250);
                        Check(picker.DroppedDown, "Language list closed after appearance/mode switch"); picker.DroppedDown = false;
                        Save(shell, Path.Combine(args[0], "theme-" + (dark ? "dark" : "light") + "-" + (loopMode ? "loop" : "simple") + "-" + language + ".png"));
                    }
                    using (var dialog = LocalizedDialog.Create("將真的輸入並點擊送出，會覆寫剪貼簿。", "確認循環操作", MessageBoxButtons.OKCancel))
                    {
                        dialog.Opacity = 0; dialog.Show(shell); Pump(20);
                        Check(dialog.BackColor == Ui.Background && Contrast(dialog.ForeColor, dialog.BackColor) >= 4.5, "Confirmation theme/contrast mismatch");
                        Save(dialog, Path.Combine(args[0], "theme-" + (dark ? "dark" : "light") + "-dialog-" + language + ".png")); dialog.Close();
                    }
                }
                var engine = Field<LoopEngine>(loop, "engine");
                engine.Start(new LoopPlan { FirstTime = DateTime.Now.AddHours(1), Interval = TimeSpan.FromMinutes(1), MaxRounds = 1, Prompts = new[] { editor.Text } }, DateTime.Now, Stopwatch.GetTimestamp() / (double)Stopwatch.Frequency);
                toggle.PerformClick(); toggle.PerformClick();
                Check(engine.Active && engine.Completed == 0 && editor.Text == "Unchanged prompt 中文 😀", "Appearance change affected active plan");
                shell.Close();
            }
            Console.WriteLine("PASS: " + checks + " appearance/startup/contrast/state checks; both modes and dialogs rendered in two themes and five languages.");
        }
        catch (Exception ex) { Console.WriteLine("FAIL: " + ex); Environment.ExitCode = 1; }
    }
}
