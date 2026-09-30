param([string]$GodotPath = 'C:/Users/tsmar/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$benchRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$benchOut = Join-Path $benchRoot '_bmad-output/implementation-artifacts/cenarios-base'
$results = @()
foreach ($test in Get-ChildItem $PSScriptRoot -Filter '*test.gd') {
 $output = & $GodotPath --headless --path $benchRoot --script $test.FullName --quit-after 200 2>&1 | Out-String
 $ok = $LASTEXITCODE -eq 0 -and $output -match 'TESTS_DONE failures=0' -and $output -notmatch 'SCRIPT ERROR|ERROR:'
 $results += [pscustomobject]@{test=$test.Name;ok=$ok;output=$output}
}
$results | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $benchOut 'base-tests.json')
if ($results.ok -contains $false) { throw 'Base test failed; see base-tests.json' }
'PASS: all base test receipts verified'
