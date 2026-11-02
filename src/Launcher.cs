using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Text;
using System.Threading;
using System.Windows.Forms;

namespace CodexZhLocalizer
{
    internal static class Program
    {
        [STAThread]
        private static int Main(string[] args)
        {
            string appDir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\');
            string reportPath = GetArgumentValue(args, "--self-test-report");

            if (Array.IndexOf(args, "--self-test") >= 0)
            {
                return RunSelfTest(appDir, reportPath);
            }

            bool createdNew;
            using (Mutex mutex = new Mutex(true, @"Local\CodexZhLocalizer.Gui", out createdNew))
            {
                if (!createdNew)
                {
                    MessageBox.Show(
                        "Codex 中文外挂控制面板已经在运行。",
                        "Codex 中文外挂",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information
                    );
                    return 0;
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new MainForm(appDir));
                GC.KeepAlive(mutex);
            }
            return 0;
        }

        private static int RunSelfTest(string appDir, string reportPath)
        {
            List<string> lines = new List<string>();
            List<string> errors = new List<string>();

            CheckFile(lines, errors, Path.Combine(appDir, "start-localizer.ps1"));
            CheckFile(lines, errors, Path.Combine(appDir, "restore-localizer.ps1"));
            CheckFile(lines, errors, Path.Combine(appDir, "translator.mjs"));
            CheckFile(lines, errors, Path.Combine(appDir, "overlay.js"));
            CheckFile(lines, errors, Path.Combine(appDir, "VERSION"));

            if (FindNodeExecutable() == null)
                errors.Add("node.exe was not found in PATH.");

            try
            {
                using (MainForm form = new MainForm(appDir))
                {
                    form.CreateControl();
                    form.RunSelfTestChecks(errors);
                }
                lines.Add("GUI construction: OK");
            }
            catch (Exception ex)
            {
                errors.Add("GUI construction failed: " + ex.Message);
            }

            RunScriptSelfTest(lines, errors, appDir, "start-localizer.ps1");
            RunScriptSelfTest(lines, errors, appDir, "restore-localizer.ps1");

            lines.Insert(0, errors.Count == 0 ? "STATUS=OK" : "STATUS=FAILED");
            lines.Add("ERROR_COUNT=" + errors.Count);
            lines.AddRange(errors);

            string output = string.Join(Environment.NewLine, lines.ToArray());
            if (!string.IsNullOrWhiteSpace(reportPath))
                File.WriteAllText(reportPath, output, new UTF8Encoding(false));

            return errors.Count == 0 ? 0 : 1;
        }

        private static void RunScriptSelfTest(
            List<string> lines,
            List<string> errors,
            string appDir,
            string scriptName
        )
        {
            try
            {
                string powerShell = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                    @"System32\WindowsPowerShell\v1.0\powershell.exe"
                );
                ProcessStartInfo info = new ProcessStartInfo(powerShell);
                info.Arguments =
                    "-NoProfile -ExecutionPolicy Bypass -File \""
                    + Path.Combine(appDir, scriptName)
                    + "\" -SelfTest";
                info.WorkingDirectory = appDir;
                info.UseShellExecute = false;
                info.CreateNoWindow = true;
                info.RedirectStandardOutput = true;
                info.RedirectStandardError = true;

                using (Process process = Process.Start(info))
                {
                    string stdout = process.StandardOutput.ReadToEnd();
                    string stderr = process.StandardError.ReadToEnd();
                    process.WaitForExit();
                    if (process.ExitCode != 0)
                    {
                        errors.Add(
                            scriptName
                                + " self-test failed: "
                                + (stderr.Length > 0 ? stderr : stdout).Trim()
                        );
                    }
                    else
                    {
                        lines.Add(scriptName + " self-test: OK");
                    }
                }
            }
            catch (Exception ex)
            {
                errors.Add(scriptName + " self-test failed: " + ex.Message);
            }
        }

        private static void CheckFile(List<string> lines, List<string> errors, string path)
        {
            if (File.Exists(path))
                lines.Add("File OK: " + Path.GetFileName(path));
            else
                errors.Add("Missing file: " + path);
        }

