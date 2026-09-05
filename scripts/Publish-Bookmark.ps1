[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $HtmlPath,

    [Parameter(Mandatory)]
    [ValidateLength(1, 1024)]
    [string] $Title,

    [string[]] $DestinationPath = @('Favorites bar', 'Imported'),

    [ValidateRange(5, 600)]
    [int] $TimeoutSeconds = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-Slug([string] $Value) {
    $slug = $Value.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return 'bookmark'
    }
    return $slug.Substring(0, [Math]::Min($slug.Length, 80))
}

if ($Title.Trim() -cne $Title -or [string]::IsNullOrWhiteSpace($Title) -or
    $Title -match '[\u0000-\u001f\u007f]') {
    throw 'Title must be a non-empty, trimmed string without control characters.'
}
if ($DestinationPath.Count -eq 0 -or $DestinationPath[0] -cne 'Favorites bar' -or
    @($DestinationPath | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
    throw "DestinationPath must start with exactly 'Favorites bar' and contain no empty segments."
}

$resolvedHtmlPath = [IO.Path]::GetFullPath($HtmlPath)
if (-not (Test-Path -LiteralPath $resolvedHtmlPath -PathType Leaf)) {
    throw "HTML file was not found at '$resolvedHtmlPath'."
}
if ([IO.Path]::GetExtension($resolvedHtmlPath) -cne '.html') {
    throw 'HtmlPath must reference an .html file.'
}

$html = [IO.File]::ReadAllText($resolvedHtmlPath)
if ($html -notmatch '(?is)<title>\s*[^<]+\s*</title>' -or
    $html -notmatch '(?is)<h1(?:\s[^>]*)?>.*?</h1>' -or
    $html -notmatch '(?is)<meta\s+[^>]*charset\s*=') {
    throw 'HTML must contain a non-empty title, an h1, and charset metadata.'
}

$slug = ConvertTo-Slug $Title
$commandPath = Join-Path (Split-Path -Parent $resolvedHtmlPath) "$slug-edge-command.json"
$fileUri = [Uri]::new($resolvedHtmlPath).AbsoluteUri
$command = [ordered]@{
    version = 1
    type = 'upsertBookmark'
    destinationPath = @($DestinationPath)
    bookmark = [ordered]@{
        type = 'bookmark'
        name = $Title
        url = $fileUri
    }
}
[IO.File]::WriteAllText(
    $commandPath,
    ($command | ConvertTo-Json -Depth 10),
    [Text.UTF8Encoding]::new($false))

$bridgePath = Join-Path $env:USERPROFILE '.copilot\skills\learn-with-bookmarks\scripts\Invoke-EdgeFavoritesCompanion.ps1'
if (-not (Test-Path -LiteralPath $bridgePath -PathType Leaf)) {
    throw "The Edge companion bridge was not found at '$bridgePath'."
}

$result = & $bridgePath -CommandPath $commandPath -TimeoutSeconds $TimeoutSeconds
if ($result.ok -ne $true) {
    throw 'The Edge companion did not return a successful result.'
}

[pscustomobject]@{
    HtmlPath = $resolvedHtmlPath
    FileUri = $fileUri
    DestinationPath = @($DestinationPath)
    BookmarkTitle = $Title
    CommandPath = $commandPath
    CompanionResult = $result
}
