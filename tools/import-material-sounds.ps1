param(
    [Parameter(Mandatory = $true)]
    [string]$SourceRoot,

    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'

function Get-SafeSoundName([string]$FileName) {
    $baseName = [IO.Path]::GetFileNameWithoutExtension($FileName).ToLowerInvariant()
    $baseName = [regex]::Replace($baseName, '[^a-z0-9_]', '_')
    $baseName = [regex]::Replace($baseName, '_+', '_').Trim('_')
    if ([string]::IsNullOrWhiteSpace($baseName)) {
        $baseName = 'material_sound'
    }
    if (-not $baseName.StartsWith('snd_')) {
        $baseName = "snd_$baseName"
    }
    return $baseName
}

function Get-AudioFile([string]$ResourceDirectory) {
    return Get-ChildItem -LiteralPath $ResourceDirectory -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -ne '.yy' } |
        Select-Object -First 1
}

function Test-SameFile([string]$Left, [string]$Right) {
    if (-not (Test-Path -LiteralPath $Left) -or -not (Test-Path -LiteralPath $Right)) {
        return $false
    }
    return (Get-FileHash -LiteralPath $Left -Algorithm SHA256).Hash -eq
        (Get-FileHash -LiteralPath $Right -Algorithm SHA256).Hash
}

$sourceRootPath = (Resolve-Path -LiteralPath $SourceRoot).Path
$projectRootPath = (Resolve-Path -LiteralPath $ProjectRoot).Path
$soundsRoot = Join-Path $projectRootPath 'sounds'
$projectFile = Join-Path $projectRootPath 'UNDERTALE Engine Ultra.yyp'
$manifestPath = Join-Path $projectRootPath 'docs\IMPORTED_SOUND_MANIFEST.md'

$supportedExtensions = @('.wav', '.ogg', '.mp3', '.flac', '.m4a', '.aac', '.opus', '.wma')
$allSourceFiles = Get-ChildItem -LiteralPath $sourceRootPath -Recurse -File |
    Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() } |
    Sort-Object FullName

# The editor already exposes every sound resource that exists in the engine.  The
# material pack is therefore only used to fill the combat/bullet-script gaps; UI,
# title, game-over, music, player-attack and full character voice collections are
# deliberately not duplicated here.
$curatedRelativePaths = @(
    '攻击音效\mus_rotate.wav',
    '攻击音效\mus_sfx_a_bullet.wav',
    '攻击音效\mus_sfx_a_gigatalk.wav',
    '攻击音效\mus_sfx_a_lithit.wav',
    '攻击音效\mus_sfx_a_lithit2.wav',
    '攻击音效\mus_sfx_a_pullback.wav',
    '攻击音效\mus_sfx_a_swordappear.wav',
    '攻击音效\mus_sfx_cinematiccut.wav',
    '攻击音效\mus_sfx_spellcast.wav',
    '攻击音效\mus_sfx_star.wav',
    '攻击音效\snd_bomb.wav',
    '攻击音效\snd_saber3.wav',
    '攻击音效\snd_shadowpendant.wav',
    '攻击音效\snd_shakerbreaker.wav',
    '灵魂音效\snd_heartshot.wav',
    '灵魂音效\snd_hurt1_c.wav',
    '灵魂音效\snd_hurt1.wav',
    '鱼姐专属音效\snd_arrow.wav',
    '鱼姐专属音效\snd_spearappear.wav',
    '普通音效\mus_explosion.wav',
    '普通音效\mus_sfx_eyeflash.wav',
    '普通音效\mus_sfx_sparkles.wav',
    '普通音效\snd_glassbreak.wav',
    '普通音效\snd_grab.wav',
    '普通音效\snd_heal_c.wav',
    '普通音效\snd_heavydamage.wav',
    '普通音效\snd_power.wav',
    '普通音效\snd_undynedis.wav',
    '普通音效\snd_undynestep.wav',
    '普通音效\snd_vaporized.wav',
    '普通音效\snd_vulkinhurt.wav',
    'mtt专属音效\snd_mtt_burst.wav',
    'mtt专属音效\snd_mtt_hit.wav',
    'mtt专属音效\snd_mtt_prebomb.wav',
    'sans专属音效\mus_sfx_rainbowbeam_1.wav',
    'sans专属音效\mus_sfx_segapower.wav',
    'sans专属音效\mus_sfx_segapower2.wav',
    'sans专属音效\snd_battlefall.wav',
    'sans专属音效\snd_spearrise.wav'
)
$curatedLookup = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($relativePath in $curatedRelativePaths) {
    [void]$curatedLookup.Add($relativePath)
}
$sourceFiles = $allSourceFiles | Where-Object {
    $curatedLookup.Contains([IO.Path]::GetRelativePath($sourceRootPath, $_.FullName))
}
if ($sourceFiles.Count -ne $curatedRelativePaths.Count) {
    throw "Curated sound selection resolved to $($sourceFiles.Count) files; expected $($curatedRelativePaths.Count)."
}

