param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectDir = ".",
    [string]$RepoName,
    [string]$Name,
    [string]$Arch = "x64",
    [string]$Configuration = "Release",
    [string]$BuildMethod = "cmake",
    [string]$BuildDir = "build",
    [string[]]$ExtraArgs
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

if ($BuildMethod -eq "cmake") {
    $RepoPath = New-Item -ItemType directory -Path $RepoName/$ProjectDir/$BuildDir -Force

    if($IsWindows -and $Arch -eq "x86"){
        $ExtraArgs += '-A', 'win32'
    }

    Write-Output "Entering '$RepoPath'"
    Push-Location $RepoPath
    try {
        Write-Output "Building '$Name'"

        # Without quotes $Configuration wont expand 🤡
        cmake .. -DCMAKE_BUILD_TYPE="$Configuration" $ExtraArgs

        cmake --build . --config $Configuration --parallel ([Environment]::ProcessorCount)

    } finally {
        Write-Output "Leaving '$RepoPath'"
        Pop-Location
    }

} elseif ($BuildMethod -eq "msbuild") {
    $RepoPath = New-Item -ItemType directory -Path $RepoName/$ProjectDir -Force

    Write-Output "Entering '$RepoPath'"
    Push-Location $RepoPath
    try {
        & {
            $PSNativeCommandUseErrorActionPreference = $false
            nuget restore || Write-Warning "nuget restore failed"
        }
        Write-Output "`nCleaning...`n"
        msbuild /p:Configuration=$Configuration /p:Platform=$Arch /p:OutDir=$RepoPath\$BuildDir\ /t:Clean
        Write-Output "`nCleaning done.`nBuilding...`n"
        msbuild /p:Configuration=$Configuration /p:Platform=$Arch /p:OutDir=$RepoPath\$BuildDir\

    } finally {
        Write-Output "Leaving '$RepoPath'"
        Pop-Location
    }

} else {
    Write-Error "The build method '$BuildMethod' is not supported."
}
