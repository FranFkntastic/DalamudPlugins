[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$PluginInternalName,

    [Parameter(Mandatory)]
    [string]$ReleaseTag,

    [Parameter(Mandatory)]
    [string]$AssetName,

    [string]$AssemblyVersion,
    [string]$ManifestPath = (Join-Path $PSScriptRoot '..\pluginmaster.json'),
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$ErrorActionPreference = 'Stop'

$resolvedManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
$parsed = Get-Content -LiteralPath $resolvedManifest -Raw | ConvertFrom-Json
$entries = @($parsed)
$matches = @($entries | Where-Object InternalName -EQ $PluginInternalName)
if ($matches.Count -ne 1) {
    throw "Expected exactly one PluginMaster entry named '$PluginInternalName'; found $($matches.Count)."
}

$entry = $matches[0]
$repositoryUri = $null
if (-not [Uri]::TryCreate([string]$entry.RepoUrl, [UriKind]::Absolute, [ref]$repositoryUri) -or
    $repositoryUri.Scheme -ne 'https' -or
    $repositoryUri.Host -ne 'github.com') {
    throw "$PluginInternalName has an unsupported RepoUrl: $($entry.RepoUrl)"
}

$repository = $repositoryUri.AbsolutePath.Trim('/')
if ($repository.Split('/').Count -ne 2) {
    throw "$PluginInternalName RepoUrl does not identify one GitHub repository: $($entry.RepoUrl)"
}

$version = if ([string]::IsNullOrWhiteSpace($AssemblyVersion)) {
    $ReleaseTag -replace '^v', ''
} else {
    $AssemblyVersion
}
if ($version -notmatch '^\d+\.\d+\.\d+\.\d+$') {
    throw "Assembly version '$version' is not four-part numeric. Provide -AssemblyVersion when the release tag uses a different format."
}

$headers = @{
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent' = 'DalamudPlugins-release-workflow'
}
if (-not [string]::IsNullOrWhiteSpace($GitHubToken)) {
    $headers.Authorization = "Bearer $GitHubToken"
}

$encodedTag = [Uri]::EscapeDataString($ReleaseTag)
$releaseUri = "https://api.github.com/repos/$repository/releases/tags/$encodedTag"
$release = Invoke-RestMethod -Uri $releaseUri -Headers $headers
if ($release.draft -or $release.prerelease) {
    throw "Release '$ReleaseTag' must be published and stable before PluginMaster publication."
}

$assets = @($release.assets | Where-Object name -EQ $AssetName)
if ($assets.Count -ne 1) {
    $available = @($release.assets | ForEach-Object name) -join ', '
    throw "Release '$ReleaseTag' does not contain exactly one '$AssetName' asset. Available assets: $available"
}

if ([string]::IsNullOrWhiteSpace([string]$release.published_at)) {
    throw "Release '$ReleaseTag' does not have a publication timestamp."
}

$publishedAt = [DateTimeOffset]::Parse(
    [string]$release.published_at,
    [Globalization.CultureInfo]::InvariantCulture)
$lastUpdate = $publishedAt.ToUnixTimeSeconds().ToString([Globalization.CultureInfo]::InvariantCulture)
$downloadUrl = [string]$assets[0].browser_download_url

$desiredValues = [ordered]@{
    AssemblyVersion = $version
    DownloadLinkInstall = $downloadUrl
    DownloadLinkTesting = $downloadUrl
    DownloadLinkUpdate = $downloadUrl
}

$changedFields = [Collections.Generic.List[string]]::new()
foreach ($field in $desiredValues.Keys) {
    if ([string]$entry.$field -ne [string]$desiredValues[$field]) {
        $entry.$field = [string]$desiredValues[$field]
        $changedFields.Add($field)
    }
}

if ($changedFields.Count -eq 0) {
    Write-Host "$PluginInternalName already points to $ReleaseTag/$AssetName."
    return
}

if ([string]$entry.LastUpdate -ne $lastUpdate) {
    $entry.LastUpdate = $lastUpdate
    $changedFields.Add('LastUpdate')
}

if ($PSCmdlet.ShouldProcess($resolvedManifest, "Publish $PluginInternalName $version")) {
    $json = ConvertTo-Json -InputObject $entries -Depth 20
    [IO.File]::WriteAllText(
        $resolvedManifest,
        $json + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false))
}

Write-Host "Updated $PluginInternalName to $ReleaseTag/${AssetName}: $($changedFields -join ', ')."
