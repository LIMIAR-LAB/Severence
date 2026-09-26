$ErrorActionPreference = 'Stop'
$testRoot = Split-Path -Parent $PSScriptRoot
$godotTest = 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$outDir = Join-Path $testRoot 'test-output'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$testHost = Start-Process -FilePath $godotTest -ArgumentList '--headless','--path',('"' + $testRoot + '"'),'--','--network-host-test' -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outDir 'network-host.log') -RedirectStandardError (Join-Path $outDir 'network-host-errors.log')
Start-Sleep -Milliseconds 600
$testClient = Start-Process -FilePath $godotTest -ArgumentList '--headless','--path',('"' + $testRoot + '"'),'--','--network-client-test' -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $outDir 'network-client.log') -RedirectStandardError (Join-Path $outDir 'network-client-errors.log')
$hostDone = $testHost.WaitForExit(15000)
$clientDone = $testClient.WaitForExit(15000)
if (-not $hostDone -or -not $clientDone) { throw 'Network test timed out.' }
$hostLog = Get-Content -LiteralPath (Join-Path $outDir 'network-host.log') -Raw
$clientLog = Get-Content -LiteralPath (Join-Path $outDir 'network-client.log') -Raw
$errors = Get-Content -LiteralPath (Join-Path $outDir 'network-host-errors.log'), (Join-Path $outDir 'network-client-errors.log') -Raw
if ($errors -match 'ERROR|WARNING' -or $hostLog -notmatch 'MOVED=true' -or $clientLog -notmatch 'NETWORK_SNAPSHOT') {
    $hostLog
    $clientLog
    $errors | Select-Object -First 2
    throw 'Network integration failed.'
}
$hostLog
$clientLog
'NETWORK INTEGRATION PASS: connection, remote movement, compressed state delivery, no engine errors.'
