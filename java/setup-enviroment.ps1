
param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName,
    [Parameter(Mandatory=$true)]
    [string]$JavaSDKEnvVar,
    [string]$ProjectDir = "."
)

$RepoPath = [IO.Path]::Combine($pwd, $RepoName)

Write-Output "Entering '$RepoPath'"
Push-Location $RepoPath

try {

    Write-Output "Setting up $JavaSDKEnvVar"

    # Set the JAVA_HOME environment variable
    [Environment]::SetEnvironmentVariable('JAVA_HOME', [Environment]::GetEnvironmentVariable($JavaSDKEnvVar))

    # Add the Java binary directory to the system PATH
    $env:Path = "$env:JAVA_HOME/bin;$env:Path"
    
    # Write the value of the environment variable to the GITHUB_ENV file,
    # which makes the variable available to all subsequent steps in the job.
    Write-Output "JAVA_HOME=$env:JAVA_HOME" | Out-File -Encoding utf8 -FilePath $env:GITHUB_ENV -Append

    if( $env:RUNNER_OS -eq "Linux" ){
        # Create a symbolic link between the java binary in the JAVA_HOME directory 
        # and the /usr/bin/java path, which is on the system's PATH.
        sudo ln -sf $env:JAVA_HOME/bin/java /usr/bin/java
    }

    # Verify that the correct version of Java is being used
    java -version
}

finally{
    Write-Output "Finished setting up enviromental variables"
    Write-Output "Leaving '$RepoPath'"
    Pop-Location
}


exit $LASTEXITCODE
