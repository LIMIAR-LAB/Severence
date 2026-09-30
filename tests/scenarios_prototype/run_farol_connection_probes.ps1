param([string]$GodotPath='C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe')
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$runId=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$evidence=Join-Path $repoRoot "_bmad-output/implementation-artifacts/cenarios-gerador/farol-connection/$runId"
New-Item -ItemType Directory -Force $evidence | Out-Null
$source=Join-Path $repoRoot 'scripts/scenarios/farol_module.gd'
$before=(Get-FileHash $source).Hash
$cases=@('valid','missing_normal','string_normal','zero_normals','diagonal_normals','zero_width','negative_width','string_width','infinite_height','string_height','empty_type','empty_material','missing_width','mismatch_width','mismatch_height','mismatch_type','mismatch_material','same_normal')
$results=foreach($caseId in $cases){
    $log=& $GodotPath --headless --path $repoRoot --quit-after 2 --script (Join-Path $PSScriptRoot 'farol_connection_probe.gd') -- $caseId 2>&1 | Out-String
    $log | Set-Content (Join-Path $evidence "$caseId.log")
    $matchResult=[regex]::Match($log,'(?m)^PROBE_RESULT (.+)$')
    $result=if($matchResult.Success){$matchResult.Groups[1].Value|ConvertFrom-Json}else{$null}
    [pscustomobject]@{case=$caseId;script_error=($log -match 'SCRIPT ERROR|Parse Error');result_present=$matchResult.Success;accepted=if($result){$result.accepted}else{$null};error=if($result){$result.error}else{''}}
}
$after=(Get-FileHash $source).Hash
@{source_before=$before;source_after=$after;results=@($results)}|ConvertTo-Json -Depth 5|Set-Content (Join-Path $evidence 'results.json')
$results|Format-Table case,script_error,accepted,error
Write-Output $runId
