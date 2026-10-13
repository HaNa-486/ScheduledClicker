using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using ScheduledClicker;

internal static class LocalizationTests
{
    private static int checks;
    private static T Field<T>(object item, string name) { return (T)item.GetType().GetField(name, BindingFlags.Instance | BindingFlags.NonPublic).GetValue(item); }
    private static void Check(bool success, string reason) { checks++; if (!success) throw new Exception(reason); }
    private static void Save(Form form, string path) { using (var bitmap = new Bitmap(form.Width, form.Height)) { form.DrawToBitmap(bitmap, new Rectangle(Point.Empty, form.Size)); bitmap.Save(path, ImageFormat.Png); } }
    private static void EnglishText(Control root, params Control[] excluded)
    {
        if (Array.IndexOf(excluded, root) >= 0) return;
        if (root is Label || root is ButtonBase || root is GroupBox || root is Form)
            Check(!Regex.IsMatch(root.Text, @"\p{IsCJKUnifiedIdeographs}"), "Untranslated UI: " + root.Text);
        foreach (Control child in root.Controls) EnglishText(child, excluded);
    }
    [STAThread] private static void Main(string[] args)
    {
        try
        {
            if (args.Length == 2 && args[0] == "--locale")
            {
                System.Threading.Thread.CurrentThread.CurrentUICulture = CultureInfo.GetCultureInfo(args[1]);
                Console.WriteLine(L.Language); return;
            }
            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException);
            Application.EnableVisualStyles();
            foreach (string locale in new[] { "zh-CN", "zh-TW", "ja-JP", "ko-KR", "de-DE", "en-US", "fr-FR" })
            {
                var info = new ProcessStartInfo(Assembly.GetExecutingAssembly().Location, "--locale " + locale) { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true };
                using (var process = Process.Start(info))
                {
                    string actual = process.StandardOutput.ReadToEnd().Trim(); process.WaitForExit();
                    Check(process.ExitCode == 0 && actual == L.Resolve(locale), "Startup language " + locale + ": " + actual);
                }
            }
            foreach (string locale in new[] { "zh-TW", "zh-CN", "zh-HK", "zh-Hans-SG", "zh-Hant", "zh_MO" }) Check(L.Resolve(locale) == "zh", "Chinese mapping " + locale);
            foreach (string locale in new[] { "ja-JP", "ko-KR", "de-DE", "de-CH", "de-AT" }) Check(L.Resolve(locale) == locale.Substring(0, 2), "Locale mapping " + locale);
            foreach (string locale in new[] { "en-US", "fr-FR", "es-ES", "ar-SA", "", "invalid" }) Check(L.Resolve(locale) == "en", "Fallback " + locale);
            foreach (string code in L.Codes)
            {
                L.Select(code);
                foreach (string[] row in L.Catalog)
                {
                    string source = Regex.Replace(row[0], @"\{(\d+)\}", m => "VALUE" + m.Groups[1].Value);
                    string expected = Regex.Replace(row[Array.IndexOf(L.Codes, code)], @"\{(\d+)\}", m => "VALUE" + m.Groups[1].Value);
                    Check(L.T(source) == expected, code + " catalog rendering: " + source + " -> " + L.T(source));
                }
            }
            L.Select("en");
            Check(L.T("已執行送出點擊 2 輪；下個步驟剩 5 秒\n已貼上，等待點擊送出。 F8 可停止。") == "Send clicked for 2 rounds; next action in 5 s\nPasted; waiting to click Send. Press F8 to stop.", "Composed running status");
            Check(!Regex.IsMatch(L.T("執行失敗，已停止且不重試：焦點已離開目標視窗，已停止。 本輪可能留下草稿，重新啟動前請檢查。已發生的操作無法撤回。"), @"\p{IsCJKUnifiedIdeographs}"), "Composed failure status");
            using (var simple = new MainForm())
            using (var loop = new LoopForm())
            {
                simple.Opacity = loop.Opacity = 0; simple.ShowInTaskbar = loop.ShowInTaskbar = false;
                simple.Show(); loop.Show(); Application.DoEvents();
                var editor = Field<TextBox>(loop, "editor"); var mode = Field<ComboBox>(loop, "mode");
                mode.SelectedIndex = 1; Field<Button>(loop, "add").PerformClick();
                editor.Text = "使用者保留：目前時間 / Continue / 続けて / 계속 / Weiter 😀"; editor.Select(3, 5);
                string prompt = editor.Text;
                var first = Field<DateTimePicker>(loop, "first"); first.Value = DateTime.Now.AddHours(12); DateTime firstValue = first.Value;
                Field<NumericUpDown>(loop, "count").Value = 7;
                foreach (string code in L.Codes)
                {
                    Field<ComboBox>(simple, "language").SelectedIndex = Array.IndexOf(L.Codes, code);
                    Application.DoEvents();
                    Check(Field<ComboBox>(loop, "language").SelectedIndex == Array.IndexOf(L.Codes, code), "Cross-window selection");
                    Check(editor.Text == prompt && editor.SelectionStart == 3 && editor.SelectionLength == 5, "Language switch altered prompt/caret " + code);
                    Check(mode.SelectedIndex == 1 && Field<ListBox>(loop, "entries").SelectedIndex == 1, "Language switch altered prompt selection");
                    Check(first.Value == firstValue && Field<NumericUpDown>(loop, "count").Value == 7, "Language switch altered configuration");
                    var note = Field<Label>(loop, "notice"); var settings = Field<FlowLayoutPanel>(loop, "settings");
                    settings.AutoScrollPosition = Point.Empty;
                    Check(note.Visible && note.Parent == loop && loop.ClientRectangle.Contains(note.Bounds), "Notice not visible initially " + code);
                    Check(settings.Bottom <= note.Top, "Notice overlaps settings");
                    Check(note.Height >= TextRenderer.MeasureText(note.Text, note.Font, new Size(note.Width - note.Padding.Horizontal, Int32.MaxValue), TextFormatFlags.WordBreak | TextFormatFlags.TextBoxControl).Height + note.Padding.Vertical, "Notice clipped " + code);
                    Save(simple, Path.Combine(args[0], "simple-" + code + ".png")); Save(loop, Path.Combine(args[0], "loop-" + code + ".png"));
                    Size original = loop.Size; loop.Size = loop.MinimumSize; Application.DoEvents();
                    Check(loop.ClientRectangle.Contains(note.Bounds) && settings.Height > 100, "Notice lost at minimum window size " + code);
                    Save(loop, Path.Combine(args[0], "loop-min-" + code + ".png")); loop.Size = original;
                    if (code == "en") { EnglishText(simple, Field<ComboBox>(simple, "language")); EnglishText(loop, editor, Field<ComboBox>(loop, "language")); }
                    // Inspect the actual confirmation, including localized buttons; it performs no native input.
                    string summary = "首次：2026/10/14 10:00:00\n間隔：05:10:00（每輪結束後起算）\n停止：3 輪；截止 2026/10/15 12:00:00\n提示詞：依輪次設定（2 筆），重複最後一筆\n輸入框：X 10 / Y 20；送出鈕：X 30 / Y 40\n\n將真的輸入並點擊送出，會覆寫剪貼簿。\n會取代輸入框原有文字。\n請保持目標視窗／聊天不變。未驗證 AI 狀態或送達。";
                    using (var dialog = LocalizedDialog.Create(summary, "確認循環操作", MessageBoxButtons.OKCancel))
                    using (var closeDialog = new Timer { Interval = 50 })
                    {
                        dialog.Opacity = 0;
                        closeDialog.Tick += delegate
                        {
                            closeDialog.Stop();
                            Check(dialog.Visible, "Confirmation was not shown");
                            if (code == "en") EnglishText(dialog);
                            Save(dialog, Path.Combine(args[0], "confirmation-" + code + ".png"));
                            dialog.DialogResult = DialogResult.Cancel;
                        };
                        closeDialog.Start();
                        Check(dialog.ShowDialog(loop) == DialogResult.Cancel, "Localized confirmation cancellation");
                    }
                }
                // Switching UI language while armed must not re-arm, cancel, or change the prompt snapshot.
                var engine = Field<LoopEngine>(loop, "engine");
                engine.Start(new LoopPlan { FirstTime = DateTime.Now.AddHours(1), Interval = TimeSpan.FromHours(1), MaxRounds = 1, Prompts = new[] { prompt } }, DateTime.Now, 0);
                foreach (string code in L.Codes) { L.Select(code); Check(engine.Active && engine.Completed == 0 && editor.Text == prompt, "Language switch changed active work"); }
                engine.Stop("已取消排程。"); loop.Close(); simple.Close();
            }
            Console.WriteLine("PASS: " + checks + " localization/catalog/state/layout checks; both modes rendered in five languages.");
        }
        catch (Exception ex) { Console.WriteLine("FAIL: " + ex); Environment.ExitCode = 1; }
    }
}
