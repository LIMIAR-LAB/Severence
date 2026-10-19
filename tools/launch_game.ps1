param(
    [switch]$ResolveOnly,
    [switch]$PreferEngine,
    [switch]$Import,
    [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent)
)
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectRoot).Path
$build = Join-Path $project 'build/Severence.exe'
if (-not $PreferEngine -and -not $Import -and (Test-Path -LiteralPath $build -PathType Leaf)) {
    $target = [pscustomobject]@{ Kind = 'Build'; Executable = $build; Project = $project }
} else {
    if (-not (Test-Path -LiteralPath (Join-Path $project 'project.godot'))) { throw 'project.godot nao encontrado nesta pasta.' }
    $candidates = [Collections.Generic.List[string]]::new()
    if ($env:GODOT_EXE) {
        $configured = $env:GODOT_EXE.Trim('"')
        if (-not (Test-Path -LiteralPath $configured -PathType Leaf)) { throw 'GODOT_EXE aponta para um arquivo inexistente. Corrija a variavel ou remova-a.' }
        $candidates.Add($configured)
    }
    foreach ($name in @('godot', 'godot4', 'godot_console', 'godot4_console')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $candidates.Add($command.Source) }
    }
    foreach ($folder in @($project, (Join-Path $project 'tools'), (Join-Path $project 'bin'), (Join-Path $project 'Godot'), (Join-Path $env:USERPROFILE 'Downloads'))) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        $engines = @(Get-ChildItem -LiteralPath $folder -File -Filter 'Godot*.exe' -ErrorAction SilentlyContinue)
        foreach ($child in (Get-ChildItem -LiteralPath $folder -Directory -Filter 'Godot*' -ErrorAction SilentlyContinue)) {
            $engines += @(Get-ChildItem -LiteralPath $child.FullName -File -Filter 'Godot*.exe' -ErrorAction SilentlyContinue)
        }
        foreach ($engine in ($engines | Sort-Object @{Expression={$_.Name -match '_console'}}, @{Expression={$_.Name}; Descending=$true})) { $candidates.Add($engine.FullName) }
    }
    if ($candidates.Count -eq 0) { throw 'Godot nao encontrado. Defina GODOT_EXE, adicione Godot ao PATH ou abra project.godot no Godot 4.7.2 e pressione F5.' }
    $enginePath = (Resolve-Path -LiteralPath $candidates[0]).Path
    $target = [pscustomobject]@{ Kind = 'Godot'; Executable = $enginePath; Project = $project }
}
if ($ResolveOnly) { return $target }
if ($target.Kind -eq 'Godot' -and ($Import -or -not (Test-Path -LiteralPath (Join-Path $project '.godot/global_script_class_cache.cfg')))) {
    & $target.Executable --headless --path $project --import --quit
    if ($LASTEXITCODE -ne 0) { throw 'A importacao falhou. Abra o projeto no editor para verificar os recursos.' }
}
if ($target.Kind -eq 'Build') {
    Start-Process -FilePath $target.Executable -WorkingDirectory (Split-Path $target.Executable -Parent) -WindowStyle Hidden | Out-Null
} else {
    Start-Process -FilePath $target.Executable -ArgumentList @('--path', ('"' + $project + '"')) -WorkingDirectory $project -WindowStyle Hidden | Out-Null
}
