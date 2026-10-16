# jw-monitor · 教务系统入口恢复监测

> 一句话简介：PowerShell 单文件脚本，低频轮询教务系统入口，检测到恢复即自动开浏览器喊你去抢课。

## 一、解决什么问题

抢课那几分钟，教务系统的登录入口经常打不开——不是挂了，是同时涌入的人太多，服务器间歇性拒绝连接。刷新一次显示「无法访问此网站」，再刷新又通了，然后再刷又挂。

这时候人肉盯着浏览器是最笨的办法：你不可能整晚守在电脑前每隔十几秒点一次刷新，而且真正入口放开的那个瞬间，你大概率正在刷别的页面，等切回来早没了。

这个脚本干的事很简单：**每隔十几秒自动探一次，探到入口活了立刻帮你把登录页打开**。你不用盯，听到浏览器自己弹出来再过去操作即可。

## 二、工作逻辑

### 探测目标

三个入口同时探，任一个恢复即算成功：

| 目标 | 地址 |
|---|---|
| 教务系统 https | `https://jw.shengda.edu.cn:8090/` |
| 教务系统 http | `http://jw.shengda.edu.cn:8090/` |
| 智慧校园门户 | `https://my.shengda.edu.cn/` |

### 判定「恢复」的条件

只看状态码是不够的。入口半死不活的时候也会返回 200（比如返回一个 Nginx 错误页或跳转中的空页），这时候打开浏览器只会看到一片白。所以判定用了**双重条件**：

```powershell
if ($code -match '^(200|301|302|303|307)$') {
    $b = Get-Content $tmp -Raw
    # 状态码 OK 还不够，正文里必须出现登录页特征词
    if ($b -and $b.Length -gt 200 -and $b -match $pat) { $ok = $true }
}
```

特征词表覆盖了国内常见 CAS/SSO 统一身份认证页的 URL 与表单字段特征：

```
login|cas|jwglxt|xtgl|auth|sso|username|password|userlogin|ids|统一身份|账号|登录
```

这里刻意**以英文为主**——`jwglxt`（教务管理系统）、`xtgl`（系统管理）、`sso`、`cas` 这些是系统实际 URL 里的字段，比中文标题稳定得多，也能绕开 PowerShell 在不同代码页下读中文可能出现的编码问题。

### 探测频率

默认每轮间隔约 15 秒，并加上 0–4 秒随机抖动：

```powershell
$gap = $BaseGap + (Get-Random -Minimum 0 -Maximum 5)
Start-Sleep -Seconds $gap
```

随机抖动不是多余的。几十个人同时跑同一个脚本、完全同步的请求节奏，等于自己造了一次小型 DDoS，反而更容易把服务端压住。抖动开一点，请求就分散了。

单次请求本身也有 `-m 8` 超时限制，避免某个入口挂起时把整轮探测卡死。

### 探到之后的动作

```powershell
Log ("[已恢复] " + $t.n + "  code=" + $code + "  URL=" + $t.u)
Set-Content -Path $flag -Value $msg -Encoding UTF8
Start-Process $t.u          # 用默认浏览器直接打开
Start-Sleep -Seconds 2
exit 0
```

同时落两处记录：`monitor.log` 追加时间线，`RECOVERED.txt` 写一条恢复快照。这样隔天回头能查清到底是哪个入口、几点几分恢复的。

## 三、用法

```powershell
# 默认：监测 45 分钟，间隔约 15 秒
powershell -File monitor.ps1

# 自定义时长与间隔
powershell -File monitor.ps1 -Minutes 90 -BaseGap 8
```

| 参数 | 默认 | 说明 |
|---|---|---|
| `-Minutes` | 45 | 最长监测时长（分钟） |
| `-BaseGap` | 15 | 每轮探测的基础间隔（秒） |

跑到设定时长没探到，脚本自行退出并在日志里记一条「期间未检测到入口恢复」。

## 四、实现上的几个细节

**用 `curl.exe` 而不是 `Invoke-WebRequest`**：系统自带的 curl 处理 `-k`（忽略自签证书）、跟随重定向、写文件、取状态码这些事比 PowerShell 原生 cmdlet 稳，也不会被 IE 引擎的兼容性设置干扰。教务系统用自签证书是常态，`-k` 必须开。

**带桌面浏览器 UA**：`-A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'`。有些系统会按 UA 直接拒掉非浏览器请求。

**全程 UTF8 编码写日志**：`Add-Content -Encoding UTF8`，避免中文在默认代码页下变乱码。

**`try/catch` 包住每次请求**：单个入口连不上不该中断整轮探测，`$code = '000'` 兜底。

**日志目录硬编码为脚本所在目录**：`$dir` 直接指向 `D:\豆包产物\教务抢课监测`，日志和快照跟脚本放在一起，换机使用需要改这一行。

## 五、文件结构

```
├── monitor.ps1     # 主脚本（56 行）
├── monitor.log     # 运行时生成的探测时间线
└── RECOVERED.txt   # 探到恢复时生成的快照
```

## 许可证

MIT License
