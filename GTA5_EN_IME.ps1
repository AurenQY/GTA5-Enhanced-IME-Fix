# GTA5 Enhanced 启动期间强制英文输入法, 游戏完全启动后解除
param(
    [int]$GraceSeconds   = 8,     # 游戏主窗口出现后, 再继续锁定多少秒
    [int]$TimeoutSeconds = 600,   # 总超时, 防止脚本一直驻留
    [string[]]$GameProcesses = @('GTA5_Enhanced', 'GTA5'),   # 真正的游戏进程名 (不带 .exe)
    [int]$PreferLang = 0         # 优先的英语布局语言 ID (0=自动选已安装的第一个英语布局; 0x0C09=en-AU, 0x0409=en-US)
)

$log = Join-Path $env:TEMP 'gta5_ime.log'
function Log($m) { "$(Get-Date -Format 'HH:mm:ss') $m" | Out-File -FilePath $log -Append -Encoding utf8 }
"" | Out-File $log -Encoding utf8

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class ImeLock {
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] static extern IntPtr GetKeyboardLayout(uint tid);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr LoadKeyboardLayout(string id, uint flags);
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] static extern int GetKeyboardLayoutList(int n, IntPtr[] list);

    const uint WM_INPUTLANGCHANGEREQUEST = 0x0050;
    static IntPtr hklEn = IntPtr.Zero;

    // 语言 ID 低 10 位 = 主语言, 0x09 = 英语 (en-US 0x0409, en-AU 0x0C09, en-GB 0x0809 ...)
    static bool IsEnglish(IntPtr hkl) { return (hkl.ToInt64() & 0x3FF) == 0x09; }

    // 在已安装布局里找英语布局, 优先 preferLang (默认 en-AU 0x0C09); 找不到再加载 en-US
    static IntPtr FindEnglish(int preferLang) {
        int n = GetKeyboardLayoutList(0, null);
        IntPtr[] list = new IntPtr[n];
        GetKeyboardLayoutList(n, list);
        IntPtr any = IntPtr.Zero;
        foreach (IntPtr h in list) {
            if (!IsEnglish(h)) continue;
            if ((h.ToInt64() & 0xFFFF) == preferLang) return h;
            if (any == IntPtr.Zero) any = h;
        }
        return any != IntPtr.Zero ? any : LoadKeyboardLayout("00000409", 0);
    }

    public static string TargetInfo() { return "0x" + hklEn.ToInt64().ToString("X8"); }

    // 把前台窗口的输入语言切到英语布局; 已经是任意英语布局则不动. 返回是否发生了切换
    public static bool ForceEnglish(int preferLang) {
        if (hklEn == IntPtr.Zero) hklEn = FindEnglish(preferLang);
        IntPtr fg = GetForegroundWindow();
        if (fg == IntPtr.Zero) return false;
        uint pid;
        uint tid = GetWindowThreadProcessId(fg, out pid);
        if (IsEnglish(GetKeyboardLayout(tid))) return false;
        // wParam = INPUTLANGCHANGE_SYSCHARSET(1): 与微软文档/ReactOS 的用法一致, lParam = 英文布局 HKL
        PostMessage(fg, WM_INPUTLANGCHANGEREQUEST, new IntPtr(1), hklEn);
        return true;
    }
}
"@

function Get-GameWindowProc {
    foreach ($n in $GameProcesses) {
        $p = Get-Process -Name $n -ErrorAction SilentlyContinue |
             Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -ne '' } |
             Select-Object -First 1
        if ($p) { return $p }
    }
    return $null
}

$start = Get-Date
$gameSeen = $null      # 游戏主窗口首次出现的时间
[void][ImeLock]::ForceEnglish($PreferLang)
Log "start, grace=$GraceSeconds timeout=$TimeoutSeconds target HKL=$([ImeLock]::TargetInfo())"

while ($true) {
    if (((Get-Date) - $start).TotalSeconds -gt $TimeoutSeconds) { Log 'timeout, exit'; break }

    if ([ImeLock]::ForceEnglish($PreferLang)) { Log 'switched foreground window to English' }

    $proc = Get-GameWindowProc
    if ($proc -and -not $gameSeen) {
        $gameSeen = Get-Date
        Log "game window found: $($proc.ProcessName) '$($proc.MainWindowTitle)', grace period begins"
    }
    if ($gameSeen) {
        if (((Get-Date) - $gameSeen).TotalSeconds -ge $GraceSeconds) {
            [void][ImeLock]::ForceEnglish($PreferLang)   # 最后一次保证进游戏时是英文
            Log 'game fully started, lock released, exit'
            break
        }
        # 游戏窗口出现后又被关掉, 直接退出
        if (-not (Get-GameWindowProc)) { Log 'game closed early, exit'; break }
    }
    Start-Sleep -Milliseconds 200
}
