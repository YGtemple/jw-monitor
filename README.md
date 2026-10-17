<div align="right">

**[English](README.md)** · [简体中文](README.zh-CN.md)

</div>

# jw-monitor

A PowerShell script that watches course registration and reports when a slot opens.

<sub>PowerShell · single script</sub>

---

## What it does

Polls the registration page on an interval and reports a change — a course that was full now has a seat.

```
monitor.ps1      poll, compare, notify
```

## Running

```powershell
.\monitor.ps1
```

Edit the course identifiers at the top of the script to match what you are watching.

## Note

Written against a specific registration system. The parsing depends on that page's structure, so it will need adjusting if the page changes.

## License

MIT
