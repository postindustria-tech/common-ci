
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [string]$Configuration = "Release",
    [string]$Arch,
    [string]$ProjectDir = ".",
    [Parameter(Mandatory=$true)]
    [string]$ResultName
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    $TestArgs = "-c", $Configuration, $ProjectDir, "-r", "output", "--blame-crash"
    if ("" -ne $Arch) {

        $TestArgs += "-l", "trx;LogFileName=TestResults-$Configuration-$Arch.trx", "--arch", $Arch

    }
    else {

        $TestArgs += "-l", "trx;LogFileName=TestResults-$Configuration.trx"

    }
    
    dotnet test $TestArgs

}
finally {

    Write-Output "Setting '`$$ResultName'"
    Set-Variable -Name $ResultName -Value $(0 -eq $LASTEXITCODE) -Scope 1

    Write-Output "Leaving '$RepoPath'"
    Pop-Location

}

