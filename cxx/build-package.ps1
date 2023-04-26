
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

$BuildPath = [IO.Path]::Combine($pwd, $RepoName, "build")
$OutPath = [IO.Path]::Combine($pwd, $RepoName, "package")
mkdir $BuildPath
mkdir $OutPath

Write-Output "Entering '$BuildPath'"
Push-Location $BuildPath

try {

    Write-Output "Building"
    
    cmake .. -DCMAKE_BUILD_TYPE=Release
    cmake --build . --config Release

}
finally {

    Write-Output "Leaving '$BuildPath'"
    Pop-Location

}

Write-Output "Copying build to '$OutPath'"
Copy-Item -Recurse -Path $([IO.Path]::Combine($BuildPath, "bin")) -Destination $OutPath

exit $LASTEXITCODE