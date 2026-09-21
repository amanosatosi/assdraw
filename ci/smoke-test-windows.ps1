param(
    [Parameter(Mandatory = $true)]
    [string]$Executable
)

$ErrorActionPreference = 'Stop'
$sourceExe = (Resolve-Path -LiteralPath $Executable).Path
$smokeDirectory = Join-Path $env:RUNNER_TEMP 'assdraw-standalone-smoke'

if (Test-Path -LiteralPath $smokeDirectory) {
    Remove-Item -LiteralPath $smokeDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $smokeDirectory | Out-Null
$smokeExe = Join-Path $smokeDirectory 'ASSDraw3.exe'
Copy-Item -LiteralPath $sourceExe -Destination $smokeExe

$files = @(Get-ChildItem -LiteralPath $smokeDirectory -File)
if ($files.Count -ne 1 -or $files[0].Name -cne 'ASSDraw3.exe') {
    throw 'The smoke-test directory must contain ASSDraw3.exe and nothing else.'
}

$process = $null
try {
    $process = Start-Process -FilePath $smokeExe -WorkingDirectory $smokeDirectory -PassThru
    Start-Sleep -Seconds 10
    $process.Refresh()
    if ($process.HasExited) {
        throw "ASSDraw3.exe exited during startup with code $($process.ExitCode)."
    }
    if ($process.MainWindowHandle -eq 0) {
        throw 'ASSDraw3.exe stayed alive but did not create a visible top-level window.'
    }

    $remainingFiles = @(Get-ChildItem -LiteralPath $smokeDirectory -File)
    if ($remainingFiles.Count -ne 1 -or $remainingFiles[0].Name -cne 'ASSDraw3.exe') {
        throw 'ASSDraw3.exe required or created a companion file in its launch directory.'
    }

    Write-Host "ASSDraw3.exe started from an otherwise empty directory (window handle $($process.MainWindowHandle))."
}
finally {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit()
    }
}

if ($env:GITHUB_STEP_SUMMARY) {
    @"
### Standalone smoke test

``ASSDraw3.exe`` started, created a visible window, and remained running for 10 seconds from a directory containing no companion files.
"@ | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
}
