# Memory watchdog for parity recordings and probe runs (2026-11-12, after two
# hard lock-ups: a probe copy with a parse error made four headless Godot runs
# allocate until Windows ran out of virtual memory; docs/HANDOFF.md).
#
# usage: powershell -NoProfile -ExecutionPolicy Bypass -File tools/parity/watchdog.ps1 <stop file> [max GB per process] [min free GB]
#
# Every 2 s, while <stop file> does not exist: any Godot process whose command
# line runs from a project copy under tools\parity\out\_* is killed when its
# private memory exceeds the limit (default 3 GB); when the system's free
# physical memory falls below the minimum (default 1.0 GB) the largest such
# process is killed. Only those processes are touched (never the editor or a
# game the user started). Each kill is logged to tools/parity/out/watchdog.log.
param([string]$StopFile, [double]$MaxGB = 3.0, [double]$MinFreeGB = 1.0)
$out = Join-Path $PSScriptRoot "out"
New-Item -ItemType Directory -Force $out | Out-Null
$log = Join-Path $out "watchdog.log"
function Log($msg) { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $msg) }
Log "start (max $MaxGB GB per process, min free $MinFreeGB GB, stop file $StopFile)"
while (-not (Test-Path $StopFile)) {
	$procs = Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" |
		Where-Object { $_.CommandLine -match 'tools[\\/]parity[\\/]out[\\/]_' }
	$mine = @()
	foreach ($p in $procs) {
		$gp = Get-Process -Id $p.ProcessId -ErrorAction SilentlyContinue
		if ($null -eq $gp) { continue }
		$gb = $gp.PrivateMemorySize64 / 1GB
		$mine += [pscustomobject]@{ Id = $p.ProcessId; GB = $gb; Cmd = $p.CommandLine }
		if ($gb -gt $MaxGB) {
			Log ("kill {0}: {1:N2} GB private: {2}" -f $p.ProcessId, $gb, $p.CommandLine)
			Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
		}
	}
	$free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
	if ($free -lt $MinFreeGB -and $mine.Count -gt 0) {
		$top = $mine | Sort-Object GB -Descending | Select-Object -First 1
		Log ("low memory ({0:N2} GB free): kill {1} ({2:N2} GB): {3}" -f $free, $top.Id, $top.GB, $top.Cmd)
		Stop-Process -Id $top.Id -Force -ErrorAction SilentlyContinue
	}
	Start-Sleep -Seconds 2
}
Log "stop"
