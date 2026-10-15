using System;
using System.Drawing;
using System.Reflection;
using System.Windows.Forms;
using ScheduledClicker;

internal static class DateInputTests
{
    private static int checks;
    private static T Field<T>(object value,string key) { return (T)value.GetType().GetField(key,BindingFlags.NonPublic|BindingFlags.Instance).GetValue(value); }
    private static void Check(bool value,string text) { checks++;if(!value)throw new Exception(text); }
    private static void Call(object value,string method,params object[] args) { value.GetType().GetMethod(method,BindingFlags.NonPublic|BindingFlags.Instance).Invoke(value,args); }
    private static void Respond(MainForm shell,string title,DialogResult result,Action action)
    {
        bool seen=false;string actual=null;
        using(var timer=new Timer {Interval=30}) {
            timer.Tick+=delegate { Form dialog=null;foreach(Form f in Application.OpenForms)if(f!=shell){dialog=f;break;}if(dialog==null)return;timer.Stop();seen=true;actual=dialog.Text;dialog.DialogResult=result; };
            timer.Start();action();
        }
        Check(seen && actual==L.T(title),"Unexpected date validation/confirmation dialog: "+actual);
    }
    [STAThread] private static void Main()
    {
        try {
            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.ThrowException);Application.EnableVisualStyles();L.Select("en");
            using(var shell=new MainForm()) {
                shell.Opacity=0;shell.ShowInTaskbar=false;shell.Show();Application.DoEvents();
                var date=Field<DateTimeField>(shell,"targetTime");var editor=Field<TextBox>(date,"editor");DateTime parsed;
                editor.Text="2026/02/30 10:00:00";Check(!date.TryGetValue(out parsed),"Impossible day accepted");
                bool rejected=false;try{var unused=date.Value;}catch(InvalidOperationException){rejected=true;}Check(rejected,"Invalid getter silently used old date");
                Ui.Select(!Ui.Dark);Check(editor.Text=="2026/02/30 10:00:00","Theme rewrote invalid input");
                editor.Text="2028/02/29 23:59:59";Check(date.TryGetValue(out parsed),"Leap day rejected");editor.Select(18,0);date.Nudge(1);Check(date.Value==new DateTime(2028,3,1,0,0,0),"Second rollover failed");
                date.Value=new DateTime(2028,2,29,12,30,0);editor.Select(0,0);date.Nudge(1);Check(date.Value==new DateTime(2029,2,28,12,30,0),"Leap-year adjustment failed");
                date.Value=new DateTime(2026,1,31,12,30,0);editor.Select(5,0);date.Nudge(1);Check(date.Value==new DateTime(2026,2,28,12,30,0),"Month-end adjustment failed");
                date.Value=new DateTime(2026,1,31,12,30,0);editor.Select(12,0);date.Nudge(1);Check(date.Value.Hour==13 && date.Value.Minute==30,"Hour digit adjusted wrong segment");
                editor.Select(15,0);date.Nudge(-1);Check(date.Value.Hour==13 && date.Value.Minute==29,"Minute digit adjusted wrong segment");
                Check(editor.AccessibleName==L.T("指定時間"),"Date editor has no accessible label");
                editor.Text="bad date";date.Nudge(1);Check(editor.Text=="bad date","Spinner silently corrected invalid input");
                typeof(MainForm).GetField("capturedPoint",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(shell,(Point?)new Point(100,100));
                Respond(shell,"時間無效",DialogResult.OK,delegate {Call(shell,"ArmSchedule",null,EventArgs.Empty);});
                var service=Field<ScheduleService>(shell,"schedule");Check(!service.IsArmed,"Invalid date armed simple schedule");
                date.Value=DateTime.Now.AddHours(2);DateTime expected=date.Value;
                Respond(shell,"確認排程",DialogResult.OK,delegate {Call(shell,"ArmSchedule",null,EventArgs.Empty);});
                Check(service.IsArmed,"Valid date did not arm");
                var plan=Field<Label>(shell,"statusLabel").Tag as ClickPlan;Check(plan!=null && plan.TargetTime==expected,"Typed date changed before scheduling");
                Ui.Select(!Ui.Dark);Check(ReferenceEquals(Field<Label>(shell,"statusLabel").Tag,plan) && service.IsArmed,"Appearance lost active plan");
                Call(shell,"CancelSchedule","排程已取消。",false);Check(!service.IsArmed,"Test schedule did not cancel");
                shell.SwitchMode(true);var loop=Field<LoopForm>(shell,"loopForm");
                Field<TextBox>(Field<DateTimeField>(loop,"first"),"editor").Text="2026/13/01 10:00:00";
                Respond(shell,"無法啟動",DialogResult.OK,delegate {Call(loop,"Arm",false);});
                Check(!Field<LoopEngine>(loop,"engine").Active,"Invalid date armed loop");shell.Close();
            }
            Console.WriteLine("PASS: "+checks+" date input/rollover/validation/schedule-preservation checks; future fixture schedule cancelled before execution.");
        } catch(Exception e) { Console.WriteLine("FAIL: "+e);Environment.ExitCode=1; }
    }
}
