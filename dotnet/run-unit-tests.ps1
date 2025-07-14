[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release",
    [string]$Arch = "x64",
    [string]$BuildMethod="dotnet",
    [switch]$DotnetDiag,
    [string]$DirNameFormatForDotnet = "*bin*",
    [string]$DirNameFormatForNotDotnet = "*\bin\*",
    [string]$Filter,
    [string]$OutputFolder = "unit"
)

$SkipPlatformArgs = (($Arch -eq "Any CPU") -or ($Filter.Contains("dll")))
Write-Output "SkipPlatformArgs = $SkipPlatformArgs"

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$TestResultPath = [IO.Path]::Combine($RepoPath, "test-results", $OutputFolder, $Name)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {
    $ok = $true
    $verbose = $IsMacOS ? '--verbosity', 'd' : $null # macOS debugging

    $skipPattern = "*performance*"
    Write-Output "Testing '$Name'"
    if ($BuildMethod -eq "dotnet"){
        Write-Output "[dotnet] => Looking for '$Filter' in directories like '$DirNameFormatForDotnet'"
        $PlatformParams = $SkipPlatformArgs ? @() : @("-p:Platform=$Arch")
        foreach ($NextFile in (Get-ChildItem -Path $RepoPath -Recurse -File)) {
            $DotnetCallParams = $PlatformParams
            if ($DotnetDiag) {
                $DotnetCallParams += "--diag:$RepoPath/test-log-$($NextFile.Name).txt"
            }
            $NextDirName = $NextFile.DirectoryName
            $NextFileName = $NextFile.Name
            Write-Debug "[$NextDirName]/[$NextFileName]"
            if ($NextDirName -notlike $DirNameFormatForDotnet) {
                Write-Debug "- $NextDirName not matched $DirNameFormatForDotnet"
            } elseif ($NextFileName -like $skipPattern) {
                Write-Debug "- $NextFileName matched $skipPattern"
            } elseif ($NextFileName -notmatch "$Filter") {
                Write-Debug "- $NextFileName not matched $Filter"
            } else {
                Write-Output "Testing Assembly: '$NextFile'"
                dotnet test $NextFile.FullName `
                    --no-build `
                    --configuration $Configuration `
                    @DotnetCallParams `
                    --results-directory $TestResultPath `
                    --blame-crash --blame-hang-timeout 5m -l "trx" $verbose
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "dotnet test LastExitCode=$LASTEXITCODE"
                    if ($DotnetDiag) {
                        $LogFiles = Get-ChildItem "$RepoPath/test-log-$($NextFile.Name)*txt"
                        foreach ($NextLogFile in $LogFiles) {
                            Write-Warning "---- $($NextLogFile.Name) BEGIN ----"
                            Get-Content $NextLogFile.FullName
                            Write-Warning "---- $($NextLogFile.Name) END ----"
                        }
                    }
                    $script:ok = $false
                }
                Write-Output "dotnet test LastExitCode=$LASTEXITCODE"
            }
        }
    } else {
        Write-Output "[$BuildMethod] ~> Looking for '$Filter' in directories like '$DirNameFormatForNotDotnet'"
        $PlatformParams = $SkipPlatformArgs ? @() : @("/Platform:$Arch")
        foreach ($NextFile in (Get-ChildItem -Path $RepoPath -Recurse -File)) {
            $NextDirName = $NextFile.DirectoryName
            $NextFileName = $NextFile.Name
            Write-Debug "[$NextDirName]/[$NextFileName]"
            if ($NextDirName -notlike $DirNameFormatForNotDotnet) {
                Write-Debug "- $NextDirName not matched $DirNameFormatForNotDotnet"
            } elseif ($NextFileName -like $skipPattern) {
                Write-Debug "- $NextFileName matched $skipPattern"
            } elseif ($NextFileName -notmatch "$Filter") {
                Write-Debug "- $NextFileName not matched $Filter"
            } else {
                Write-Output "Testing Assembly: '$NextFile'"
                & vstest.console.exe $NextFile.FullName `
                    @PlatformParams `
                    /Logger:trx `
                    /ResultsDirectory:$TestResultPath || $($script:ok = $false)
                Write-Output "vstest.console LastExitCode=$LASTEXITCODE"
            }
        }
    }

    if (!$ok) {
        Write-Error "Tests failed"
    }
} finally {
    Write-Output "Leaving '$RepoPath'"
    Pop-Location
}
