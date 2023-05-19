# Run vswhere command and capture the output
Invoke-WebRequest -Uri https://github.com/microsoft/vswhere/releases/download/3.1.1/vswhere.exe -OutFile vswhere.exe
$vsWhereOutput = & .\vswhere.exe -latest -property installationPath
# Extract the installation path from the output
$installationPath = $vsWhereOutput.Trim()
# Construct the full path to vstest.console.exe
$vstestConsolePath = Join-Path -Path $installationPath -ChildPath "Common7\IDE\CommonExtensions\Microsoft\TestWindow"
# Display the path
Write-Host "Adding vstest.console.exe to PATH: $vstestConsolePath"
$env:PATH += ";$vstestConsolePath"