        internal static string FindNodeExecutable()
        {
            string path = Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
            foreach (string directory in path.Split(Path.PathSeparator))
            {
                if (string.IsNullOrWhiteSpace(directory))
                    continue;
                string candidate = Path.Combine(directory.Trim(), "node.exe");
                if (File.Exists(candidate))
                    return candidate;
            }
            return null;
        }

        private static string GetArgumentValue(string[] args, string name)
        {
            for (int index = 0; index < args.Length - 1; index++)
            {
                if (string.Equals(args[index], name, StringComparison.OrdinalIgnoreCase))
                    return args[index + 1];
            }
            return null;
        }
    }

    internal sealed class MainForm : Form
    {
        private readonly string appDir;
        private readonly string stateDir;
        private readonly string helperPidFile;
        private readonly string startScript;
        private readonly string restoreScript;
        private readonly string powerShellExe;
        private readonly string version;

        private readonly Label statusDot;
        private readonly Label statusText;
        private readonly Label detailText;
        private readonly TextBox logBox;
        private readonly Button startButton;
        private readonly Button restoreButton;
        private readonly System.Windows.Forms.Timer refreshTimer;

        private Process actionProcess;
        private string actionKind;
        private bool busy;

        internal MainForm(string appDir)
        {
            this.appDir = appDir;
            stateDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "CodexChineseOverlay"
            );
            helperPidFile = Path.Combine(stateDir, "translator.pid");
            startScript = Path.Combine(appDir, "start-localizer.ps1");
            restoreScript = Path.Combine(appDir, "restore-localizer.ps1");
            powerShellExe = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                @"System32\WindowsPowerShell\v1.0\powershell.exe"
            );

            string versionFile = Path.Combine(appDir, "VERSION");
            version = File.Exists(versionFile)
                ? File.ReadAllText(versionFile, Encoding.UTF8).Trim()
                : "未知";

            Text = "Codex 中文外挂";
            ClientSize = new Size(640, 470);
            MinimumSize = new Size(656, 509);
            MaximumSize = new Size(656, 509);
            StartPosition = FormStartPosition.CenterScreen;
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            BackColor = Color.FromArgb(244, 247, 251);
            Font = new Font("Microsoft YaHei UI", 9F);
            try
            {
                Icon = Icon.ExtractAssociatedIcon(powerShellExe);
            }
            catch
            {
            }

            Panel header = new Panel();
            header.Bounds = new Rectangle(0, 0, 640, 96);
            header.BackColor = Color.FromArgb(30, 58, 138);
            Controls.Add(header);

            Label title = new Label();
            title.Text = "Codex 中文外挂";
            title.Font = new Font("Microsoft YaHei UI", 20F, FontStyle.Bold);
            title.ForeColor = Color.White;
            title.AutoSize = true;
            title.Location = new Point(26, 17);
            header.Controls.Add(title);

            Label subtitle = new Label();
            subtitle.Text = "一键切换中文界面，也能随时恢复原界面";
            subtitle.ForeColor = Color.FromArgb(219, 234, 254);
            subtitle.AutoSize = true;
            subtitle.Location = new Point(29, 60);
            header.Controls.Add(subtitle);

            Panel statusPanel = new Panel();
            statusPanel.Bounds = new Rectangle(24, 118, 592, 112);
            statusPanel.BackColor = Color.White;
            Controls.Add(statusPanel);

            statusDot = new Label();
            statusDot.Text = "●";
            statusDot.Font = new Font("Microsoft YaHei UI", 18F);
            statusDot.AutoSize = true;
            statusDot.Location = new Point(20, 23);
            statusPanel.Controls.Add(statusDot);

            statusText = new Label();
            statusText.Text = "正在检测状态...";
            statusText.Font = new Font("Microsoft YaHei UI", 14F, FontStyle.Bold);
            statusText.ForeColor = Color.FromArgb(30, 41, 59);
            statusText.AutoSize = true;
            statusText.Location = new Point(53, 18);
            statusPanel.Controls.Add(statusText);

            detailText = new Label();
            detailText.ForeColor = Color.FromArgb(71, 85, 105);
            detailText.AutoEllipsis = true;
            detailText.Bounds = new Rectangle(56, 61, 515, 24);
            statusPanel.Controls.Add(detailText);

            startButton = CreateActionButton(
                "启动汉化",
                new Point(24, 252),
                Color.FromArgb(37, 99, 235),
                Color.White
            );
            startButton.Click += delegate { StartAction("start"); };
            Controls.Add(startButton);

            restoreButton = CreateActionButton(
                "恢复原界面",
                new Point(330, 252),
                Color.White,
                Color.FromArgb(30, 41, 59)
            );
            restoreButton.FlatAppearance.BorderColor = Color.FromArgb(203, 213, 225);
            restoreButton.Click += delegate { StartAction("restore"); };
            Controls.Add(restoreButton);

            logBox = new TextBox();
            logBox.Bounds = new Rectangle(24, 324, 592, 70);
            logBox.Multiline = true;
            logBox.ReadOnly = true;
            logBox.ScrollBars = ScrollBars.Vertical;
            logBox.BackColor = Color.White;
            logBox.ForeColor = Color.FromArgb(71, 85, 105);
            logBox.BorderStyle = BorderStyle.FixedSingle;
            logBox.Text = "准备就绪。";
            Controls.Add(logBox);

            LinkLabel folderLink = new LinkLabel();
            folderLink.Text = "打开工具目录";
            folderLink.AutoSize = true;
            folderLink.LinkColor = Color.FromArgb(37, 99, 235);
            folderLink.Location = new Point(25, 415);
            folderLink.LinkClicked += delegate
            {
                Process.Start("explorer.exe", "\"" + appDir + "\"");
            };
            Controls.Add(folderLink);

            LinkLabel logLink = new LinkLabel();
            logLink.Text = "查看运行日志";
            logLink.AutoSize = true;
            logLink.LinkColor = Color.FromArgb(37, 99, 235);
            logLink.Location = new Point(131, 415);
            logLink.LinkClicked += delegate
            {
                Directory.CreateDirectory(stateDir);
                Process.Start("explorer.exe", "\"" + stateDir + "\"");
            };
            Controls.Add(logLink);

            Label versionLabel = new Label();
            versionLabel.Text = "v" + version + " · 本机运行";
            versionLabel.AutoSize = true;
            versionLabel.ForeColor = Color.FromArgb(148, 163, 184);
            versionLabel.Location = new Point(514, 415);
            Controls.Add(versionLabel);

            refreshTimer = new System.Windows.Forms.Timer();
            refreshTimer.Interval = 1000;
            refreshTimer.Tick += delegate { UpdateInterface(); };
            refreshTimer.Start();

            Shown += delegate { UpdateInterface(); };
            FormClosed += delegate { refreshTimer.Stop(); };
        }

        private static Button CreateActionButton(
            string text,
            Point location,
            Color backColor,
            Color foreColor
        )
        {
            Button button = new Button();
            button.Text = text;
            button.Bounds = new Rectangle(location, new Size(286, 52));
            button.FlatStyle = FlatStyle.Flat;
            button.FlatAppearance.BorderSize = backColor == Color.White ? 1 : 0;
            button.BackColor = backColor;
            button.ForeColor = foreColor;
            button.Font = new Font("Microsoft YaHei UI", 11F, FontStyle.Bold);
            button.Cursor = Cursors.Hand;
            return button;
        }

        private void StartAction(string kind)
        {
            if (busy)
                return;

            string scriptPath = kind == "start" ? startScript : restoreScript;
            if (!File.Exists(scriptPath))
            {
                ShowError("找不到操作脚本：" + scriptPath);
                return;
            }

            busy = true;
            actionKind = kind;
            logBox.Text = kind == "start"
                ? "正在启动汉化，Codex 将自动重新打开..."
                : "正在恢复原界面，Codex 将自动重新打开...";
            UpdateButtons();

            try
            {
                ProcessStartInfo info = new ProcessStartInfo(powerShellExe);
                info.Arguments =
                    "-NoProfile -ExecutionPolicy Bypass -File \""
                    + scriptPath
                    + "\"";
                info.WorkingDirectory = appDir;
                info.UseShellExecute = false;
                info.CreateNoWindow = true;
                info.RedirectStandardOutput = true;
                info.RedirectStandardError = true;

                actionProcess = new Process();
                actionProcess.StartInfo = info;
                actionProcess.EnableRaisingEvents = true;
                actionProcess.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e)
                {
                    if (!string.IsNullOrWhiteSpace(e.Data))
                        AppendLog(e.Data);
                };
                actionProcess.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e)
                {
                    if (!string.IsNullOrWhiteSpace(e.Data))
                        AppendLog(e.Data);
                };
                actionProcess.Exited += ActionProcessExited;
                actionProcess.Start();
                actionProcess.BeginOutputReadLine();
                actionProcess.BeginErrorReadLine();
            }
            catch (Exception ex)
            {
                busy = false;
                actionKind = null;
                if (actionProcess != null)
                    actionProcess.Dispose();
                actionProcess = null;
                ShowError(ex.Message);
                UpdateInterface();
            }
        }

        private void ActionProcessExited(object sender, EventArgs e)
        {
            Process completed = (Process)sender;
            int exitCode = completed.ExitCode;
            string completedKind = actionKind;

            if (IsDisposed || !IsHandleCreated)
                return;

            BeginInvoke((MethodInvoker)delegate
            {
                busy = false;
                actionKind = null;
                actionProcess.Dispose();
                actionProcess = null;
                if (exitCode == 0)
                {
                    logBox.Text = completedKind == "start"
                        ? "汉化已启动，Codex 已重新打开。"
                        : "已恢复原始界面，Codex 已重新打开。";
                }
                else
                {
                    logBox.Text = "操作失败，退出代码：" + exitCode + "。请查看运行日志。";
                }
                UpdateInterface();
            });
        }

        private void AppendLog(string line)
        {
            if (IsDisposed || !IsHandleCreated)
                return;
            BeginInvoke((MethodInvoker)delegate
            {
                if (logBox.IsDisposed)
                    return;
                logBox.AppendText((logBox.TextLength > 0 ? Environment.NewLine : "") + line);
            });
        }

        private void UpdateInterface()
        {
            bool helperRunning = IsHelperRunning();
            bool codexRunning = Process.GetProcessesByName("ChatGPT").Length > 0;

            if (busy)
            {
                if (actionKind == "start")
                {
                    statusText.Text = "正在启动汉化...";
                    detailText.Text = "正在重新打开 Codex，请稍候。";
                }
                else
                {
                    statusText.Text = "正在恢复原界面...";
                    detailText.Text = "正在停止汉化并重新打开 Codex。";
                }
                statusDot.ForeColor = Color.FromArgb(217, 119, 6);
            }
            else if (helperRunning)
            {
                statusText.Text = "汉化已开启";
                detailText.Text = "辅助进程正在运行，界面文字已应用。";
                statusDot.ForeColor = Color.FromArgb(22, 163, 74);
            }
            else
            {
                statusText.Text = codexRunning ? "当前为原始界面" : "Codex 当前未运行";
                detailText.Text = codexRunning
                    ? "点击“启动汉化”即可切换为中文界面。"
                    : "点击“启动汉化”后，工具会尝试打开 Codex。";
                statusDot.ForeColor = Color.FromArgb(100, 116, 139);
            }

            UpdateButtons();
        }

        private void UpdateButtons()
        {
            startButton.Enabled = !busy && !IsHelperRunning();
            restoreButton.Enabled = !busy;
        }

        private bool IsHelperRunning()
        {
            try
            {
                if (!File.Exists(helperPidFile))
                    return false;
                int pid;
                if (!int.TryParse(File.ReadAllText(helperPidFile).Trim(), out pid))
                    return false;
                using (Process process = Process.GetProcessById(pid))
                    return string.Equals(
                        process.ProcessName,
                        "node",
                        StringComparison.OrdinalIgnoreCase
                    );
            }
            catch
            {
                return false;
            }
        }

        private void ShowError(string message)
        {
            logBox.Text = "操作失败：" + message;
            MessageBox.Show(
                message,
                "Codex 中文外挂",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error
            );
        }

        internal void RunSelfTestChecks(List<string> errors)
        {
            if (startButton == null || !startButton.Enabled)
                errors.Add("Start button was not initialized.");
            if (restoreButton == null || !restoreButton.Enabled)
                errors.Add("Restore button was not initialized.");
            if (logBox == null || statusText == null)
                errors.Add("Core interface controls were not initialized.");
            if (!File.Exists(powerShellExe))
                errors.Add("Windows PowerShell was not found.");
        }
    }
}
