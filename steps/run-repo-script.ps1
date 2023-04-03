param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$ScriptName,
    $Options
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$Script = [IO.Path]::Combine($RepoPath, "ci", $ScriptName)

$ScriptParameters = (Get-Command -Name $Script).Parameters

$Parameters = @()

foreach ($Option in $Options.GetEnumerator()) {
    Write-Output $Option.Key
    Write-Output $Option.Value

    if ($ScriptParameters.ContainsKey($Option.Key)) {
        Write-Output "matched..."
        $Parameters += "-$($Option.Key)",  $Option.Value
    }
}

Write-Output "Running script '$Script' with parameters: $Parameters"

. $Script -Options $Parameters

exit $LASTEXITCODE
