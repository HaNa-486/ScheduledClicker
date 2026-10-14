using System;
using System.Drawing;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal static class Ui
    {
        internal enum Role { Primary, Notice, Surface, Accent, Warning, Success, Error }
        internal static bool Dark { get; private set; }
        internal static event Action Changed;
        static Ui() { Dark = ReadSystemTheme(); }
        internal static bool ResolveTheme(object value) { return value is int && (int)value == 0; }
        internal static bool ReadSystemTheme()
        {
            try { using (var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize")) return ResolveTheme(key == null ? null : key.GetValue("AppsUseLightTheme")); }
            catch (System.Security.SecurityException) { return false; }
            catch (UnauthorizedAccessException) { return false; }
            catch (System.IO.IOException) { return false; }
        }
        internal static void Select(bool dark) { if (Dark == dark) return; Dark = dark; if (Changed != null) Changed(); }
        internal static Color Background { get { return Dark ? Color.FromArgb(17, 24, 39) : Color.FromArgb(247, 249, 252); } }
        internal static Color Surface { get { return Dark ? Color.FromArgb(31, 41, 55) : Color.White; } }
        internal static Color Text { get { return Dark ? Color.FromArgb(229, 231, 235) : Color.FromArgb(36, 45, 60); } }
        internal static Color Accent { get { return Dark ? Color.FromArgb(139, 188, 255) : Color.FromArgb(32, 106, 196); } }
        internal static Color Notice { get { return Dark ? Color.FromArgb(48, 43, 28) : Color.FromArgb(255, 249, 230); } }
        internal static Color DisabledText { get { return Dark ? Color.FromArgb(158, 173, 194) : Color.FromArgb(100, 110, 124); } }
        private static Color PrimaryColor { get { return Color.FromArgb(37, 99, 235); } }
        [DllImport("dwmapi.dll")] private static extern int DwmSetWindowAttribute(IntPtr window, int attribute, ref int value, int size);
        internal static void TitleBar(Form form)
        {
            if (!form.IsHandleCreated) return;
            int dark = Dark ? 1 : 0;
            try { DwmSetWindowAttribute(form.Handle, 20, ref dark, sizeof(int)); }
            catch (DllNotFoundException) { } catch (EntryPointNotFoundException) { }
        }
        internal static void Tone(Control control, Role role) { control.Tag = role; PaintControl(control); }
        internal static void Apply(Control root)
        {
            root.SuspendLayout();
            PaintControl(root);
            foreach (Control child in root.Controls) Apply(child);
            root.ResumeLayout(false); root.Invalidate();
            var form = root as Form; if (form != null) TitleBar(form);
        }
        private static void PaintControl(Control control)
        {
            var role = control.Tag is Role ? (Role?)control.Tag : null;
            control.ForeColor = Text;
            control.BackColor = control.Parent == null ? Background : control.Parent.BackColor;
            if (control is Form || control is UserControl) control.BackColor = Background;
            if (control is GroupBox || role == Role.Surface) control.BackColor = Surface;
            if (control is TextBoxBase || control is ListBox || control is UpDownBase || control is ComboBox) control.BackColor = Dark ? Background : Color.White;
            var button = control as Button;
            if (button != null) {
                button.Paint -= DisabledButtonPaint; button.Paint += DisabledButtonPaint;
                button.UseVisualStyleBackColor = false; button.FlatStyle = FlatStyle.Flat;
                button.FlatAppearance.BorderColor = Dark ? Color.FromArgb(83, 99, 120) : Color.FromArgb(190, 199, 211);
                button.FlatAppearance.MouseOverBackColor = Dark ? Color.FromArgb(50, 65, 85) : Color.FromArgb(228, 237, 250);
                button.BackColor = Surface;
            }
            var combo = control as ComboBox;
            if (combo != null && combo.DrawMode != DrawMode.OwnerDrawFixed) {
                combo.DrawMode = DrawMode.OwnerDrawFixed; combo.ItemHeight = combo.Font.Height + 2;
                combo.DrawItem += DrawComboItem;
            }
            var list = control as ListBox; if (list != null && list.DrawMode != DrawMode.OwnerDrawFixed) { list.DrawMode = DrawMode.OwnerDrawFixed; list.ItemHeight = list.Font.Height + 2; list.DrawItem += DrawListItem; }
            var check = control as CheckBox; if (check != null) { check.Paint -= DisabledCheckPaint; check.Paint += DisabledCheckPaint; check.FlatStyle = FlatStyle.Flat; check.UseVisualStyleBackColor = false; }
            var radio = control as RadioButton; if (radio != null) { radio.FlatStyle = FlatStyle.Flat; radio.UseVisualStyleBackColor = false; }
            if (role == Role.Primary) {
                control.BackColor = PrimaryColor; control.ForeColor = Color.White;
                if (button != null) { button.FlatAppearance.MouseOverBackColor = Color.FromArgb(29, 78, 216); button.FlatAppearance.MouseDownBackColor = Color.FromArgb(30, 64, 175); }
            }
            if (role == Role.Notice) { control.BackColor = Notice; control.ForeColor = Dark ? Color.FromArgb(245, 226, 172) : Text; }
            if (role == Role.Accent) control.ForeColor = Accent;
            if (role == Role.Warning) control.ForeColor = Dark ? Color.FromArgb(255, 199, 130) : Color.FromArgb(150, 75, 15);
            if (role == Role.Success) control.ForeColor = Dark ? Color.FromArgb(129, 223, 170) : Color.FromArgb(32, 130, 83);
            if (role == Role.Error) control.ForeColor = Dark ? Color.FromArgb(255, 170, 167) : Color.FromArgb(190, 55, 55);
            // Date/time fields keep native segment editing, selection, spin buttons and accessibility.
            if (control is DateTimePicker) { control.BackColor = SystemColors.Window; control.ForeColor = SystemColors.WindowText; }
        }
        private static void DrawComboItem(object sender, DrawItemEventArgs e)
        {
            var combo = (ComboBox)sender;
            bool selected = (e.State & DrawItemState.Selected) != 0;
            Color background = selected ? PrimaryColor : (Dark ? Background : Color.White);
            Color foreground = selected ? Color.White : Text;
            using (var brush = new SolidBrush(background)) e.Graphics.FillRectangle(brush, e.Bounds);
            string text = e.Index >= 0 ? Convert.ToString(combo.Items[e.Index]) : combo.Text;
            TextRenderer.DrawText(e.Graphics, text, combo.Font, e.Bounds, foreground, TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.NoPrefix);
            e.DrawFocusRectangle();
        }
        private static void DrawListItem(object sender, DrawItemEventArgs e)
        {
            var list = (ListBox)sender; if (e.Index < 0) return;
            bool selected = (e.State & DrawItemState.Selected) != 0;
            Color background = list.Enabled ? (selected ? PrimaryColor : list.BackColor) : Surface;
            Color foreground = list.Enabled ? (selected ? Color.White : Text) : DisabledText;
            using (var brush = new SolidBrush(background)) e.Graphics.FillRectangle(brush, e.Bounds);
            TextRenderer.DrawText(e.Graphics, Convert.ToString(list.Items[e.Index]), list.Font, e.Bounds, foreground, TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.NoPrefix);
            e.DrawFocusRectangle();
        }
        private static void DisabledCheckPaint(object sender, PaintEventArgs e)
        {
            var check = (CheckBox)sender; if (check.Enabled) return;
            e.Graphics.Clear(check.BackColor);
            int side = Math.Max(12, check.Font.Height - 5), y = (check.Height - side) / 2;
            using (var pen = new Pen(DisabledText)) {
                e.Graphics.DrawRectangle(pen, 1, y, side, side);
                if (check.Checked) e.Graphics.DrawLines(pen, new[] { new Point(3, y + side / 2), new Point(1 + side / 2, y + side - 3), new Point(side - 1, y + 3) });
            }
            TextRenderer.DrawText(e.Graphics, check.Text, check.Font, new Rectangle(side + 6, 0, Math.Max(0, check.Width - side - 6), check.Height), DisabledText, TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.NoPrefix);
        }
        private static void DisabledButtonPaint(object sender, PaintEventArgs e)
        {
            var button = (Button)sender; if (button.Enabled) return;
            e.Graphics.Clear(Surface);
            using (var pen = new Pen(Dark ? Color.FromArgb(83, 99, 120) : Color.FromArgb(190, 199, 211)))
                e.Graphics.DrawRectangle(pen, 0, 0, button.Width - 1, button.Height - 1);
            TextRenderer.DrawText(e.Graphics, button.Text, button.Font, button.ClientRectangle,
                DisabledText, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.NoPrefix);
        }
        internal static void Selected(Button button, bool selected)
        {
            if ((button.Tag is Role && (Role)button.Tag == Role.Primary) == selected && button.BackColor == (selected ? PrimaryColor : Surface)) return;
            button.Tag = selected ? (object)Role.Primary : null; PaintControl(button);
        }
        internal static Button Button(string text) { return new Button { Text = text, AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink, MinimumSize = new Size(80, 30), Padding = new Padding(8, 1, 8, 1), Margin = new Padding(3, 2, 3, 2) }; }
        internal static void Primary(Button button) { Tone(button, Role.Primary); }
        internal static GroupBox Card(string title) { return new GroupBox { Text = title, Dock = DockStyle.Fill, BackColor = Color.White, Padding = new Padding(4), Margin = new Padding(0, 0, 8, 8) }; }
        internal static TableLayoutPanel Columns(float left, float right)
        {
            var grid = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 1, Margin = new Padding(0) };
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, left)); grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, right));
            grid.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); return grid;
        }
    }
}
