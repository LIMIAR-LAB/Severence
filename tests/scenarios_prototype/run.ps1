param(
    [string]$GodotPath = 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$prototypePath = Join-Path $repoRoot 'tools/scenarios/prototype'
$testPath = Join-Path $PSScriptRoot 'graph_test.gd'
$evidencePath = Join-Path $repoRoot '_bmad-output/implementation-artifacts/cenarios-gerador'
foreach ($name in @('graph-tests.json', 'graph-tests-process-2.json')) {
    $reportPath = Join-Path $evidencePath $name
    & $GodotPath --headless --path $prototypePath --script $testPath -- "--report=$reportPath"
    if ($LASTEXITCODE -ne 0) { throw "Godot graph test failed: $name" }
}
$first = Get-Content (Join-Path $evidencePath 'graph-tests.json') -Raw | ConvertFrom-Json
$second = Get-Content (Join-Path $evidencePath 'graph-tests-process-2.json') -Raw | ConvertFrom-Json
if ($first.engine_version -ne $second.engine_version -or $first.generator_version -ne $second.generator_version) { throw 'Version mismatch' }
if ($first.failures.Count -ne 0 -or $second.failures.Count -ne 0) { throw 'Reported test failures' }
for ($index = 0; $index -lt $first.profiles.Count; $index++) {
    if ($first.profiles[$index].id -ne $second.profiles[$index].id -or $first.profiles[$index].corpus_hash -ne $second.profiles[$index].corpus_hash) { throw 'Cross-process determinism failure' }
}
[ordered]@{ok=$true; engine_version=$first.engine_version; generator_version=$first.generator_version; profiles=$first.profiles.Count; seeds_per_profile=1000; processes=2} | ConvertTo-Json | Set-Content (Join-Path $evidencePath 'cross-process.json')
Write-Output 'PASS: matching canonical corpus hashes across two Godot processes.'
