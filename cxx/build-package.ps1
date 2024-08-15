param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$BuildPath = New-Item -ItemType directory -Path $RepoName/build -Force
$OutPath = New-Item -ItemType directory -Path package -Force

Write-Output "Entering '$BuildPath'"
Push-Location $BuildPath
try {
    Write-Output "Building"

    cmake .. -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release

} finally {
    Write-Output "Leaving '$BuildPath'"
    Pop-Location
}

Write-Output "Copying build to '$OutPath'"
Copy-Item -Recurse -Path $BuildPath/bin -Destination $OutPath
