// Runloc's small Windows-only containment adapter. No EzVM product code is embedded.
// The child cannot execute until assignment to this exact kill-on-close Job succeeds.
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using Microsoft.Win32.SafeHandles;

namespace RunlocPoc
{
    public sealed class CapturedLine
    {
        public string Channel;
        public string Text;
        public string Utc;
        public double Seconds;
    }

    public sealed class OwnedProcess : IDisposable
    {
        [StructLayout(LayoutKind.Sequential)] struct SecurityAttributes
        { public int Length; public IntPtr Descriptor; public int Inherit; }
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct StartupInfo
        {
            public int Size; public string Reserved; public string Desktop; public string Title;
            public int X, Y, XSize, YSize, XChars, YChars, Fill, Flags;
            public short Show, ReservedLength; public IntPtr ReservedBytes, Input, Output, Error;
        }
        [StructLayout(LayoutKind.Sequential)] struct StartupInfoEx
        { public StartupInfo Start; public IntPtr Attributes; }
        [StructLayout(LayoutKind.Sequential)] struct ProcessInfo
        { public IntPtr Process, Thread; public uint Pid, Tid; }
        [StructLayout(LayoutKind.Sequential)] struct BasicLimits
        {
            public long ProcessTime, JobTime; public uint Flags;
            public UIntPtr Minimum, Maximum; public uint Active;
            public UIntPtr Affinity; public uint Priority, Scheduling;
        }
        [StructLayout(LayoutKind.Sequential)] struct IoCounters
        { public ulong ReadOps, WriteOps, OtherOps, ReadBytes, WriteBytes, OtherBytes; }
        [StructLayout(LayoutKind.Sequential)] struct ExtendedLimits
        {
            public BasicLimits Basic; public IoCounters Io;
            public UIntPtr ProcessMemory, JobMemory, PeakProcess, PeakJob;
        }
        [StructLayout(LayoutKind.Sequential)] struct Accounting
        {
            public long User, Kernel, PeriodUser, PeriodKernel;
            public uint Faults, Total, Active, Terminated;
        }
        [StructLayout(LayoutKind.Sequential)] struct FileInformation
        {
            public uint Attributes; public System.Runtime.InteropServices.ComTypes.FILETIME Created, Accessed, Written;
            public uint Volume, SizeHigh, SizeLow, Links, IndexHigh, IndexLow;
        }
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern IntPtr CreateJobObject(IntPtr attributes, string name);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool CreateDirectory(string path, IntPtr attributes);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool SetInformationJobObject(IntPtr job, int kind, ref ExtendedLimits info, uint size);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool QueryInformationJobObject(IntPtr job, int kind, out Accounting info, uint size, IntPtr returned);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateJobObject(IntPtr job, uint exitCode);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool TerminateProcess(IntPtr process, uint exitCode);
        [DllImport("kernel32.dll", SetLastError = true)] static extern uint ResumeThread(IntPtr thread);
        [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr handle);
        [DllImport("kernel32.dll", SetLastError = true)] static extern uint WaitForSingleObject(IntPtr handle, uint milliseconds);
        [DllImport("kernel32.dll", SetLastError = true)] static extern bool GetExitCodeProcess(IntPtr process, out uint code);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool CreateProcess(string application, StringBuilder command, IntPtr processAttributes,
            IntPtr threadAttributes, bool inheritHandles, uint flags, IntPtr environment, string directory,
            ref StartupInfoEx startup, out ProcessInfo info);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool InitializeProcThreadAttributeList(IntPtr list, int count, uint flags, ref IntPtr size);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool UpdateProcThreadAttribute(IntPtr list, uint flags, IntPtr attribute, IntPtr value,
            IntPtr size, IntPtr previous, IntPtr returned);
        [DllImport("kernel32.dll")] static extern void DeleteProcThreadAttributeList(IntPtr list);
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern SafeFileHandle CreateFile(string path, uint access, uint share, ref SecurityAttributes attributes,
            uint creation, uint flags, IntPtr template);
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool GetFileInformationByHandle(SafeFileHandle file, out FileInformation info);
        [StructLayout(LayoutKind.Sequential)] struct Luid { public uint Low; public int High; }
        [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
        [DllImport("advapi32.dll", SetLastError = true)] static extern bool OpenProcessToken(IntPtr process, uint access, out IntPtr token);
        [DllImport("advapi32.dll", SetLastError = true)]
        static extern bool GetTokenInformation(IntPtr token, int kind, IntPtr information, int length, out int returned);
        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        static extern bool LookupPrivilegeName(string system, ref Luid id, StringBuilder name, ref int length);

        IntPtr job, process;
        AnonymousPipeServerStream stdout, stderr;
        Thread stdoutThread, stderrThread;
        StreamWriter raw;
        readonly object outputLock = new object();
        readonly object lifetimeLock = new object();
        readonly Queue<CapturedLine> pending = new Queue<CapturedLine>();
        readonly Stopwatch clock = Stopwatch.StartNew();
        long bytes;
        readonly long maximumBytes;
        volatile bool overflow, readerFailed;
        public readonly uint ProcessId;
        public readonly string CreatedUtc;
        public readonly string Executable;
        public bool OutputOverflow { get { return overflow; } }
        public bool OutputFailed { get { return readerFailed; } }
        public double ElapsedSeconds { get { return clock.Elapsed.TotalSeconds; } }

        public static string QuoteArgument(string value)
        {
            // Microsoft command-line quoting, including trailing backslashes before a quote.
            StringBuilder result = new StringBuilder("\""); int slashes = 0;
            foreach (char c in value)
            {
                if (c == '\\') { slashes++; continue; }
                if (c == '"') { result.Append('\\', slashes * 2 + 1); result.Append('"'); }
                else { result.Append('\\', slashes); result.Append(c); }
                slashes = 0;
            }
            result.Append('\\', slashes * 2); result.Append('"'); return result.ToString();
        }

        public static uint FileLinkCount(string path)
        {
            SecurityAttributes attributes = new SecurityAttributes();
            attributes.Length = Marshal.SizeOf(typeof(SecurityAttributes));
            // OPEN_REPARSE_POINT: never resolve a link while verifying an owned file.
            using (SafeFileHandle file = CreateFile(path, 0, 1 | 2 | 4, ref attributes, 3, 0x00200000, IntPtr.Zero))
            {
                if (file.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
                FileInformation info;
                if (!GetFileInformationByHandle(file, out info)) throw new Win32Exception(Marshal.GetLastWin32Error());
                return info.Links;
            }
        }

        public static void CreateNewDirectory(string path)
        {
            if (Environment.OSVersion.Platform != PlatformID.Win32NT) throw new PlatformNotSupportedException();
            // An existing path, including a differently-cased name, must not be
            // mistaken for this attempt's newly created empty directory.
            if (!CreateDirectory(Path.GetFullPath(path), IntPtr.Zero)) throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        public static bool CurrentTokenHasPrivilege(string expectedName)
        {
            IntPtr token, information = IntPtr.Zero;
            if (!OpenProcessToken(GetCurrentProcess(), 0x0008, out token)) throw new Win32Exception(Marshal.GetLastWin32Error());
            try
            {
                int length; GetTokenInformation(token, 3, IntPtr.Zero, 0, out length);
                if (length < 4 || length > 65536) throw new InvalidOperationException("Invalid token privilege length.");
                information = Marshal.AllocHGlobal(length);
                if (!GetTokenInformation(token, 3, information, length, out length)) throw new Win32Exception(Marshal.GetLastWin32Error());
                int count = Marshal.ReadInt32(information);
                if (count < 0 || 4 + count * 12 > length) throw new InvalidOperationException("Invalid token privilege count.");
                for (int i = 0; i < count; i++)
                {
                    IntPtr entry = IntPtr.Add(information, 4 + i * 12);
                    Luid id = (Luid)Marshal.PtrToStructure(entry, typeof(Luid));
                    int nameLength = 256; StringBuilder name = new StringBuilder(nameLength);
                    if (!LookupPrivilegeName(null, ref id, name, ref nameLength)) throw new Win32Exception(Marshal.GetLastWin32Error());
                    // Presence is refused even when the privilege is currently disabled.
                    if (String.Equals(name.ToString(), expectedName, StringComparison.Ordinal)) return true;
                }
                return false;
            }
            finally { if (information != IntPtr.Zero) Marshal.FreeHGlobal(information); CloseHandle(token); }
        }

        public static SortedDictionary<string, string> CreateChildEnvironment(string temporary)
        {
            // Deliberately exclude GitHub/admin tokens and arbitrary host environment secrets.
            // Do not inherit PSModulePath: the child PowerShell must construct its
            // own default paths instead of autoloading modules for the parent engine.
            // Defaults include CurrentUser/AllUsers; this is not an inbox-only policy.
            SortedDictionary<string, string> childEnvironment = new SortedDictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (string name in new string[] { "SystemRoot", "SystemDrive", "WINDIR", "COMSPEC", "PATH", "PATHEXT",
                "USERPROFILE", "APPDATA", "LOCALAPPDATA", "ProgramFiles", "ProgramFiles(x86)", "ProgramData",
                "PROCESSOR_ARCHITECTURE", "NUMBER_OF_PROCESSORS" })
            {
                string value = Environment.GetEnvironmentVariable(name);
                if (value != null) childEnvironment[name] = value;
            }
            childEnvironment["TEMP"] = Path.GetFullPath(temporary); childEnvironment["TMP"] = Path.GetFullPath(temporary);
            return childEnvironment;
        }

        public OwnedProcess(string executable, string[] arguments, string directory, string temporary,
            string rawLogPath, long maxBytes)
        {
            if (Environment.OSVersion.Platform != PlatformID.Win32NT) throw new PlatformNotSupportedException();
            if (maxBytes < 1024 || maxBytes > 64 * 1024 * 1024) throw new ArgumentOutOfRangeException("maxBytes");
            maximumBytes = maxBytes;
            Executable = Path.GetFullPath(executable);
            CreatedUtc = DateTime.UtcNow.ToString("o");
            ProcessInfo child = new ProcessInfo();
            IntPtr environment = IntPtr.Zero, attributes = IntPtr.Zero, handles = IntPtr.Zero;
            bool attributesReady = false, assigned = false;
            SafeFileHandle input = null;
            try
            {
                raw = new StreamWriter(new FileStream(rawLogPath, FileMode.CreateNew, FileAccess.Write, FileShare.Read),
                    new UTF8Encoding(false)); raw.AutoFlush = true;
                job = CreateJobObject(IntPtr.Zero, null);
                if (job == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
                ExtendedLimits limits = new ExtendedLimits();
                limits.Basic.Flags = 0x00002000; // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE; no breakaway allowed.
                if (!SetInformationJobObject(job, 9, ref limits, (uint)Marshal.SizeOf(typeof(ExtendedLimits))))
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                stdout = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                stderr = new AnonymousPipeServerStream(PipeDirection.In, HandleInheritability.Inheritable);
                SecurityAttributes sa = new SecurityAttributes(); sa.Length = Marshal.SizeOf(typeof(SecurityAttributes)); sa.Inherit = 1;
                input = CreateFile("NUL", 0x80000000, 1 | 2, ref sa, 3, 0, IntPtr.Zero);
                if (input.IsInvalid) throw new Win32Exception(Marshal.GetLastWin32Error());
                IntPtr size = IntPtr.Zero;
                InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref size);
                attributes = Marshal.AllocHGlobal(size);
                if (!InitializeProcThreadAttributeList(attributes, 1, 0, ref size)) throw new Win32Exception(Marshal.GetLastWin32Error());
                attributesReady = true;
                handles = Marshal.AllocHGlobal(3 * IntPtr.Size);
                Marshal.WriteIntPtr(handles, 0, input.DangerousGetHandle());
                Marshal.WriteIntPtr(handles, IntPtr.Size, stdout.ClientSafePipeHandle.DangerousGetHandle());
                Marshal.WriteIntPtr(handles, 2 * IntPtr.Size, stderr.ClientSafePipeHandle.DangerousGetHandle());
                if (!UpdateProcThreadAttribute(attributes, 0, new IntPtr(0x00020002), handles,
                    new IntPtr(3 * IntPtr.Size), IntPtr.Zero, IntPtr.Zero)) throw new Win32Exception(Marshal.GetLastWin32Error());
                StartupInfoEx startup = new StartupInfoEx();
                startup.Start.Size = Marshal.SizeOf(typeof(StartupInfoEx)); startup.Start.Flags = 0x00000100;
                startup.Start.Input = input.DangerousGetHandle(); startup.Start.Output = stdout.ClientSafePipeHandle.DangerousGetHandle();
                startup.Start.Error = stderr.ClientSafePipeHandle.DangerousGetHandle(); startup.Attributes = attributes;
                SortedDictionary<string, string> childEnvironment = CreateChildEnvironment(temporary);
                StringBuilder block = new StringBuilder();
                foreach (KeyValuePair<string, string> entry in childEnvironment) block.Append(entry.Key).Append('=').Append(entry.Value).Append('\0');
                block.Append('\0'); environment = Marshal.StringToHGlobalUni(block.ToString());
                StringBuilder command = new StringBuilder(QuoteArgument(Executable));
                foreach (string argument in arguments) command.Append(' ').Append(QuoteArgument(argument));
                // SUSPENDED | UNICODE_ENVIRONMENT | EXTENDED_STARTUPINFO_PRESENT | NO_WINDOW.
                if (!CreateProcess(Executable, command, IntPtr.Zero, IntPtr.Zero, true, 0x08080404,
                    environment, Path.GetFullPath(directory), ref startup, out child)) throw new Win32Exception(Marshal.GetLastWin32Error());
                process = child.Process; ProcessId = child.Pid;
                if (!AssignProcessToJobObject(job, process)) throw new Win32Exception(Marshal.GetLastWin32Error());
                assigned = true;
                stdout.DisposeLocalCopyOfClientHandle(); stderr.DisposeLocalCopyOfClientHandle();
                stdoutThread = new Thread(delegate() { Read(stdout, "stdout"); }); stdoutThread.IsBackground = true;
                stderrThread = new Thread(delegate() { Read(stderr, "stderr"); }); stderrThread.IsBackground = true;
                stdoutThread.Start(); stderrThread.Start();
                if (ResumeThread(child.Thread) == UInt32.MaxValue) throw new Win32Exception(Marshal.GetLastWin32Error());
            }
            catch
            {
                // The only pre-assignment termination uses the held CreateProcess handle, while still suspended.
                if (process != IntPtr.Zero) { if (assigned) TerminateJobObject(job, 1223); else TerminateProcess(process, 1223); }
                Dispose(); throw;
            }
            finally
            {
                if (child.Thread != IntPtr.Zero) CloseHandle(child.Thread);
                if (input != null) input.Dispose();
                if (attributesReady) DeleteProcThreadAttributeList(attributes);
                if (attributes != IntPtr.Zero) Marshal.FreeHGlobal(attributes);
                if (handles != IntPtr.Zero) Marshal.FreeHGlobal(handles);
                if (environment != IntPtr.Zero) Marshal.FreeHGlobal(environment);
            }
        }

        void Read(Stream stream, string channel)
        {
            try
            {
                using (StreamReader reader = new StreamReader(stream, new UTF8Encoding(false), true, 4096, true))
                {
                    char[] chunk = new char[4096]; StringBuilder line = new StringBuilder(); int count;
                    while ((count = reader.Read(chunk, 0, chunk.Length)) > 0)
                    {
                        for (int i = 0; i < count; i++)
                        {
                            char c = chunk[i];
                            if (c == '\n') { Emit(channel, line.ToString().TrimEnd('\r')); line.Length = 0; }
                            else if (line.Length < 8192) line.Append(c);
                            else overflow = true;
                        }
                    }
                    if (line.Length > 0) Emit(channel, line.ToString());
                }
            }
            catch (ObjectDisposedException) { }
            catch { readerFailed = true; }
        }

        void Emit(string channel, string value)
        {
            lock (outputLock)
            {
                if (overflow) return;
                string utc = DateTime.UtcNow.ToString("o"); double seconds = clock.Elapsed.TotalSeconds;
                string stored = utc + " " + channel + " " + value;
                long length = Encoding.UTF8.GetByteCount(stored) + 2;
                if (bytes + length > maximumBytes) { overflow = true; return; }
                bytes += length;
                raw.WriteLine(stored);
                pending.Enqueue(new CapturedLine { Channel = channel, Text = value, Utc = utc, Seconds = seconds });
            }
        }

        public CapturedLine[] Drain()
        {
            lock (outputLock) { CapturedLine[] result = pending.ToArray(); pending.Clear(); return result; }
        }
        public bool HasExited { get { return process != IntPtr.Zero && WaitForSingleObject(process, 0) == 0; } }
        public int ExitCode
        {
            get { uint code; if (!HasExited || !GetExitCodeProcess(process, out code)) throw new InvalidOperationException("Child has not exited."); return unchecked((int)code); }
        }
        public uint ActiveProcesses
        {
            get
            {
                lock (lifetimeLock)
                {
                    Accounting info;
                    if (job == IntPtr.Zero || !QueryInformationJobObject(job, 1, out info, (uint)Marshal.SizeOf(typeof(Accounting)), IntPtr.Zero))
                        throw new Win32Exception(Marshal.GetLastWin32Error());
                    return info.Active;
                }
            }
        }
        public void Terminate()
        {
            lock (lifetimeLock)
            {
                if (job == IntPtr.Zero) return;
                if (!TerminateJobObject(job, 124)) throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }
        public bool FinishOutput(int milliseconds)
        {
            Stopwatch wait = Stopwatch.StartNew();
            if (stdoutThread != null && !stdoutThread.Join(Math.Max(0, milliseconds))) return false;
            return stderrThread == null || stderrThread.Join(Math.Max(0, milliseconds - (int)wait.ElapsedMilliseconds));
        }
        public void Dispose()
        {
            // Closing this non-inheritable Job handle terminates only this launched descendant tree.
            lock (lifetimeLock)
            {
                if (job != IntPtr.Zero) { CloseHandle(job); job = IntPtr.Zero; }
                if (process != IntPtr.Zero) { CloseHandle(process); process = IntPtr.Zero; }
            }
            if (stdout != null) { stdout.Dispose(); stdout = null; }
            if (stderr != null) { stderr.Dispose(); stderr = null; }
            FinishOutput(2000);
            lock (outputLock) { if (raw != null) { raw.Dispose(); raw = null; } }
        }
    }
}
