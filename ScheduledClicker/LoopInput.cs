using System;
using System.Drawing;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace ScheduledClicker
{
    internal sealed class LoopTarget
    {
        internal Point Point;
        internal IntPtr Window;
        internal Rectangle Bounds;
        internal uint Process;

        internal static LoopTarget Capture(Point point)
        {
            IntPtr root = NativeLoopInput.RootAt(point);
            NativeLoopInput.Rect rect;
            uint process;
            if (root == IntPtr.Zero || !NativeLoopInput.GetWindowRect(root, out rect))
                throw new InvalidOperationException("無法識別目標視窗，請重新擷取。");
            NativeLoopInput.GetWindowThreadProcessId(root, out process);
            return new LoopTarget { Point = point, Window = root, Bounds = rect.Rectangle, Process = process };
        }
    }

    internal sealed class NativeLoopInput : ILoopActions
    {
        internal LoopTarget Input;
        internal LoopTarget Submit;
        private string displays;

        [StructLayout(LayoutKind.Sequential)] internal struct Rect
        {
            internal int Left, Top, Right, Bottom;
            internal Rectangle Rectangle { get { return Rectangle.FromLTRB(Left, Top, Right, Bottom); } }
        }
        // Explicit union includes mouse input to retain INPUT's native size on x86/x64.
        [StructLayout(LayoutKind.Sequential)] private struct InputEvent { internal uint Type; internal InputUnion Data; }
        [StructLayout(LayoutKind.Explicit)] private struct InputUnion
        {
            [FieldOffset(0)] internal KeyInput Key;
            [FieldOffset(0)] internal MouseInput Mouse;
        }
        [StructLayout(LayoutKind.Sequential)] private struct KeyInput
        { internal ushort Key, Scan; internal uint Flags, Time; internal IntPtr Extra; }
        [StructLayout(LayoutKind.Sequential)] private struct MouseInput
        { internal int X, Y; internal uint Data, Flags, Time; internal IntPtr Extra; }

        [DllImport("user32.dll")] private static extern IntPtr WindowFromPoint(Point point);
        [DllImport("user32.dll")] private static extern IntPtr GetAncestor(IntPtr window, uint flags);
        [DllImport("user32.dll")] internal static extern bool GetWindowRect(IntPtr window, out Rect rect);
        [DllImport("user32.dll")] internal static extern uint GetWindowThreadProcessId(IntPtr window, out uint process);
        [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
        [DllImport("user32.dll", SetLastError = true)] private static extern uint SendInput(uint count, InputEvent[] events, int size);
        [DllImport("user32.dll", SetLastError = true)] private static extern IntPtr OpenInputDesktop(uint flags, bool inherit, uint access);
        [DllImport("user32.dll")] private static extern bool CloseDesktop(IntPtr desktop);
        [DllImport("user32.dll")] private static extern bool SwitchDesktop(IntPtr desktop);

        internal static IntPtr RootAt(Point point) { return GetAncestor(WindowFromPoint(point), 2); }
        private static string DisplayLayout()
        {
            return String.Join(";", Screen.AllScreens.OrderBy(s => s.DeviceName).Select(s => s.DeviceName + s.Bounds.ToString()).ToArray());
        }
        internal void Prepare()
        {
            if (Input == null || Submit == null || Input.Window != Submit.Window)
                throw new InvalidOperationException("請擷取同一目標視窗的輸入框與送出按鈕。");
            displays = DisplayLayout();
        }
        private void Check(LoopTarget target, bool requireFocus)
        {
            IntPtr desktop = OpenInputDesktop(0, false, 0x100);
            if (desktop == IntPtr.Zero) throw new InvalidOperationException("桌面無法操作，排程已停止。");
            try { if (!SwitchDesktop(desktop)) throw new InvalidOperationException("桌面已鎖定或不可操作。"); }
            finally { CloseDesktop(desktop); }
            if (DisplayLayout() != displays) throw new InvalidOperationException("螢幕配置已改變，請重新擷取。");
            Rect rect;
            uint process;
            GetWindowThreadProcessId(target.Window, out process);
            if (process != target.Process || !GetWindowRect(target.Window, out rect) || rect.Rectangle != target.Bounds || RootAt(target.Point) != target.Window)
                throw new InvalidOperationException("目標視窗移動、被遮住或已關閉，請檢查後重新擷取。");
            if (requireFocus && GetForegroundWindow() != target.Window)
                throw new InvalidOperationException("焦點已離開目標視窗，已停止。");
            foreach (int key in new[] { 0x10, 0x11, 0x12, 0x5B, 0x5C })
                if ((GetAsyncKeyState(key) & 0x8000) != 0) throw new InvalidOperationException("偵測到修飾鍵按住，已停止。");
        }
        public void FocusInput() { Check(Input, false); Check(Submit, false); NativeMouse.Click(Input.Point, ClickKind.Single); }
        public void Paste(string prompt, bool replaceDraft)
        {
            Check(Input, true);
            Clipboard.SetText(prompt, TextDataFormat.UnicodeText);
            if (replaceDraft) Chord(0x41);
            Chord(0x56);
        }
        public void Send() { Check(Submit, true); NativeMouse.Click(Submit.Point, ClickKind.Single); }

        private static InputEvent Key(ushort code, bool up)
        {
            return new InputEvent { Type = 1, Data = new InputUnion { Key = new KeyInput { Key = code, Flags = up ? 2U : 0U } } };
        }
        private static void Chord(ushort key)
        {
            var events = new[] { Key(0x11, false), Key(key, false), Key(key, true), Key(0x11, true) };
            if (SendInput((uint)events.Length, events, Marshal.SizeOf(typeof(InputEvent))) != events.Length)
            {
                // Best-effort release after a partially accepted batch.
                var release = new[] { Key(key, true), Key(0x11, true) };
                SendInput(2, release, Marshal.SizeOf(typeof(InputEvent)));
                throw new InvalidOperationException("Windows 未完整接受鍵盤輸入，已停止。");
            }
        }
    }
}
