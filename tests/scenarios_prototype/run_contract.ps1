param([string]$GodotPath = 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$evidencePath = Join-Path $repoRoot '_bmad-output/implementation-artifacts/cenarios-gerador'
foreach ($name in @('contract-adapter-tests.json', 'contract-adapter-process-2.json')) {
    $reportPath = Join-Path $evidencePath $name
    & $GodotPath --headless --path $repoRoot --script (Join-Path $PSScriptRoot 'contract_adapter_test.gd') -- "--report=$reportPath"
    if ($LASTEXITCODE -ne 0) { throw "Adapter test failed: $name" }
}
$first = Get-Content (Join-Path $evidencePath 'contract-adapter-tests.json') -Raw | ConvertFrom-Json
$second = Get-Content (Join-Path $evidencePath 'contract-adapter-process-2.json') -Raw | ConvertFrom-Json
if ($first.engine -ne $second.engine -or $first.adapter -ne $second.adapter -or $first.contract -ne $second.contract -or $first.corpus_hash -ne $second.corpus_hash -or $first.failures.Count -ne 0 -or $second.failures.Count -ne 0) { throw 'Contract adapter cross-process mismatch/failure' }
Write-Output 'PASS: contract binding repeatable across two processes.'
