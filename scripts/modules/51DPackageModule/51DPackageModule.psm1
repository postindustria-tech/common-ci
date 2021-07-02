<#
  ===================== Packages =====================
  .Description
  This module contains functions that perform actions
  on managing packages.
  For more information, please read description of
  each function.
#>

# Global variables to be updated when one of the main APIs is called.
$global:releaseConfig = $null
$global:projects = $null

<#
  .Description
  Initialise the global variables
  
  .Parameter ConfigFile
  Path to the configration file
#>
function Initialize-GlobalVariables {
	param (
		[string]$ConfigFile
	)
	
	# Obtain the config file content. Initialise the global variables
	Write-Host "# Initialise form configuration file: " + $ConfigFile
	$global:releaseConfig = Get-Content $ConfigFile | Out-String | ConvertFrom-Json
	$global:projects = $global:releaseConfig.projects
	Write-Host "# Init config: " + $global:releaseConfig
	Write-Host "# Init projects: " + $global:projects
}

<#
  .Description
  Update dependencies of all Maven packages in a project.
  
  .Parameter ConfigFile
  Full path to a configration file
  
  .Outputs
  true or false
#>
function Update-MavenPackageDependencies {
	param (
		[string]$ProjectName
	)
	
	Write-Host ""
	Write-Host "Update Maven Package Dependencies"
	Write-Host "================================="
	
	$dependencies = $global:projects."$ProjectName".dependencies
	if ($dependencies -ne $null -and $dependencies.count -gt 0) {
		# Check if pom.xml exists
		if (Test-Path pom.xml) {
			$pomContent = $(Get-Content pom.xml)
			$changeMade = $false
			foreach ($dependency in $dependencies) {
				$versionVariableName = $global:projects."$dependency".versionVariableName
				if ($pomContent -match "\<$versionVariableName\>") {
					Write-Host "# Version variable matches dependency $versionVariableName. Update."
					$dependencyVersion = $global:projects."$dependency".version
					$pomContent = $pomContent -replace `
						"\<$versionVariableName\>.*\</$versionVariableName\>", `
						"<$versionVariableName>$dependencyVersion</$versionVariableName>"
					$changeMade = $true
				} else {
					Write-Host "# Nothing to update for dependency $versionVariableName"
				}
			}
			
			# Check if pom has been updated.
			if ($changeMade) {
				Write-Host "# Dependency version has been updated. Update the pom.xml content."
				Set-Content pom.xml -Value $pomContent
				if (!$?) {
					Write-Host "# ERROR: Failed to update the pom.xml content."
					return $false
				}
				
				# Stage the change
				git add pom.xml
				if (!$?) {
					Write-Host "# ERROR: Failed to stage the change."
					return $false
				}
			}
		} else {
			Write-Host "# ERROR: No pom file is found at this directory. Nothing to update."
			return $false
		}
	} else {
		Write-Host "# There is no dependencies defined in configuration file. Skipped."
	}
	
	return $true
}

<#
  .Description
  Update dependencies of all Dotnet packages in a project.
  
  .Parameter ConfigFile
  Full path to a configration file
  
  .Outputs
  true or false
