// Independent deadlines for the dedicated supervisor process. No PowerShell callback
// or runspace is needed, so a blocked controller or receipt operation cannot pause them.
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;

namespace RunlocPoc
{
    public sealed class SupervisorDeadline : IDisposable
    {
        [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
        [DllImport("kernel32.dll", SetLastError = true)] static extern bool TerminateProcess(IntPtr process, uint exitCode);
        readonly object gate = new object();
        readonly Timer executionTimer, terminalTimer;
        readonly bool terminateSupervisor;
        Action terminateOwnedJob;
        volatile bool disposed, expired, stopFailed, hardWallReached;
        public bool ExecutionExpired { get { return expired; } }
        public bool StopFailed { get { return stopFailed; } }
        public bool HardWallReached { get { return hardWallReached; } }
        public bool TimersEnabled { get { return executionTimer != null; } }

        // Default production uses the fixed 5340/5400-second absolute deadlines.
        // The explicit owner exception constructs no timers via the overload below.
        // Milliseconds and the no-exit mode permit short synthetic native tests.
        public SupervisorDeadline(int executionMilliseconds, int terminalMilliseconds, bool terminateSupervisor)
            : this(executionMilliseconds, terminalMilliseconds, terminateSupervisor, false) { }

        public SupervisorDeadline(int executionMilliseconds, int terminalMilliseconds, bool terminateSupervisor, bool noOverallTimeout)
        {
            this.terminateSupervisor = terminateSupervisor;
            if (noOverallTimeout)
            {
                if (executionMilliseconds != 0 || terminalMilliseconds != 0)
                    throw new ArgumentException("Disabled deadlines require zero timing arguments.");
                return; // No Timer is constructed or armed in this explicit operator mode.
            }
            if (executionMilliseconds < 1 || terminalMilliseconds <= executionMilliseconds)
                throw new ArgumentOutOfRangeException("executionMilliseconds");
            executionTimer = new Timer(ExecutionDeadline, null, executionMilliseconds, Timeout.Infinite);
            terminalTimer = new Timer(TerminalDeadline, null, terminalMilliseconds, Timeout.Infinite);
        }

        public void AttachTermination(Action terminate)
        {
            if (terminate == null) throw new ArgumentNullException("terminate");
            lock (gate)
            {
                if (disposed || terminateOwnedJob != null) throw new InvalidOperationException("Deadline ownership already set or closed.");
                terminateOwnedJob = terminate;
                if (expired) StopOwnedJob();
            }
        }

        public void DetachTermination()
        {
            // The caller detaches before disposing the owned Job. Terminate itself
            // serializes native handle access with OwnedProcess.Dispose.
            lock (gate) { terminateOwnedJob = null; }
        }

        void StopOwnedJob()
        {
            if (terminateOwnedJob == null) return;
            try { terminateOwnedJob(); }
            catch { stopFailed = true; }
        }

        void ExecutionDeadline(object ignored)
        {
            lock (gate)
            {
                if (disposed) return;
                expired = true;
                StopOwnedJob();
            }
        }

        void TerminalDeadline(object ignored)
        {
            // This must not wait for the Job lock or a stuck output/file operation.
            // Exiting this dedicated process closes its non-inherited Job handles.
            if (disposed) return;
            hardWallReached = true;
            if (terminateSupervisor)
            {
                // No managed shutdown handlers, output flush, or process enumeration.
                // Only the already-validated dedicated supervisor can arm this mode.
                TerminateProcess(GetCurrentProcess(), 124);
            }
        }

        public void Dispose()
        {
            lock (gate)
            {
                if (disposed) return;
                disposed = true;
                terminateOwnedJob = null;
                if (executionTimer != null) executionTimer.Dispose();
                if (terminalTimer != null) terminalTimer.Dispose();
            }
        }

        public static bool IsDedicatedFileInvocation(string[] arguments, string expectedScript, string invocationName)
        {
            if (arguments == null || invocationName == "." || String.IsNullOrEmpty(expectedScript)) return false;
            bool noProfile = false, nonInteractive = false;
            for (int i = 1; i < arguments.Length; i++)
            {
                string argument = arguments[i];
                if (String.Equals(argument, "-NoProfile", StringComparison.OrdinalIgnoreCase)) { noProfile = true; continue; }
                if (String.Equals(argument, "-NonInteractive", StringComparison.OrdinalIgnoreCase)) { nonInteractive = true; continue; }
                if (String.Equals(argument, "-NoLogo", StringComparison.OrdinalIgnoreCase)) continue;
                if (String.Equals(argument, "-ExecutionPolicy", StringComparison.OrdinalIgnoreCase))
                {
                    if (++i >= arguments.Length || !String.Equals(arguments[i], "Bypass", StringComparison.OrdinalIgnoreCase)) return false;
                    continue;
                }
                if (!String.Equals(argument, "-File", StringComparison.OrdinalIgnoreCase) || ++i >= arguments.Length) return false;
                try
                {
                    return noProfile && nonInteractive && String.Equals(Path.GetFullPath(arguments[i]), Path.GetFullPath(expectedScript),
                        Environment.OSVersion.Platform == PlatformID.Win32NT ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal);
                }
                catch (ArgumentException) { return false; }
                catch (NotSupportedException) { return false; }
            }
            return false;
        }
    }
}
