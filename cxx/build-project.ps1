
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectDir = ".",
    [string]$RepoName,
    [string]$Name,
    [string]$Arch = "x64",
    [string]$Configuration = "Release",
    [string]$BuildMethod = "cmake"
)

if ($BuildMethod -eq "cmake") {

    $RepoPath = [IO.Path]::Combine($pwd, $RepoName, $ProjectDir, "build")
    mkdir $RepoPath

    Write-Output "Entering '$RepoPath'"
    Push-Location $RepoPath
    
    try {
    
        Write-Output "Building '$Name'"
        
        cmake .. -DCMAKE_BUILD_TYPE=$Configuration 
        cmake --build . --config $Configuration
    
    }
    finally {
    
        Write-Output "Leaving '$RepoPath'"
        Pop-Location
    
    }
}
elseif ($BuildMethod -eq "msbuild") {

    $RepoPath = [IO.Path]::Combine($pwd, $RepoName, $ProjectDir)

    Write-Output "Entering '$RepoPath'"
    Push-Location $RepoPath
    
    try {

        nuget restore
        msbuild /p:Configuration=$Configuration /p:Platform=$Arch /p:OutDir=$RepoPath\build

    }
    finally {

        Write-Output "Leaving '$RepoPath'"
        Pop-Location

    }
}
else {

    Write-Error "The build method '$BuildMethod' is not supported."

}

exit $LASTEXITCODE