#>
function Update-DotnetPackageDependencies {
	param (
		[string]$ProjectName
	)
	
	Write-Host ""
	Write-Host "Update Dotnet Package Dependencies"
	Write-Host "================================="
	
	$dependencies = $global:projects."$ProjectName".dependencies
	# Make sure only update if there are dependencies
	if ($dependencies -ne $null -and $dependencies.count -gt 0) {
		# Update each .csproj file.
		foreach ($project in $(Get-ChildItem -Filter *.csproj -Recurse)) {
			$projFileContent = $(Get-Content $project.FullName)
			$changeMade = $false
			# Update each .csproj file with dependency versions.
			foreach ($dependency in $dependencies) {
				$packageName = $global:projects."$dependency".packageName
				# This pattern has a match group name 'name'. That will be used to preserv the actual matched package name.
				$matchPattern = "\<PackageReference \s*Include=\`"(?<name>$packageName.*)\`" \s*Version=\`"\d+\.\d+\.\d+\`"\s*/\>"
				if ($projFileContent -match "$matchPattern") {
					Write-Host "# Version variable matches dependency $packageName. Update."
					$dependencyVersion = $global:projects."$dependency".version
					# This reuse the matched group so make sure we don't lose the original package name.
					$replaceString = '<PackageReference Include="${name}" Version="' + $dependencyVersion +'" />'
					$projFileContent = $projFileContent -replace "$matchPattern",$replaceString
					$changeMade = $true
				} else {
					Write-Host "# Nothing to update for dependency $packageName"
				}
			}
			
			# Check if .csproj has been updated.
			if ($changeMade) {
				Write-Host "# Dependency version has been updated. Update the $($project.FullName) content."
				Set-Content $project.FullName -Value $projFileContent
				if (!$?) {
					Write-Host "# ERROR: Failed to update the $project.FullName content."
					return $false
				}
				
				# Stage the change
				git add $project.FullName
				if (!$?) {
					Write-Host "# ERROR: Failed to stage the change."
					return $false
				}
			}
		}
	} else {
		Write-Host "# There is no dependencies defined in configuration file. Skipped."
	}
	
	return $true
}

<#
  .Description
  Take a package file content and update the input project version.
  
  .Parameter ProjectName
  Name of the project to update
  
  .Parameter PackageFileContent
  Content of the package file to update
  
  .Outputs 2 outputs
  ChangeMade: true or false
  Updated file content
#>
function Update-NodePackageDependency {
	param (
		[string]$ProjectName,
		$PackageFileContent
	)
	
	$packageName = $global:projects."$ProjectName".packageName
	# This pattern has a match group name 'name'. That will be used to preserve the actual matched package name.
	$matchPattern = "\`"(?<name>$packageName(\.[A-Za-z]+)*)\`"\s*:\s*\`"\^\d+\.\d+\.\d+\`""
	if ($PackageFileContent -match "$matchPattern") {
		Write-Host "# Version variable matches dependency $packageName. Try to update."
		$dependencyVersion = $global:projects."$ProjectName".version
		# This reuse the matched group so make sure we don't lose the original package name.
		$replaceString = '"${name}": "^' + $dependencyVersion + '"'
		$PackageFileContent = $PackageFileContent -replace "$matchPattern",$replaceString
	} else {
		Write-Host "# Nothing to update for dependency $packageName"
	}
	return $PackageFileContent
}

<#
  .Description
  Update a package file with a input list of dependencies.
  
  .Parameter ProjectName
  Name of the current project
  
  .Parameter dependencies
  List of dependencies obtained from configration file.
  
  .Parameter PackageFileName
  Name of the package file
  
  .Outputs
  true or false
#>
function Update-NodeDependenciesSub {
	param (
		[string]$ProjectName,
		$Dependencies,
		[string]$PackageFileName
	)
	
	# Update each file.
	foreach ($project in $(Get-ChildItem -Filter $PackageFileName -Recurse)) {
		$pkgFileContent = $(Get-Content $project.FullName -Raw)
		$changeMade = $false
		# Update each package file with dependency versions.
		foreach ($dependency in $Dependencies) {
			$returnedContent = Update-NodePackageDependency -ProjectName $dependency -PackageFileContent $pkgFileContent
			if ($returnedContent -ne $pkgFileContent) {
				$pkgFileContent = $returnedContent
				$changeMade = $true
			}
		}
		
		# If is remote_package.json, then also update internal dependencies.
		if ($PackageFileName -match "remote_package.json") {
			$returnedContent = Update-NodePackageDependency -ProjectName $ProjectName -PackageFileContent $pkgFileContent
			if ($returnedContent -ne $pkgFileContent) {
				$pkgFileContent = $returnedContent
				$changeMade = $true
			}
		}
		
		# Check if package files have been updated.
		if ($changeMade) {
			Write-Host "# Dependency version has been updated. Update the $($project.FullName) content."
			Set-Content $project.FullName -Value $pkgFileContent
			if (!$?) {
				Write-Host "# ERROR: Failed to update the $project.FullName content."
				return $false
			}
			
			# Stage the change
			git add $project.FullName
			if (!$?) {
				Write-Host "# ERROR: Failed to stage the change."
				return $false
			}
		}
	}
	return $true
}

<#
  .Description
  Update dependencies of all Node packages in a project.
  
  .Parameter ConfigFile
  Full path to a configration file
  
  .Outputs
  true or false
#>
function Update-NodePackageDependencies {
	param (
		[string]$ProjectName
	)
	
	Write-Host ""
	Write-Host "Update Node Package Dependencies"
	Write-Host "================================="
	
	$dependencies = $global:projects."$ProjectName".dependencies
	# Make sure only update if there are dependencies
	if ($dependencies -ne $null -and $dependencies.count -gt 0) {
		# Update package.json files
		Write-Host "# Update package.json files"
		Update-NodeDependenciesSub -ProjectName $ProjectName -Dependencies $dependencies -PackageFileName "package.json"
		
		# Update remote-package.json files
		Write-Host "# Update remote_package.json files"
		Update-NodeDependenciesSub -ProjectName $ProjectName -Dependencies $dependencies -PackageFileName "remote_package.json"
	} else {
		Write-Host "# There is no dependencies defined in configuration file. Skipped."
	}
	
	return $true
}

<#
  .Description
  Update dependencies of all Python packages in a project.
  In Python, package version is determined by what being
  present at run time. Thus, this function only update the
  package version being used for testing pipeline.
  
  .Parameter ConfigFile
  Full path to a configration file
  
  .Outputs
  true or false
#>
function Update-PythonPackageDependencies {
	param (
		[string]$ProjectName
	)
	
	Write-Host ""
	Write-Host "Update Python Package Dependencies"
	Write-Host "================================="
	
	$dependencies = $global:projects."$ProjectName".dependencies
	if ($dependencies -ne $null -and $dependencies.count -gt 0) {
		# Check if shared-variables.yml exists
		if (Test-Path ci\shared-variables.yml) {
			$sharedVariablesContent = $(Get-Content ci\shared-variables.yml -Raw)
			$changeMade = $false
			foreach ($dependency in $dependencies) {
				$versionVariableName = $global:projects."$dependency".versionVariableName
				if ($sharedVariablesContent -match "(?<prefix>name\s*:\s*$versionVariableName\s*\r\n\s*value\s*:\s*)'==\d+\.\d+\.\d+'") {
					Write-Host "# Version variable matches dependency $versionVariableName. Update."
					Write-Host $Matches['prefix']
					$dependencyVersion = $global:projects."$dependency".version
					$replaceString = '${prefix}' + "'==$dependencyVersion'"
					Write-Host $replaceString
					$sharedVariablesContent = $sharedVariablesContent -replace `
						"(?<prefix>name\s*:\s*pipelineVersion\s*\r\n\s*value\s*:\s*)'==\d+\.\d+\.\d+'", `
						$replaceString
					Write-Host $sharedVariablesContent
					$changeMade = $true
				} else {
					Write-Host "# Nothing to update for dependency $versionVariableName"
				}
			}
			
			# Check if shared-variables.yml has been updated.
			if ($changeMade) {
				Write-Host "# Dependency version has been updated. Update the shared-variables.yml content."
				Set-Content ci\shared-variables.yml -Value $sharedVariablesContent
				if (!$?) {
					Write-Host "# ERROR: Failed to update the shared-variables.yml content."
					return $false
				}
				
				# Stage the change
				git add ci\shared-variables.yml
				if (!$?) {
					Write-Host "# ERROR: Failed to stage the change."
					return $false
				}
			}
		} else {
			Write-Host "# ERROR: No shared-variables.yml file is found at this directory. Nothing to update."
			return $false
		}
	} else {
		Write-Host "# There is no dependencies defined in configuration file. Skipped."
	}
	
	return $true
}

<#
  .Description
  Update dependencies of all packages in a project.
  This determine the type of package based on project name.
  Any change will be automatically staged.
  
  .Parameter ConfigFile
  Full path to a configration file
  
  .Outputs
  true or false
#>
function Update-PackageDependencies {
	param (
		[string]$ConfigFile
	)
	
	# Initialise the global variables
	Initialize-GlobalVariables -ConfigFile $ConfigFile
	
	# Get repository name
	$repoName = Get-RepositoryName
	
	$succeeded = $true
	# Determine the type of package based on languages
	switch -Wildcard ("$repoName") {
		"*java" {
			Write-Host "# $repoName is a Maven package."
			$succeeded = Update-MavenPackageDependencies -ProjectName $repoName
			Break
		}
		"*dotnet" {
			Write-Host "# $repoName is a Dotnet package."
			$succeeded = Update-DotnetPackageDependencies -ProjectName $repoName
			Break
		}
		"*node" {
			Write-Host "# $repoName is a Node package."
			$succeeded = Update-NodePackageDependencies -ProjectName $repoName
			Break
		}
		"*python" {
			Write-Host "# $repoName is a Python package."
			$succeeded = Update-PythonPackageDependencies -ProjectName $repoName
			Break
		}
		Default {
			Write-Host "# $repoName is of type that do not need to update package."
			Break
		}
	}
	
	return $succeeded
}

Export-ModuleMember -Function Update-PackageDependencies