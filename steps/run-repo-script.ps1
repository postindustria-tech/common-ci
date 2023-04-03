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
        $Parameters.Add($Option.Key, $Option.Value)
    }
}

Write-Output "Running script '$Script' with parameters: $Parameters"

. $Script @Parameters

exit $LASTEXITCODE
