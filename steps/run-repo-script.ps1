param (
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$ScriptName,
    $Options = @{}
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

$Script = [IO.Path]::Combine($RepoPath, "ci", $ScriptName)

# Get the named parameters from the script file.
$ScriptParameters = (Get-Command -Name $Script).Parameters

$Parameters = @{}

# Add all the parameters that are available in the options.
foreach ($Option in $Options.GetEnumerator()) {
    if ($ScriptParameters.ContainsKey($Option.Key)) {
        Write-Output "Adding parameter '$($Option.Key)'"
        $Parameters.Add($Option.Key, $Option.Value)
    }
}

# If there are keys required, add these too.
if ($Null -ne $Options.Keys) {
    foreach ($Key in $Options.Keys.GetEnumerator()) {
        if ($ScriptParameters.ContainsKey($Key.Key)) {
            Write-Output "Adding parameter '$($Key.Key)'"
            $Parameters.Add($Key.Key, $Key.Value)
        }
    }
}
# If the repo name is required, then add that too.
if ($ScriptParameters.ContainsKey("RepoName")) {
    Write-Output "Adding parameter RepoName"
    $Parameters.Add("RepoName", $RepoName)
}

Write-Output "Running script '$Script'."

. $Script @Parameters

exit $LASTEXITCODE
