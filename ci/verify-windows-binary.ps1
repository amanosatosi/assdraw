param(
    [Parameter(Mandatory = $true)]
    [string]$Executable
)

$ErrorActionPreference = 'Stop'
$exe = (Resolve-Path -LiteralPath $Executable).Path
if ([IO.Path]::GetFileName($exe) -cne 'ASSDraw3.exe') {
    throw "Expected ASSDraw3.exe, got '$exe'."
}

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$install = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$dumpbin = Get-ChildItem "$install\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe" |
    Sort-Object FullName -Descending | Select-Object -First 1
if (-not $dumpbin) {
    throw 'dumpbin.exe was not found in the Visual Studio installation.'
}

$dependencyOutput = & $dumpbin.FullName /DEPENDENTS $exe | Out-String
$dependencyOutput | Write-Host
if ($LASTEXITCODE -ne 0) {
    throw "dumpbin /DEPENDENTS failed with exit code $LASTEXITCODE."
}

$imports = [regex]::Matches($dependencyOutput, '(?im)^\s+([A-Za-z0-9_.+\-]+\.(?:dll|drv))\s*$') |
    ForEach-Object { $_.Groups[1].Value.ToUpperInvariant() } |
    Sort-Object -Unique
if (-not $imports) {
    throw 'No imported Windows libraries were found; dumpbin output could not be validated.'
}

$forbidden = $imports | Where-Object {
    $_ -match '^(WX.*\.DLL|AGG.*\.DLL|VCRUNTIME.*\.DLL|MSVCP.*\.DLL|CONCRT.*\.DLL|UCRTBASE\.DLL|LIBGCC.*\.DLL|LIBSTDC\+\+.*\.DLL|LIBWINPTHREAD.*\.DLL)$'
}
if ($forbidden) {
    throw "Forbidden third-party/runtime imports found: $($forbidden -join ', ')"
}

# Extract resource ID 1 to prove that the hand-authored Windows manifest was
# embedded, rather than relying on a loose file beside the application.
$mt = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\mt.exe" |
    Sort-Object FullName -Descending | Select-Object -First 1
if (-not $mt) {
    throw 'mt.exe was not found in the Windows SDK.'
}
$manifest = Join-Path $env:RUNNER_TEMP 'ASSDraw3.embedded.manifest'
& $mt.FullName -nologo "-inputresource:$exe;#1" "-out:$manifest"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $manifest)) {
    throw 'The embedded application manifest could not be extracted.'
}
$manifestText = Get-Content -LiteralPath $manifest -Raw
foreach ($requiredText in @('ASSDraw3', 'asInvoker', 'Microsoft.Windows.Common-Controls', 'PerMonitorV2')) {
    if ($manifestText -notmatch [regex]::Escape($requiredText)) {
        throw "The embedded manifest is missing '$requiredText'."
    }
}

$version = (Get-Item -LiteralPath $exe).VersionInfo
if ($version.FileVersion -ne '3.0.0.0' -or $version.OriginalFilename -cne 'ASSDraw3.exe') {
    throw "Unexpected version resource: FileVersion='$($version.FileVersion)', OriginalFilename='$($version.OriginalFilename)'."
}

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class ASSDrawIconAudit
{
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern uint ExtractIconEx(
        string fileName, int iconIndex, IntPtr[] largeIcons, IntPtr[] smallIcons, uint iconCount);
}
'@
if ([ASSDrawIconAudit]::ExtractIconEx($exe, -1, $null, $null, 0) -lt 1) {
    throw 'ASSDraw3.exe does not contain an embedded application icon.'
}

Write-Host "Verified imports: $($imports -join ', ')"
Write-Host 'No forbidden wxWidgets, AGG, MSVC, or MinGW runtime DLL imports were found.'
Write-Host 'The application manifest, version metadata, icon, common-controls identity, and DPI declaration are embedded.'

if ($env:GITHUB_STEP_SUMMARY) {
    @"
### ASSDraw3.exe dependency audit

- Imported libraries: ``$($imports -join ', ')``
- Forbidden third-party/runtime imports: none
- Embedded resources: verified (icon, version 3.0.0.0, asInvoker manifest, Common Controls v6, PerMonitorV2)
"@ | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
}
