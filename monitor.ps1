param(
  [int]$Minutes = 45,
  [int]$BaseGap = 15
)
# 升达教务系统入口恢复监测：低频轻量探测，检测到入口恢复即自动用默认浏览器打开登录页
$dir  = 'D:\豆包产物\教务抢课监测'
$log  = Join-Path $dir 'monitor.log'
$flag = Join-Path $dir 'RECOVERED.txt'

$targets = @(
  @{ n = '教务系统https'; u = 'https://jw.shengda.edu.cn:8090/' },
  @{ n = '教务系统http';  u = 'http://jw.shengda.edu.cn:8090/' },
  @{ n = '智慧校园门户';  u = 'https://my.shengda.edu.cn/' }
)
# 登录页特征（以英文为主，避免编码问题）
$pat = 'login|cas|jwglxt|xtgl|auth|sso|username|password|userlogin|ids|统一身份|账号|登录'
$end = (Get-Date).AddMinutes($Minutes)

function Log($m) {
  $line = "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m
  Add-Content -Path $log -Value $line -Encoding UTF8
}

Log ("监测开始，最长 {0} 分钟，间隔约 {1} 秒" -f $Minutes, $BaseGap)
while ((Get-Date) -lt $end) {
  foreach ($t in $targets) {
    $tmp = Join-Path $env:TEMP ('jwprobe_' + ($t.n) + '.html')
    $code = '000'
    try {
      $code = (& curl.exe -k -s -L -m 8 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' -o $tmp -w '%{http_code}' $t.u) 2>$null
    } catch { $code = '000' }

    $ok = $false
    if ($code -match '^(200|301|302|303|307)$') {
      try {
        $b = Get-Content $tmp -Raw -ErrorAction SilentlyContinue
        if ($b -and $b.Length -gt 200 -and $b -match $pat) { $ok = $true }
      } catch {}
    }

    if ($ok) {
      Log ("[已恢复] " + $t.n + "  code=" + $code + "  URL=" + $t.u)
      $msg = "教务系统入口已恢复：{0}`r`n恢复时间：{1}`r`n已自动用默认浏览器打开该入口，请立即登录抢课。" -f $t.u, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
      Set-Content -Path $flag -Value $msg -Encoding UTF8
      Start-Process $t.u
      Start-Sleep -Seconds 2
      exit 0
    }
    else {
      Log ("探测 " + $t.n + " -> " + $code)
    }
  }
  $gap = $BaseGap + (Get-Random -Minimum 0 -Maximum 5)
  Start-Sleep -Seconds $gap
}
Log "监测达到设定时长结束，期间未检测到入口恢复。"
