[CmdletBinding()]
param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot '..\pluginmaster.json'),
    [switch]$SkipDownloadValidation
)

$ErrorActionPreference = 'Stop'

$resolvedManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
$parsed = Get-Content -LiteralPath $resolvedManifest -Raw | ConvertFrom-Json
$entries = @($parsed)
if ($entries.Count -eq 0) {
    throw 'PluginMaster contains no entries.'
}

$duplicates = $entries | Group-Object InternalName | Where-Object Count -gt 1
if ($duplicates) {
    throw "Duplicate InternalName values: $($duplicates.Name -join ', ')"
}

foreach ($entry in $entries) {
    foreach ($field in @('Author', 'Name', 'InternalName', 'AssemblyVersion', 'RepoUrl', 'DownloadLinkInstall')) {
        if ([string]::IsNullOrWhiteSpace([string]$entry.$field)) {
            throw "$($entry.InternalName): required field '$field' is empty."
        }
    }

    if ([string]$entry.AssemblyVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
        throw "$($entry.InternalName): AssemblyVersion is not four-part numeric."
    }
}

$downloadUrls = $entries |
    ForEach-Object { $_.DownloadLinkInstall; $_.DownloadLinkTesting; $_.DownloadLinkUpdate } |
    Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
    Sort-Object -Unique

foreach ($url in $downloadUrls) {
    $uri = $null
    if (-not [Uri]::TryCreate([string]$url, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https') {
        throw "Download URL is not an absolute HTTPS URL: $url"
    }

    if ($SkipDownloadValidation) {
        continue
    }

    & curl.exe --fail --head --location --silent --show-error $url | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Download URL is unavailable: $url"
    }
}

Write-Host "Validated $($entries.Count) PluginMaster entries and $($downloadUrls.Count) download URLs."
