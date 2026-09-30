param(
    [Parameter(Mandatory=$true)][ValidateSet('game_audio_test','guard_opening_test','scenery_016_test','solo_robot_test')][string]$TestName,
    [int]$TimeoutSeconds=20,
    [string]$GodotPath='C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$runId=(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+$TestName
$outputPath=Join-Path $repoRoot "_bmad-output/implementation-artifacts/cenarios-gerador/regressions/$runId"
New-Item -ItemType Directory -Force $outputPath | Out-Null
function Snapshot {
    $files = @(Get-ChildItem (Join-Path $repoRoot 'scripts') -Filter '*.gd' -Recurse) + @(Get-Item (Join-Path $repoRoot "tests/$TestName.gd")) + @(Get-Item (Join-Path $repoRoot 'project.godot'))
    if ($TestName -eq 'game_audio_test') { $files += @(Get-ChildItem (Join-Path $repoRoot 'assets/audio') -File -Recurse) }
    $hashes = [ordered]@{}
    foreach ($file in ($files | Sort-Object FullName)) { $hashes[$file.FullName.Substring($repoRoot.Length+1)] = (Get-FileHash -LiteralPath $file.FullName).Hash }
    return $hashes
}
$headBefore=(git -C $repoRoot rev-parse HEAD)
$before=Snapshot
$stdout=Join-Path $outputPath 'stdout.log'
$stderr=Join-Path $outputPath 'stderr.log'
$arguments=@('--headless','--path',('"'+$repoRoot+'"'),'--script',('tests/'+$TestName+'.gd'))
$process=Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$finished=$process.WaitForExit($TimeoutSeconds*1000)
if (-not $finished) { Stop-Process -Id $process.Id -Force; $process.WaitForExit() }
$after=Snapshot
$headAfter=(git -C $repoRoot rev-parse HEAD)
$changed=@($before.Keys | Where-Object { $before[$_] -ne $after[$_] })
[ordered]@{test=$TestName;timeout_seconds=$TimeoutSeconds;finished=$finished;exit_code=$process.ExitCode;head_before=$headBefore;head_after=$headAfter;changed_paths=$changed;hashes_before=$before;hashes_after=$after} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $outputPath 'provenance.json')
[pscustomobject]@{run=$runId;finished=$finished;exit_code=$process.ExitCode;changed_paths=($changed -join ',')} | ConvertTo-Json
