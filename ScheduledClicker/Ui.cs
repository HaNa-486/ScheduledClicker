using System.Drawing;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal static class Ui
    {
        internal static readonly Color Background = Color.FromArgb(247, 249, 252);
        internal static readonly Color Notice = Color.FromArgb(255, 249, 230);
        internal static Button Button(string text) { return new Button { Text = text, AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink, MinimumSize = new Size(80, 30), Padding = new Padding(8, 2, 8, 2), Margin = new Padding(3, 2, 3, 2) }; }
        internal static void Primary(Button button) { button.BackColor = Color.FromArgb(42, 116, 214); button.ForeColor = Color.White; button.FlatStyle = FlatStyle.Flat; button.FlatAppearance.BorderSize = 0; }
        internal static GroupBox Card(string title) { return new GroupBox { Text = title, Dock = DockStyle.Fill, BackColor = Color.White, Padding = new Padding(4), Margin = new Padding(0, 0, 8, 8) }; }
        internal static TableLayoutPanel Columns(float left, float right)
        {
            var grid = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 1, Margin = new Padding(0) };
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, left)); grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, right));
            grid.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); return grid;
        }
    }
}
