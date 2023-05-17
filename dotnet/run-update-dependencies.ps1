
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    foreach ($Project in $(Get-ChildItem -Path $pwd -Filter *.csproj -Recurse -ErrorAction SilentlyContinue -Force)) {
        foreach ($Package in $(dotnet list $Project.FullName package --outdated | Select-String -Pattern "^\s*>")) {
            $PackageName = $Package -replace '^ *> ([a-zA-Z0-9\.]*) .*$', '$1' 
            $MajorVersion = $Package -replace '^ *> [a-zA-Z0-9\.]* *([0-9]*)\.([0-9]*)\.([0-9]*).*$', '$1' 
            $MinorVersion = $Package -replace '^ *> [a-zA-Z0-9\.]* *([0-9]*)\.([0-9]*)\.([0-9]*).*$', '$2' 
            $PatchVersion = $Package -replace '^ *> [a-zA-Z0-9\.]* *([0-9]*)\.([0-9]*)\.([0-9]*).*$', '$3' 
            
            $Available = $(Find-Package -Name $PackageName -AllVersions -Source https://api.nuget.org/v3/index.json | Where-Object {$_.Version -Match "$MajorVersion.$MinorVersion.*"})
            $HighestPatch = $Available[0].Version

            if ("$MajorVersion.$MinorVersion.$PatchVersion" -ne $HighestPatch) {

                Write-Output "Updating '$PackageName' from '$MajorVersion.$MinorVersion.$PatchVersion' to $HighestPatch"

                dotnet add $Project.FullName package $PackageName -v $HighestPatch
                
            }
        }
    }

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE