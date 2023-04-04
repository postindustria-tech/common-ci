
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectDir = ".",
    [string]$RepoName,
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release"
)

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

exit $LASTEXITCODE