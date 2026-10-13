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
    [STAThread] private static void Main(string[] args)
    {
        Application.EnableVisualStyles();
        using (var form = new LoopForm())
        {
            form.Shown += delegate
            {
                try
                {
                    var mode = Field<ComboBox>(form, "mode"); var editor = Field<TextBox>(form, "editor");
                    mode.SelectedIndex = 1;
                    Field<Button>(form, "add").PerformClick(); editor.Text = "第二輪：繼續\r\n保留進度 😀";
                    mode.SelectedIndex = 0; editor.Text = "第一輪提示";
                    var prompts = Field<List<string>>(form, "prompts");
                    if (prompts.Count != 2 || prompts[0] != "第一輪提示" || !prompts[1].Contains("第二輪")) throw new Exception("Prompt editing lost data");
                    mode.SelectedIndex = 1; Field<ListBox>(form, "entries").SelectedIndex = 1;
                    if (!editor.Text.Contains("第二輪")) throw new Exception("Prompt selection mismatch");
                    using (var bitmap = new Bitmap(form.Width, form.Height))
                    { form.DrawToBitmap(bitmap, new Rectangle(Point.Empty, form.Size)); bitmap.Save(args[0], ImageFormat.Png); }
                    var settings = Field<FlowLayoutPanel>(form, "settings");
                    settings.ScrollControlIntoView(settings.Controls[settings.Controls.Count - 1]);
                    using (var bitmap = new Bitmap(form.Width, form.Height))
                    { form.DrawToBitmap(bitmap, new Rectangle(Point.Empty, form.Size)); bitmap.Save(args[0].Replace(".png", "-bottom.png"), ImageFormat.Png); }
                    Console.WriteLine("PASS: loop UI prompt modes, entry editing and rendering");
                }
                catch (Exception ex) { Console.WriteLine("FAIL: " + ex.Message); Environment.ExitCode = 1; }
                form.Close();
            };
            Application.Run(form);
        }
    }
}
