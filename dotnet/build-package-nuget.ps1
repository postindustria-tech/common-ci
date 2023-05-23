
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$ProjectDir = ".",
    [string]$Name = "Release_x64",
    [string]$Configuration = "Release",
    [string]$Arch = "x64",
    [string]$Version,
    [string]$SolutionName,
    # Regex pattern to filter out projects that will not be published as a package 
    [string]$SearchPatern = "^(?!.*Test)Project\(.*csproj"
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)
$PackagesFolder = [IO.Path]::Combine($pwd, "package")

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Building package for '$Name'"
   
    $Projects = Get-Content "$SolutionName.sln" |
    Select-String $SearchPatern |
        ForEach-Object {
            $projectParts = $_ -Split '[,=]' | ForEach-Object { $_.Trim('[ "{}]') };
            New-Object PSObject -Property @{
                Name = $projectParts[1];
                File = $projectParts[2];
                Guid = $projectParts[3]
            }
    }
    foreach($Project in $Projects){
        dotnet pack $Project.File -o "$PackagesFolder" -c $Configuration /p:Platform=$Arch /p:PackageVersion=$Version /p:BuiltOnCI=true
    }
    

}
finally {

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

exit $LASTEXITCODE
