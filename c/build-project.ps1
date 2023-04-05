
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectDir = ".",
    [string]$RepoName,
    [string]$Name = "Release_x64",
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
        cmake --build .
    
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

        msbuild $ProjectDir /p:Configuration=$Configuration /property:Platform=$Arch

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