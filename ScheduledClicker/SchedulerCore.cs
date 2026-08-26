using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;

namespace ScheduledClicker
{
    internal enum ClickKind
    {
        Single = 1,
        Double = 2
    }

    internal enum CancelResult
    {
        Canceled,
        Executing,
        NothingScheduled
    }

    internal sealed class ClickPlan
    {
        public DateTime TargetTime { get; private set; }
        public Point TargetPoint { get; private set; }
        public ClickKind ClickKind { get; private set; }

        public ClickPlan(DateTime targetTime, Point targetPoint, ClickKind clickKind)
        {
            TargetTime = targetTime;
            TargetPoint = targetPoint;
            ClickKind = clickKind;
        }
    }

    internal static class PlanValidator
    {
        internal static string Validate(ClickPlan plan, DateTime now, Rectangle virtualScreen)
        {
            if (plan == null) return "排程資料不存在。";
            if (plan.TargetTime <= now) return "執行時間必須晚於現在。";
            if (plan.TargetTime > now.AddDays(365)) return "執行時間最多可設定在 365 天內。";
            if (!virtualScreen.Contains(plan.TargetPoint)) return "點擊位置不在目前可用的螢幕範圍內。";
            if (plan.ClickKind != ClickKind.Single && plan.ClickKind != ClickKind.Double) return "點擊類型無效。";
            return null;
        }
    }

    internal sealed class ScheduleService : IDisposable
    {
        private readonly object sync = new object();
        private Timer timer;
        private ClickPlan currentPlan;
        private int generation;
        private bool isExecuting;

        internal event Action<ClickPlan> Executed;
        internal event Action<Exception> Failed;

        internal bool IsArmed
        {
            get { lock (sync) return currentPlan != null; }
        }

        internal bool IsExecuting
        {
            get { lock (sync) return isExecuting; }
        }

        internal void Arm(ClickPlan plan)
        {
            lock (sync)
            {
                CancelLocked();
                currentPlan = plan;
                generation++;
                int localGeneration = generation;
                timer = new Timer(delegate { CheckAndRun(localGeneration); }, null, NextDelay(plan.TargetTime), Timeout.Infinite);
            }
        }

        internal CancelResult Cancel()
        {
            lock (sync)
            {
                CancelResult result = currentPlan != null
                    ? CancelResult.Canceled
                    : (isExecuting ? CancelResult.Executing : CancelResult.NothingScheduled);
                generation++;
                CancelLocked();
                return result;
            }
        }

        private void CheckAndRun(int expectedGeneration)
        {
            ClickPlan plan;
            lock (sync)
            {
                if (currentPlan == null || expectedGeneration != generation) return;
                plan = currentPlan;
                if (DateTime.Now < plan.TargetTime)
                {
                    timer.Change(NextDelay(plan.TargetTime), Timeout.Infinite);
                    return;
                }
                currentPlan = null;
                isExecuting = true;
                if (timer != null) timer.Dispose();
                timer = null;
            }

            try
            {
                if (DateTime.Now - plan.TargetTime > TimeSpan.FromSeconds(5))
                    throw new InvalidOperationException("已錯過預定時間超過 5 秒，為避免誤點擊已取消。 ");
                if (!NativeMouse.IsPointOnActiveMonitor(plan.TargetPoint))
                    throw new InvalidOperationException("螢幕配置已改變，原先位置已不在可用螢幕上，已取消點擊。 ");
                NativeMouse.Click(plan.TargetPoint, plan.ClickKind);
                var handler = Executed;
                if (handler != null) handler(plan);
            }
            catch (Exception ex)
            {
                var handler = Failed;
                if (handler != null) handler(ex);
            }
            finally
            {
                lock (sync) isExecuting = false;
            }
        }

        private static int NextDelay(DateTime target)
        {
            double milliseconds = (target - DateTime.Now).TotalMilliseconds;
            if (milliseconds <= 25) return Math.Max(1, (int)Math.Ceiling(milliseconds));
            if (milliseconds <= 2000) return 20;
            if (milliseconds <= 30000) return 250;
            return 1000;
        }

        private void CancelLocked()
        {
            currentPlan = null;
            if (timer != null) timer.Dispose();
            timer = null;
        }

        public void Dispose()
        {
            Cancel();
        }
    }

    internal static class NativeMouse
    {
        private const uint InputMouse = 0;
        private const uint MouseMove = 0x0001;
        private const uint MouseLeftDown = 0x0002;
        private const uint MouseLeftUp = 0x0004;
        private const uint MouseVirtualDesk = 0x4000;
        private const uint MouseAbsolute = 0x8000;
        private const int SmXVirtualScreen = 76;
        private const int SmYVirtualScreen = 77;
        private const int SmCxVirtualScreen = 78;
        private const int SmCyVirtualScreen = 79;

        [StructLayout(LayoutKind.Sequential)]
        private struct NativePoint
        {
            internal int x;
            internal int y;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct Input
        {
            internal uint type;
            internal MouseInput mi;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MouseInput
        {
            internal int dx;
            internal int dy;
            internal uint mouseData;
            internal uint dwFlags;
            internal uint time;
            internal IntPtr dwExtraInfo;
        }

        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint numberOfInputs, Input[] inputs, int sizeOfInputStructure);

        [DllImport("user32.dll")]
        private static extern int GetSystemMetrics(int index);

        [DllImport("user32.dll")]
        private static extern IntPtr MonitorFromPoint(NativePoint point, uint flags);

        internal static bool IsPointOnActiveMonitor(Point point)
        {
            return MonitorFromPoint(new NativePoint { x = point.X, y = point.Y }, 0) != IntPtr.Zero;
        }

        internal static void Click(Point point, ClickKind clickKind)
        {
            int left = GetSystemMetrics(SmXVirtualScreen);
            int top = GetSystemMetrics(SmYVirtualScreen);
            int width = GetSystemMetrics(SmCxVirtualScreen);
            int height = GetSystemMetrics(SmCyVirtualScreen);
            if (width <= 1 || height <= 1) throw new InvalidOperationException("Windows 回報的螢幕範圍無效。 ");

            int absoluteX = (int)Math.Round((point.X - left) * 65535.0 / (width - 1));
            int absoluteY = (int)Math.Round((point.Y - top) * 65535.0 / (height - 1));
            int inputCount = clickKind == ClickKind.Double ? 5 : 3;
            var inputs = new Input[inputCount];
            inputs[0] = new Input { type = InputMouse, mi = new MouseInput { dx = absoluteX, dy = absoluteY, dwFlags = MouseMove | MouseAbsolute | MouseVirtualDesk } };
            inputs[1] = new Input { type = InputMouse, mi = new MouseInput { dwFlags = MouseLeftDown } };
            inputs[2] = new Input { type = InputMouse, mi = new MouseInput { dwFlags = MouseLeftUp } };
            if (clickKind == ClickKind.Double)
            {
                inputs[3] = new Input { type = InputMouse, mi = new MouseInput { dwFlags = MouseLeftDown } };
                inputs[4] = new Input { type = InputMouse, mi = new MouseInput { dwFlags = MouseLeftUp } };
            }

            uint sent = SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(Input)));
            if (sent != inputs.Length)
                throw new InvalidOperationException("Windows 無法送出滑鼠輸入。錯誤碼：" + Marshal.GetLastWin32Error());
        }
    }
}
