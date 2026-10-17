<div align="right">

[English](README.md) · **[简体中文](README.zh-CN.md)**

</div>

# jw-monitor

一个监测选课状态、在有位置放出时报告的 PowerShell 脚本。

<sub>PowerShell · 单脚本</sub>

---

## 做什么

按间隔轮询选课页面，发现变化就报告——原本满的课现在有位置了。

```
monitor.ps1      轮询、比对、通知
```

## 运行

```powershell
.\monitor.ps1
```

改脚本顶部的课程标识，改成你要盯的那门。

## 说明

是针对某个具体的选课系统写的。解析依赖那个页面的结构，页面一改就需要跟着调整。

## 许可证

MIT
