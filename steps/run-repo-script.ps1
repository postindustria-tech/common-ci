param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$ScriptName,
    $Options = @{}
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$Script = [IO.Path]::Combine($RepoPath, "ci", $ScriptName)

$ScriptParameters = (Get-Command -Name $Script).Parameters

$Parameters = @{}

foreach ($Option in $Options.GetEnumerator()) {
    if ($ScriptParameters.ContainsKey($Option.Key)) {
        Write-Output "Adding parameter '$($Option.Key)'"
        $Parameters.Add($Option.Key, $Option.Value)
    }
}

if ($ScriptParameters.ContainsKey("RepoName")) {
    Write-Output "Adding parameter RepoName"
    $Parameters.Add("RepoName", $RepoName)
}

Write-Output "Running script '$Script'."

. $Script @Parameters

exit $LASTEXITCODE
