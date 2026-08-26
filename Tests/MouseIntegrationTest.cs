using System;
using System.Drawing;
using System.Windows.Forms;
using ScheduledClicker;

internal sealed class MouseIntegrationTest : Form
{
    private readonly Button target = new Button();
    private readonly Timer timeout = new Timer();
    private readonly ScheduleService scheduler = new ScheduleService();
    private int clickCount;

    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.Run(new MouseIntegrationTest());
    }

    private MouseIntegrationTest()
    {
        Text = "ScheduledClicker integration test";
        StartPosition = FormStartPosition.CenterScreen;
        TopMost = true;
        ClientSize = new Size(320, 180);
        target.Text = "Safe test target";
        target.Size = new Size(180, 70);
        target.Location = new Point(70, 55);
        target.Click += delegate
        {
            clickCount++;
            if (clickCount == 1)
            {
                Console.WriteLine("PASS: native single click reached test button");
                Point center = target.PointToScreen(new Point(target.Width / 2, target.Height / 2));
                scheduler.Arm(new ClickPlan(DateTime.Now.AddMilliseconds(400), center, ClickKind.Double));
            }
            else if (clickCount == 3)
            {
                Console.WriteLine("PASS: native double click produced two clicks");
                timeout.Stop();
                scheduler.Dispose();
                Environment.ExitCode = 0;
                Close();
            }
        };
        Controls.Add(target);

        scheduler.Executed += delegate(ClickPlan plan)
        {
            Console.WriteLine("INFO: Windows SendInput accepted " + plan.ClickKind.ToString() + " click input");
        };
        scheduler.Failed += delegate(Exception error)
        {
            Console.WriteLine("FAIL: Windows input API returned an error: " + error.Message);
        };

        timeout.Interval = 5000;
        timeout.Tick += delegate
        {
            Console.WriteLine("FAIL: timed out after " + clickCount + " click(s)");
            timeout.Stop();
            scheduler.Dispose();
            Environment.ExitCode = 1;
            Close();
        };

        Shown += delegate
        {
            Activate();
            BringToFront();
            target.Focus();
            Point center = target.PointToScreen(new Point(target.Width / 2, target.Height / 2));
            timeout.Start();
            scheduler.Arm(new ClickPlan(DateTime.Now.AddMilliseconds(400), center, ClickKind.Single));
        };
    }
}