$previousImports = [System.Collections.Generic.List[object]]::new()
if (Test-Path -LiteralPath $manifestPath) {
    foreach ($line in [IO.File]::ReadAllLines($manifestPath)) {
        if ($line -match '^\| `([^`]+)` \| `([^`]+)` \|') {
            $previousImports.Add([pscustomobject]@{
                Source = $Matches[1]
                Resource = $Matches[2]
            })
        }
    }
}

$imported = [System.Collections.Generic.List[object]]::new()
$skipped = [System.Collections.Generic.List[object]]::new()

foreach ($sourceFile in $sourceFiles) {
    $baseResourceName = Get-SafeSoundName $sourceFile.Name
    $resourceName = $baseResourceName
    $resourceDirectory = Join-Path $soundsRoot $resourceName

    if (Test-Path -LiteralPath $resourceDirectory) {
        $existingAudio = Get-AudioFile $resourceDirectory
        if ($null -ne $existingAudio -and (Test-SameFile $sourceFile.FullName $existingAudio.FullName)) {
            $skipped.Add([pscustomobject]@{
                Source = $sourceFile.FullName
                Resource = $resourceName
                Reason = 'identical existing resource'
            })
            continue
        }

        $resourceName = "${baseResourceName}_material"
        $resourceDirectory = Join-Path $soundsRoot $resourceName
        $suffix = 2
        while (Test-Path -LiteralPath $resourceDirectory) {
            $existingAudio = Get-AudioFile $resourceDirectory
            if ($null -ne $existingAudio -and (Test-SameFile $sourceFile.FullName $existingAudio.FullName)) {
                $skipped.Add([pscustomobject]@{
                    Source = $sourceFile.FullName
                    Resource = $resourceName
                    Reason = 'identical previously imported resource'
                })
                continue 2
            }
            $resourceName = "${baseResourceName}_material_$suffix"
            $resourceDirectory = Join-Path $soundsRoot $resourceName
            $suffix++
        }
    }

    $extension = $sourceFile.Extension.ToLowerInvariant()
    $targetAudioName = "$resourceName$extension"
    $targetAudioPath = Join-Path $resourceDirectory $targetAudioName
    New-Item -ItemType Directory -Path $resourceDirectory -Force | Out-Null
    Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetAudioPath

    $probeJson = & ffprobe.exe -v error -select_streams a:0 `
        -show_entries stream=sample_rate -show_entries format=duration -of json -- $targetAudioPath
    $probe = $probeJson | ConvertFrom-Json
    $sampleRate = [int]$probe.streams[0].sample_rate
    $duration = [double]::Parse([string]$probe.format.duration, [Globalization.CultureInfo]::InvariantCulture)
    $durationText = $duration.ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)

    $yy = @"
{
  "`$GMSound":"v2",
  "%Name":"$resourceName",
  "audioGroupId":{
    "name":"audiogroup_default",
    "path":"audiogroups/audiogroup_default",
  },
  "bitDepth":1,
  "channelFormat":0,
  "compression":0,
  "compressionQuality":4,
  "conversionMode":0,
  "duration":$durationText,
  "exportDir":"",
  "name":"$resourceName",
  "parent":{
    "name":"SFX",
    "path":"folders/Sounds/SFX.yy",
  },
  "preload":false,
  "resourceType":"GMSound",
  "resourceVersion":"2.0",
  "sampleRate":$sampleRate,
  "soundFile":"$targetAudioName",
  "volume":1.0,
}
"@
    [IO.File]::WriteAllText((Join-Path $resourceDirectory "$resourceName.yy"), $yy, [Text.UTF8Encoding]::new($false))

    $relativeSource = [IO.Path]::GetRelativePath($sourceRootPath, $sourceFile.FullName)
    $imported.Add([pscustomobject]@{
        Source = $relativeSource
        Resource = $resourceName
        AudioFile = $targetAudioName
        Duration = $durationText
        SampleRate = $sampleRate
    })
}

$projectText = [IO.File]::ReadAllText($projectFile)
$resourceLines = foreach ($entry in $imported | Sort-Object Resource) {
    $path = "sounds/$($entry.Resource)/$($entry.Resource).yy"
    if ($projectText -notmatch [regex]::Escape("`"path`":`"$path`"")) {
        "    {`"id`":{`"name`":`"$($entry.Resource)`",`"path`":`"$path`",},},"
    }
}
if ($resourceLines.Count -gt 0) {
    $marker = '    {"id":{"name":"spr_arrow","path":"sprites/spr_arrow/spr_arrow.yy",},},'
    if (-not $projectText.Contains($marker)) {
        throw "Could not find the sound-resource insertion marker in $projectFile"
    }
    $projectText = $projectText.Replace($marker, (($resourceLines -join "`r`n") + "`r`n" + $marker))
    [IO.File]::WriteAllText($projectFile, $projectText, [Text.UTF8Encoding]::new($false))
}

