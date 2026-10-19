param(
    [Parameter(Mandatory = $true)][string]$Godot,
    [string[]]$Scripts = @('tests/profile_network_regression_test.gd'),
    [int]$TimeoutSeconds = 60
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path $PSScriptRoot -Parent
$godotPath = (Resolve-Path -LiteralPath $Godot).Path
$runId = [guid]::NewGuid().ToString('N')
$sandbox = Join-Path $workspace "output/isolated-tests/$runId"
New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
# This project has a unique user directory before any script or autoload starts.
# Junctions reuse imported assets without copying gigabytes or changing the game config.
foreach ($name in @('scripts', 'scenes', 'tests', 'assets', 'art', 'data', 'addons', 'shaders', 'tools', '.godot')) {
    $source = Join-Path $workspace $name
    if (Test-Path -LiteralPath $source) {
        New-Item -ItemType Junction -Path (Join-Path $sandbox $name) -Target $source | Out-Null
    }
}
$config = Get-Content -LiteralPath (Join-Path $workspace 'project.godot') -Raw
$config = $config -replace '(?m)^config/use_custom_user_dir=.*\r?\n', ''
$config = $config -replace '(?m)^config/custom_user_dir_name=.*\r?\n', ''
$config = $config.Replace('[application]', "[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"SeverenceTests/$runId`"")
[IO.File]::WriteAllText((Join-Path $sandbox 'project.godot'), $config, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $sandbox '.gdignore'), '')
$probe = @'
extends SceneTree
func _initialize() -> void:
    var directory := OS.get_user_data_dir().replace("\\", "/")
    if not directory.contains("/SeverenceTests/"):
        push_error("Refusing tests: user directory is not isolated")
        quit(1)
        return
    print("ISOLATED_PROJECT_USER_DATA ", directory)
    quit()
'@
[IO.File]::WriteAllText((Join-Path $sandbox 'verify_isolation.gd'), $probe, [Text.UTF8Encoding]::new($false))
function Invoke-Isolated([string]$script, [string]$label) {
    $stdout = Join-Path $sandbox "$label.stdout.log"
    $stderr = Join-Path $sandbox "$label.stderr.log"
    $arguments = @('--headless', '--path', ('"' + $sandbox + '"'), '--script', ('"res://' + $script + '"'))
    $process = Start-Process -FilePath $godotPath -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        # Stop only this test process and its child; no existing game/editor is touched.
        & taskkill.exe /PID $process.Id /T /F | Out-Null
        Write-Host "$label TIMEOUT (${TimeoutSeconds}s); logs: $sandbox"
        return $false
    }
    $process.Refresh()
    $errors = [string](Get-Content -LiteralPath $stderr -Raw)
    $ok = $process.ExitCode -eq 0 -and $errors -notmatch 'SCRIPT ERROR:|Parse Error:|ERROR:'
    Write-Host "$label exit=$($process.ExitCode) success=$ok"
    Get-Content -LiteralPath $stdout | Where-Object { $_ -match 'ISOLATED|failures=|failures:|checks=|TESTS_DONE' } | ForEach-Object { Write-Host $_ }
    if (-not $ok) { Write-Host $errors }
    return $ok
}
if (-not (Invoke-Isolated 'verify_isolation.gd' 'isolation')) { throw 'Isolation verification failed; tests were not started.' }
$failed = 0
foreach ($script in $Scripts) {
    if ($script -notmatch '^tests/[A-Za-z0-9_/-]+\.gd$' -or $script.Contains('..')) { throw "Invalid test path: $script" }
    $label = [IO.Path]::GetFileNameWithoutExtension($script)
    if (-not (Invoke-Isolated $script $label)) { $failed++ }
}
Write-Host "ISOLATED_TESTS failures=$failed logs=$sandbox"
if ($failed) { exit 1 }
