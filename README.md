# GTA5 Enhanced 中文输入法 Bug 修复 / GTA V Enhanced Chinese IME Fix

用 Steam 启动 **Grand Theft Auto V Enhanced(GTA5 增强版)** 时,自动把输入法锁定为英文,等游戏完全启动后再解除。
这样进游戏时始终是英文输入法,避开简体中文输入法导致的按键/交互异常。

> English: A tiny Steam launch-option script that forces the English keyboard layout while GTA V Enhanced is starting, then releases it once the game is up, avoiding the Simplified Chinese IME input bug. [Jump to English](#english)

- 纯系统自带组件(PowerShell + VBScript),不需要安装任何软件,不需要管理员权限
- 不修改系统设置、不修改游戏文件、不注入游戏进程
- 取消方法:清空 Steam 启动选项即可,一切恢复原样

## 使用方法(约 2 分钟)

**第 1 步:下载并放好文件**

1. 到 [Releases](../../releases/latest) 下载 `GTA5-Enhanced-IME-Fix.zip`,解压。
2. 把解压出来的两个文件放到一个**路径不含空格、最好不含中文**的固定位置,例如:

   ```
   C:\GTA5-IME-Fix\
   ├─ GTA5_EN_IME.vbs
   └─ GTA5_EN_IME.ps1
   ```

   两个文件必须在同一个文件夹里,放好后不要再移动。

**第 2 步:确认系统有英语键盘**

打开 设置 → 时间和语言 → 语言和区域,确认有任意一种英语(如 English (United States) / English (Australia))及其键盘。没有就点"添加语言"添加。

**第 3 步:设置 Steam 启动选项**

1. Steam 库 → 右键 *Grand Theft Auto V Enhanced* → 属性 → 通用 → 启动选项。
2. 粘贴下面这一行(把路径改成你实际放的位置),其余原样保留:

   ```
   C:\Windows\System32\wscript.exe "C:\GTA5-IME-Fix\GTA5_EN_IME.vbs" %command%
   ```

**第 4 步:正常从 Steam 启动游戏**

不用手动运行任何东西。启动期间会锁定英文输入法,游戏窗口出现约 8 秒后自动解除,之后你可以自由切换输入法。

## 注意事项

- **`wscript.exe` 必须写完整路径** `C:\Windows\System32\wscript.exe`,只写 `wscript.exe` 会报 `Missing game executable`。
- **`%command%` 必须原样保留**,它代表 Steam 原本要启动的游戏。
- 启动期间你在别的窗口(浏览器、聊天软件)里打中文也会被切回英文,游戏启动完就恢复正常。
- 如果进游戏后输入法又变回中文,把 `GTA5_EN_IME.ps1` 第 3 行的 `$GraceSeconds = 8` 调大(例如 20)。
- 如果原来的启动选项里已有别的参数,把它们放在 `%command%` 后面,例如:`... "C:\GTA5-IME-Fix\GTA5_EN_IME.vbs" %command% -fullscreen`。
- 防病毒软件如果拦截 `.vbs`,请放行该文件夹;脚本只有两个文本文件,可自行打开检查。
- 取消:清空启动选项即可,不需要卸载任何东西。

## 排查

脚本每次运行会写日志到 `%TEMP%\gta5_ime.log`(资源管理器地址栏粘贴该路径即可打开):

| 日志内容 | 含义 |
| --- | --- |
| `start ... target HKL=0x...` | 脚本已启动,并找到了英语键盘布局 |
| `switched foreground window to English` | 发生过一次切换 |
| `game window found` | 检测到游戏窗口,开始倒计时 |
| `lock released, exit` | 已解除锁定,脚本退出 |

没有 `game window found`:游戏进程名可能不是 `GTA5_Enhanced`,请在任务管理器里确认,并修改 `GTA5_EN_IME.ps1` 里的 `$GameProcesses`。

## 原理

GTA5 启动过程中会干扰输入法状态,简体中文输入法会拦截按键。脚本在启动期间每 200ms 检查前台窗口,如果输入语言不是英语,就向它发送 [`WM_INPUTLANGCHANGEREQUEST`](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-inputlangchangerequest) 消息切到已安装的英语布局;检测到游戏主窗口并等待几秒后,脚本退出,不再干预。

Steam 启动选项通过 `wscript.exe` 运行 VBS:VBS 在后台隐藏运行 PowerShell 监视脚本(没有黑窗口),并在前台启动游戏、等待其退出,Steam 因此能正确显示游戏运行状态。

## 给 AI Agent / 自动化的说明

- 无需安装,只有两个文件:`GTA5_EN_IME.vbs`(入口)、`GTA5_EN_IME.ps1`(逻辑)。
- Steam AppID:`3240220`;游戏进程:`GTA5_Enhanced.exe`。
- 设置方法就是写入该 AppID 的启动选项:`C:\Windows\System32\wscript.exe "<vbs 绝对路径>" %command%`。修改 `localconfig.vdf` 前必须先完全退出 Steam,否则会被 Steam 覆盖;更稳妥的做法是让用户在 Steam 界面手动粘贴。
- 参数(写在 `.ps1` 的 `param` 里):`GraceSeconds`、`TimeoutSeconds`、`GameProcesses`、`PreferLang`(0 = 自动)。

## English

**What it does:** while GTA V Enhanced launches from Steam, the script keeps the foreground window on an English keyboard layout, then stops 8 seconds after the game window appears. No install, no admin rights, no game files touched.

**Setup**

1. Download the zip from [Releases](../../releases/latest) and put `GTA5_EN_IME.vbs` and `GTA5_EN_IME.ps1` together in a fixed folder with a simple path, e.g. `C:\GTA5-IME-Fix\`.
2. Make sure an English keyboard is installed (Settings → Time & language → Language & region).
3. In Steam: right-click the game → Properties → General → Launch Options, paste (adjust the path):

   ```
   C:\Windows\System32\wscript.exe "C:\GTA5-IME-Fix\GTA5_EN_IME.vbs" %command%
   ```

4. Launch the game from Steam as usual.

**Notes:** use the full `C:\Windows\System32\wscript.exe` path (otherwise Steam shows "Missing game executable"); keep `%command%` as is; to undo, clear the launch options. Logs: `%TEMP%\gta5_ime.log`. Increase `$GraceSeconds` in the `.ps1` if the IME flips back after the game loads.

## License

[MIT](LICENSE)
