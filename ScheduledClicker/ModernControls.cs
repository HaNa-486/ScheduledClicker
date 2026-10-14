using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Globalization;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal static class Shapes
    {
        internal static GraphicsPath Rounded(RectangleF r, float radius)
        {
            var p = new GraphicsPath(); float d = Math.Min(radius * 2, Math.Min(r.Width, r.Height));
            p.AddArc(r.X, r.Y, d, d, 180, 90); p.AddArc(r.Right-d, r.Y, d, d, 270, 90);
            p.AddArc(r.Right-d, r.Bottom-d, d, d, 0, 90); p.AddArc(r.X, r.Bottom-d, d, d, 90, 90); p.CloseFigure(); return p;
        }
        internal static void Chevron(Graphics g, Color color, int x, int y, bool up)
        {
            using (var pen = new Pen(color, 1.4F)) { g.SmoothingMode = SmoothingMode.AntiAlias; g.DrawLines(pen, new[] { new Point(x-3, y+(up?2:-2)), new Point(x, y+(up?-1:1)), new Point(x+3, y+(up?2:-2)) }); }
        }
    }
    internal sealed class ModernButton : Button
    {
        internal bool IconOnly;
        private bool hover, pressed;
        internal ModernButton() { SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true); }
        protected override void OnMouseEnter(EventArgs e) { hover = true; Invalidate(); base.OnMouseEnter(e); }
        protected override void OnMouseLeave(EventArgs e) { hover = pressed = false; Invalidate(); base.OnMouseLeave(e); }
        protected override void OnMouseDown(MouseEventArgs e) { pressed = true; Invalidate(); base.OnMouseDown(e); }
        protected override void OnMouseUp(MouseEventArgs e) { pressed = false; Invalidate(); base.OnMouseUp(e); }
        protected override void OnKeyDown(KeyEventArgs e) { if (e.KeyCode == Keys.Space) { pressed = true; Invalidate(); } base.OnKeyDown(e); }
        protected override void OnKeyUp(KeyEventArgs e) { pressed = false; Invalidate(); base.OnKeyUp(e); }
        protected override void OnPaint(PaintEventArgs e)
        {
            var g=e.Graphics; g.Clear(Parent == null ? Ui.Background : Parent.BackColor); g.SmoothingMode=SmoothingMode.AntiAlias;
            bool primary=Tag is Ui.Role && (Ui.Role)Tag==Ui.Role.Primary;
            bool selected=Tag is Ui.Role && (Ui.Role)Tag==Ui.Role.Selected;
            Color fill=!Enabled ? Ui.Field : primary ? (pressed?Ui.PrimaryPressed:hover?Ui.PrimaryHover:Ui.PrimaryColor) : selected ? Ui.SelectedSurface : (hover ? Ui.Hover : Ui.Field);
            Color ink=!Enabled?Ui.DisabledText:primary?Color.White:Ui.Text;
            if (IconOnly && !hover) fill=Parent.BackColor;
            using(var path=Shapes.Rounded(new RectangleF(1,1,Width-2,Height-2),7))
            using(var brush=new SolidBrush(fill)) { g.FillPath(brush,path); if (!primary && !IconOnly && !selected) using(var pen=new Pen(Ui.Stroke))g.DrawPath(pen,path); }
            if(IconOnly)
            {
                int x=Width/2,y=Height/2;
                using(var pen=new Pen(ink,1.5F)) {
                    if(Ui.Dark) { g.DrawEllipse(pen,x-4,y-4,8,8); for(int i=0;i<8;i++){double a=i*Math.PI/4;g.DrawLine(pen,x+(float)Math.Cos(a)*7,y+(float)Math.Sin(a)*7,x+(float)Math.Cos(a)*10,y+(float)Math.Sin(a)*10);} }
                    else { using(var moon=new SolidBrush(ink))g.FillEllipse(moon,x-8,y-8,16,16);using(var cut=new SolidBrush(fill))g.FillEllipse(cut,x-3,y-10,14,14); }
                }
            }
            else TextRenderer.DrawText(g,Text,Font,ClientRectangle,ink,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPrefix);
            if(Focused && ShowFocusCues) using(var path=Shapes.Rounded(new RectangleF(3,3,Width-6,Height-6),5))using(var pen=new Pen(Ui.Accent,1.5F))g.DrawPath(pen,path);
        }
    }
    internal sealed class ModernCard : GroupBox
    {
        internal ModernCard() { SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true); }
        public override Rectangle DisplayRectangle { get { return new Rectangle(Padding.Left,28,Math.Max(0,Width-Padding.Horizontal),Math.Max(0,Height-28-Padding.Bottom)); } }
        protected override void OnPaint(PaintEventArgs e)
        {
            var g=e.Graphics;g.Clear(Parent==null?Ui.Background:Parent.BackColor);g.SmoothingMode=SmoothingMode.AntiAlias;
            using(var p=Shapes.Rounded(new RectangleF(0,0,Width-1,Height-1),11))using(var b=new SolidBrush(Ui.Surface))g.FillPath(b,p);
            using(var f=new Font(Font,FontStyle.Bold))TextRenderer.DrawText(g,Text,f,new Rectangle(14,7,Width-28,20),Ui.Text,TextFormatFlags.Left|TextFormatFlags.VerticalCenter|TextFormatFlags.NoPrefix);
        }
    }
    internal sealed class ModernCombo : ComboBox
    {
        private void Chrome(Graphics g)
        {
            Color ink=Enabled?Ui.Muted:Ui.DisabledText;
            using(var b=new SolidBrush(Ui.Field))g.FillRectangle(b,Width-21,1,20,Height-2);
            // Cover the native inset bevel as well as the outer frame in both themes.
            using(var p=new Pen(Ui.Field,2))g.DrawRectangle(p,1,1,Width-3,Height-3);
            using(var p=new Pen(Focused?Ui.Accent:Ui.Stroke))g.DrawRectangle(p,0,0,Width-1,Height-1);
            Shapes.Chevron(g,ink,Width-11,Height/2,false);
        }
        protected override void WndProc(ref Message m)
        {
            base.WndProc(ref m);
            if(m.Msg==0xF && IsHandleCreated) using(var g=Graphics.FromHwnd(Handle))Chrome(g);
            else if((m.Msg==0x317||m.Msg==0x318) && m.WParam!=IntPtr.Zero) using(var g=Graphics.FromHdc(m.WParam))Chrome(g);
        }
    }
    internal sealed class ModernNumber : NumericUpDown
    {
        internal ModernNumber() { BorderStyle=BorderStyle.None; }
        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            foreach(Control child in Controls) if(!(child is TextBox)) { child.Paint-=PaintSpin;child.Paint+=PaintSpin; }
        }
        private void PaintSpin(object sender,PaintEventArgs e)
        {
            var c=(Control)sender;e.Graphics.Clear(Ui.Field);
            Shapes.Chevron(e.Graphics,Enabled?Ui.Muted:Ui.DisabledText,c.Width/2,c.Height/4,true);
            Shapes.Chevron(e.Graphics,Enabled?Ui.Muted:Ui.DisabledText,c.Width/2,c.Height*3/4,false);
        }
    }
    // A themed, explicitly formatted date editor. Invalid text is never silently used to arm a schedule.
    internal sealed class DateTimeField : UserControl
    {
        private readonly TextBox editor=new TextBox { BorderStyle=BorderStyle.None };
        private DateTime lastValue=DateTime.Now;
        private string format="yyyy/MM/dd HH:mm:ss";
        internal DateTimeField()
        {
            Height=28;TabStop=false;SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);
            Controls.Add(editor);editor.Text=lastValue.ToString(format,CultureInfo.InvariantCulture);
            editor.TextChanged+=delegate { Invalidate(); };editor.Enter+=delegate { Invalidate(); };
            editor.Leave+=delegate { DateTime d;if(TryGetValue(out d))Value=d;Invalidate(); };
            editor.KeyDown+=delegate(object sender,KeyEventArgs e){ if(e.KeyCode==Keys.Up||e.KeyCode==Keys.Down){Nudge(e.KeyCode==Keys.Up?1:-1);e.Handled=true;e.SuppressKeyPress=true;} };
        }
        internal DateTimePickerFormat Format { get;set; }
        internal void Describe(string name) { AccessibleName=editor.AccessibleName=name; editor.AccessibleDescription="yyyy/MM/dd HH:mm:ss"; }
        internal bool ShowUpDown { get;set; }
        internal string CustomFormat { get{return format;} set{format=value;Value=lastValue;} }
        internal DateTime Value { get { DateTime d;if(!TryGetValue(out d))throw new InvalidOperationException(L.T("請輸入有效的日期與時間（yyyy/MM/dd HH:mm:ss）。"));return d; } set{lastValue=value;editor.Text=value.ToString(format,CultureInfo.InvariantCulture);} }
        internal bool TryGetValue(out DateTime value)
        {
            string text=System.Text.RegularExpressions.Regex.Replace(editor.Text.Trim(),@"\s+"," ");
            return DateTime.TryParseExact(text,"yyyy/MM/dd HH:mm:ss",CultureInfo.InvariantCulture,DateTimeStyles.AssumeLocal,out value);
        }
        internal void Nudge(int step)
        {
            DateTime d;if(!TryGetValue(out d))return;
            int caret=editor.SelectionStart;
            try { Value=caret<4?d.AddYears(step):caret<7?d.AddMonths(step):caret<10?d.AddDays(step):caret<13?d.AddHours(step):caret<16?d.AddMinutes(step):d.AddSeconds(step); }
            catch(ArgumentOutOfRangeException){return;}
            editor.Select(caret,0);editor.Focus();
        }
        protected override void OnMouseDown(MouseEventArgs e) { base.OnMouseDown(e);if(e.X>=Width-25)Nudge(e.Y<Height/2?1:-1);else editor.Focus(); }
        protected override void OnLayout(LayoutEventArgs e) { base.OnLayout(e);editor.SetBounds(9,Math.Max(2,(Height-editor.PreferredHeight)/2),Math.Max(0,Width-36),editor.PreferredHeight); }
        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);var g=e.Graphics;g.Clear(Parent==null?Ui.Surface:Parent.BackColor);g.SmoothingMode=SmoothingMode.AntiAlias;
            DateTime d;Color border=!TryGetValue(out d)?Color.IndianRed:ContainsFocus?Ui.Accent:Ui.Stroke;
            using(var path=Shapes.Rounded(new RectangleF(0,0,Width-1,Height-1),5))using(var b=new SolidBrush(Ui.Field))using(var p=new Pen(border)){g.FillPath(b,path);g.DrawPath(p,path);}
            Shapes.Chevron(g,Enabled?Ui.Muted:Ui.DisabledText,Width-12,Height/4,true);
            Shapes.Chevron(g,Enabled?Ui.Muted:Ui.DisabledText,Width-12,Height*3/4,false);
        }
    }
}
