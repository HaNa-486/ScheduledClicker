using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace ScheduledClicker
{
    // UI-only translation boundary. Scheduler reasons stay stable; user prompt text never enters it.
    internal static partial class L
    {
        internal static readonly string[] Codes = { "zh", "en", "ja", "ko", "de" };
        internal static readonly string[] Names = { "繁體中文", "English", "日本語", "한국어", "Deutsch" };
        internal static string Language = Resolve(CultureInfo.CurrentUICulture.Name);
        internal static event Action Changed;
        private static readonly Dictionary<string, string[]> lookup;
        private static readonly Regex literals;
        private sealed class Template { internal string[] Row; internal Regex Pattern; }
        private static readonly Template[] templates;
        static L()
        {
            lookup = Catalog.ToDictionary(r => r[0]);
            literals = new Regex(String.Join("|", Catalog.Where(r => !r[0].Contains("{0}")).OrderByDescending(r => r[0].Length).Select(r => Regex.Escape(r[0])).ToArray()));
            templates = Catalog.Where(r => r[0].Contains("{0}")).OrderByDescending(r => Regex.Replace(r[0], @"\{\d+\}", "").Length).Select(r => new Template { Row = r, Pattern = new Regex("^" + Regex.Replace(Regex.Escape(r[0]), @"\\\{(\d+)}", m => "(?<p" + m.Groups[1].Value + ">.*?)") + "$") }).ToArray();
        }

        internal static string Resolve(string locale)
        {
            string code = (locale ?? "").Replace('_', '-').Split('-')[0].ToLowerInvariant();
            return code == "zh" || code == "ja" || code == "ko" || code == "de" ? code : "en";
        }
        internal static void Select(string code)
        {
            if (!Codes.Contains(code) || Language == code) return;
            Language = code; if (Changed != null) Changed();
        }
        internal static string T(string source) { return Render(source, 0); }
        private static string Render(string source, int depth)
        {
            if (String.IsNullOrEmpty(source) || Language == "zh" || depth > 8) return source;
            int index = Array.IndexOf(Codes, Language);
            string[] row;
            if (lookup.TryGetValue(source, out row)) return row[index];
            if (source.Contains("\n")) return String.Join("\n", source.Split('\n').Select(s => Render(s.TrimEnd('\r'), depth + 1)).ToArray());
            foreach (Template template in templates)
            {
                Match match = template.Pattern.Match(source);
                if (!match.Success) continue;
                return Regex.Replace(template.Row[index], @"\{(\d+)\}", m => Render(match.Groups["p" + m.Groups[1].Value].Value, depth + 1));
            }
            // Composed legacy status messages contain known reason + draft/F8 suffixes.
            return literals.Replace(source, m => lookup[m.Value][index]);
        }
        internal static ComboBox Picker()
        {
            var picker = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList, Width = 145, AccessibleName = "Language" };
            picker.Items.AddRange(Names); picker.SelectedIndex = Array.IndexOf(Codes, Language);
            picker.SelectedIndexChanged += delegate { if (picker.SelectedIndex >= 0) Select(Codes[picker.SelectedIndex]); };
            Action update = delegate { picker.SelectedIndex = Array.IndexOf(Codes, Language); };
            Changed += update; picker.Disposed += delegate { Changed -= update; };
            return picker;
        }
    }

    // Explicitly binds only labels, buttons and group titles. Editable text and dates are excluded.
    internal sealed class LocalizedView : IDisposable
    {
        private readonly List<Action> updates = new List<Action>();
        internal LocalizedView(Control root, params Control[] excluded)
        {
            Bind(root, new HashSet<Control>(excluded));
            L.Changed += Refresh; Refresh();
        }
        private void Bind(Control control, HashSet<Control> excluded)
        {
            if (excluded.Contains(control)) return;
            if (control is Form || control is Label || control is ButtonBase || control is GroupBox)
            {
                string key = control.Text; updates.Add(delegate { control.Text = L.T(key); });
            }
            foreach (Control child in control.Controls) Bind(child, excluded);
        }
        internal void Refresh() { foreach (Action update in updates) update(); }
        public void Dispose() { L.Changed -= Refresh; }
    }

    internal static class LocalizedDialog
    {
        internal static DialogResult Show(IWin32Window owner, string message, string title = "定時滑鼠點擊器", MessageBoxButtons buttons = MessageBoxButtons.OK, MessageBoxIcon icon = MessageBoxIcon.None)
        {
            using (var dialog = Create(message, title, buttons)) return dialog.ShowDialog(owner);
        }
        internal static Form Create(string message, string title, MessageBoxButtons buttons)
        {
                var dialog = new Form { Text = L.T(title), Font = new System.Drawing.Font("Microsoft JhengHei UI", 10F), FormBorderStyle = FormBorderStyle.FixedDialog, StartPosition = FormStartPosition.CenterParent, MaximizeBox = false, MinimizeBox = false, ShowInTaskbar = false };
                var body = new Label { Text = L.T(message), AutoSize = true, MaximumSize = new System.Drawing.Size(630, 0), Location = new System.Drawing.Point(20, 20) };
                dialog.Controls.Add(body);
                int height = body.GetPreferredSize(new System.Drawing.Size(630, 0)).Height;
                var ok = new Button { Text = L.T("確定"), DialogResult = DialogResult.OK, Size = new System.Drawing.Size(140, 36), Location = new System.Drawing.Point(355, height + 40) };
                dialog.Controls.Add(ok); dialog.AcceptButton = ok;
                if (buttons == MessageBoxButtons.OKCancel)
                {
                    var cancel = new Button { Text = L.T("取消"), DialogResult = DialogResult.Cancel, Size = new System.Drawing.Size(140, 36), Location = new System.Drawing.Point(510, height + 40) };
                    dialog.Controls.Add(cancel); dialog.CancelButton = cancel;
                }
                else dialog.CancelButton = ok;
                dialog.ClientSize = new System.Drawing.Size(670, height + 96);
                Ui.Primary(ok); Ui.Apply(dialog); dialog.HandleCreated += delegate { Ui.TitleBar(dialog); };
                return dialog;
        }
    }
}