# Remove only resources recorded by the previous material-pack manifest.  A
# matching source/audio hash is required, so unrelated user resources with a
# similar name cannot be removed accidentally.
$selectedResources = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $imported) { [void]$selectedResources.Add($entry.Resource) }
foreach ($entry in $skipped) { [void]$selectedResources.Add($entry.Resource) }
$pruned = [System.Collections.Generic.List[object]]::new()
foreach ($entry in $previousImports) {
    if ($selectedResources.Contains($entry.Resource)) { continue }

    $sourcePath = Join-Path $sourceRootPath $entry.Source
    $resourceDirectory = Join-Path $soundsRoot $entry.Resource
    $resolvedSoundsRoot = [IO.Path]::GetFullPath($soundsRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $resolvedResourceDirectory = [IO.Path]::GetFullPath($resourceDirectory)
    if (-not $resolvedResourceDirectory.StartsWith($resolvedSoundsRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to prune a path outside the project sounds directory: $resolvedResourceDirectory"
    }

    $existingAudio = Get-AudioFile $resourceDirectory
    if (-not (Test-Path -LiteralPath $sourcePath) -or $null -eq $existingAudio -or -not (Test-SameFile $sourcePath $existingAudio.FullName)) {
        throw "Refusing to prune changed or unverifiable material sound resource: $($entry.Resource)"
    }

    Remove-Item -LiteralPath $resolvedResourceDirectory -Recurse
    $projectText = [regex]::Replace(
        $projectText,
        "(?m)^\s*\{`"id`":\{`"name`":`"$([regex]::Escape($entry.Resource))`",`"path`":`"sounds/$([regex]::Escape($entry.Resource))/$([regex]::Escape($entry.Resource))\.yy`",\},\},\r?\n?",
        ''
    )
    $pruned.Add($entry)
}
if ($pruned.Count -gt 0) {
    [IO.File]::WriteAllText($projectFile, $projectText, [Text.UTF8Encoding]::new($false))
}

$selectedManifestEntries = [System.Collections.Generic.List[object]]::new()
foreach ($entry in $imported) {
    $selectedManifestEntries.Add($entry)
}
foreach ($entry in $skipped) {
    $existingAudio = Get-AudioFile (Join-Path $soundsRoot $entry.Resource)
    $probeJson = & ffprobe.exe -v error -select_streams a:0 `
        -show_entries stream=sample_rate -show_entries format=duration -of json -- $existingAudio.FullName
    $probe = $probeJson | ConvertFrom-Json
    $selectedManifestEntries.Add([pscustomobject]@{
        Source = [IO.Path]::GetRelativePath($sourceRootPath, $entry.Source)
        Resource = $entry.Resource
        AudioFile = $existingAudio.Name
        Duration = ([double]::Parse([string]$probe.format.duration, [Globalization.CultureInfo]::InvariantCulture)).ToString('0.######', [Globalization.CultureInfo]::InvariantCulture)
        SampleRate = [int]$probe.streams[0].sample_rate
    })
}

$manifest = [System.Collections.Generic.List[string]]::new()
$manifest.Add('# 素材包音效导入清单')
$manifest.Add('')
$manifest.Add("来源：``$sourceRootPath``")
$manifest.Add('')
$manifest.Add("- 素材包全部音频：$($allSourceFiles.Count)")
$manifest.Add("- 精选战斗音频：$($sourceFiles.Count)")
$manifest.Add("- 本次新增资源：$($imported.Count)")
$manifest.Add("- 沿用完全相同资源：$($skipped.Count)")
$manifest.Add("- 移除上次误导入资源：$($pruned.Count)")
$manifest.Add('')
$manifest.Add('| 素材包相对路径 | GameMaker 资源 | 时长（秒） | 采样率 |')
$manifest.Add('|---|---|---:|---:|')
foreach ($entry in $selectedManifestEntries | Sort-Object Source) {
    $manifest.Add("| ``$($entry.Source)`` | ``$($entry.Resource)`` | $($entry.Duration) | $($entry.SampleRate) |")
}
if ($skipped.Count -gt 0) {
    $manifest.Add('')
    $manifest.Add('## 完全相同，沿用现有资源')
    $manifest.Add('')
    foreach ($entry in $skipped | Sort-Object Source) {
        $relativeSource = [IO.Path]::GetRelativePath($sourceRootPath, $entry.Source)
        $manifest.Add("- ``$relativeSource`` -> ``$($entry.Resource)``")
    }
}
[IO.File]::WriteAllLines($manifestPath, $manifest, [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    PackSourceCount = $allSourceFiles.Count
    SelectedSourceCount = $sourceFiles.Count
    ImportedCount = $imported.Count
    SkippedIdenticalCount = $skipped.Count
    PrunedCount = $pruned.Count
    Manifest = $manifestPath
}
