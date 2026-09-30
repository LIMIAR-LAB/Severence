param([string]$GodotPath = 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe', [switch]$Strict)
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$runId = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$evidencePath = Join-Path $repoRoot "_bmad-output/implementation-artifacts/cenarios-gerador/robustness/$runId"
New-Item -ItemType Directory -Force $evidencePath | Out-Null
$cases = @('room_valid','biome_valid','room_footprint_null','room_connector_scalar','room_width_string','room_spawn_missing_position','room_layer_null','room_obstacle_missing_rect','room_connector_empty_id','room_connector_bad_height','room_empty_template_id','room_negative_radius','room_bad_depth','room_point_missing_position','room_ramp_missing_rect','room_raised_scalar','room_origin_infinite','room_origin_nan','biome_materials_null','biome_pool_string','biome_fallback_null','biome_rules_null','biome_roles_scalar','biome_version_string','biome_id_numeric','biome_era_empty','biome_atmosphere_null','biome_negative_width')
$before = @{}
$cases += @('room_pixel_scale_zero','room_pixel_scale_negative','room_version_nan','biome_version_nan','biome_empty_pool','biome_empty_id')
foreach ($source in @('room_contract.gd','biome_catalog.gd')) { $before[$source] = (Get-FileHash (Join-Path $repoRoot "scripts/scenarios/$source")).Hash }
$results = foreach ($caseId in $cases) {
    $log = & $GodotPath --headless --path $repoRoot --quit-after 2 --script (Join-Path $PSScriptRoot 'public_contract_probe.gd') -- $caseId 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    $log | Set-Content (Join-Path $evidencePath "$caseId.log")
    $scriptError = $log -match 'SCRIPT ERROR|Parse Error'
    $matchResult = [regex]::Match($log,'(?m)^PROBE_RESULT (.+)$')
    $observed = if ($matchResult.Success) { $matchResult.Groups[1].Value | ConvertFrom-Json } else { $null }
    [ordered]@{case=$caseId; exit_code=$exitCode; script_error=$scriptError; result_present=$matchResult.Success; accepted=if($null -eq $observed){$null}else{$observed.accepted}; errors=if($null -eq $observed){@()}else{$observed.errors}}
}
$after = @{}
foreach ($source in @('room_contract.gd','biome_catalog.gd')) { $after[$source] = (Get-FileHash (Join-Path $repoRoot "scripts/scenarios/$source")).Hash }
[ordered]@{engine=(& $GodotPath --version | Out-String).Trim();source_hashes_before=$before;source_hashes_after=$after;results=@($results)} | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $evidencePath 'results.json')
$results | ForEach-Object { [pscustomobject]$_ } | Format-Table case,script_error,result_present,accepted
if ($Strict) {
    $violations = @($results | Where-Object { $_.script_error -or -not $_.result_present -or ($_.accepted -ne ($_.case -in @('room_valid','biome_valid'))) })
    if ($violations.Count -gt 0) { Write-Output "FAIL: $($violations.Count) public contract rejection violations"; exit 1 }
}
