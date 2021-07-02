<#
  ===================== Release =====================
  .Description
  This module contains functions that perform package
  release actions.
  For more information, please read description of
  each function.
#>

# Read-only global variables. These variables are accessed for global read-only information.
# No functions should make changes to these variables.
$global:releaseConfig = ""
$global:projects = ""

# Shared global list of projects that require action and projects
# that have been processed. These are allowed to be updated by
# Get-*-Action functions.
$global:actionTable = @{} # key is project name, value is true or false
$global:traveledTable = @{} # key is project name, value is true or false

<#
  .Description
  Get whether a project release version need action.
  The function will update the list of traveled nodes
  and the list of action required nodes.
  
  .Parameter ProjectName
  Name of the project
  
  .Parameter Version
  The target version
#>
function Get-LeafAction {
	param (
		[string]$ProjectName,
		[string]$Version
	)
	
	# If a tag exist, don't do anything and return.
	if(!$global:traveledTable[$ProjectName]) {
		if (!$(Get-Tag -ProjectName $ProjectName -Version $Version)) {
			$global:actionTable[$ProjectName] = $true
		}
		$global:traveledTable[$ProjectName] = $true
	}
}

<#
  .Description
  Get whether a project release version need action.
  Further information of the dependencies are acquired
  from the global release configuration object.
  The function will update the list of traveled nodes
  and the list of action required nodes.

  .Parameter ProjectName
  Name of the project
  
  .Parameter Version
  The target version
  
  .Parameter Dependencies
  Dependencies of the project
#>
function Get-NonLeafAction {
	param (
		[string]$ProjectName,
		[string]$Version,
		[string[]]$Dependencies
	)

	# If a tag exist, don't do anything and return.
	if(!$global:traveledTable[$ProjectName]) {
		if(!$(Get-Tag -ProjectName $ProjectName -Version $Version)) {
			$global:traveledTable[$ProjectName] = $true			
			foreach ($dependency in $Dependencies) {
				# Check if action required for a dependency.
				if (!$global:traveledTable[$dependency]) {
					Get-Action -PojectName $dependency
				}
				
				# If action is required for a dependency,
				# then no action for this node.
				if ($global:actionTable[$dependency]) {
					return
				}
			}
			$global:actionTable[$ProjectName] = $true
		}
	}
}

<#
  .Description
  Get whether a project need action. The function
  will obtain the target version and other information
  from the global release configuration object.
  The function will update the list of traveled nodes
  and the list of action required nodes.
  The algorithm is straighforward, providing the script
  is single threaded.
  For a project, if it is a leaf node, process to determine action.
  If it is not a leaf node, check the dependencies to determine action.
  Update the action required list and the traveled list in flight.
  
  .Parameter ProjectName
  Name of the project
#>
function Get-Action {
	param (
		[string]$ProjectName
	)
	
	$version = $global:releaseConfig.projects."$ProjectName".version
	$isLeaf = $global:releaseConfig.projects."$ProjectName".isLeaf
	
	if ($isLeaf) {
		$needAction = Get-LeafAction -ProjectName $ProjectName -Version $version
	} else {
		$dependencies = $global:releaseConfig.projects."$ProjectName".dependencies
		$needAction = Get-NonLeafAction -ProjectName $ProjectName -Version $version -Dependencies $dependencies
	}
}

<#
  .Description
  Bump release version. This checkout the 'main' branch and
  update the release GitVersion.
  
  .Parameter ProjectName
  Name of a project
  
  .Parameter Version
  Target release version.
  
  .Outputs true or false
#>
function Update-Version {
	param (
		$ProjectName,
		$Version
	)
	
	Write-Host "# Bump release version of project $ProjectName to $Version."
	
	# Checkout the project main branch
	$mainBranch = Get-MainBranchRef -ProjectName $ProjectName
	$remoteUrl = Get-RepositoryRemoteUrl -ProjectName $ProjectName
	if ($remoteUrl -ne $null) {
		git -c http.extraheader="AUTHORIZATION: Bearer $env:SYSTEM_ACCESSTOKEN" clone $remoteUrl
		if ($?) {
			Push-Location $ProjectName

			# Checkout the main branch
			if ($(git rev-parse --abbrev-ref HEAD) -notmatch "(master|main)") {
				git checkout $mainBranch
				if ($?) {
					Write-Host "# Successfully checkout main branch."
				} else {
					Write-Host "# ERROR: Failed to checkout main branch."
					Pop-Location
					return $false
				}
			} else {
				Write-Host "# Currently on $mainBranch."
			}
			
			if ($(Test-Path GitVersion.yml)) {
				# Update the GitVersion number to the target release version.
				Write-Host "# GitVersion.yml exists. Update the file with the next version $Version."
				if ($(Get-Content GitVersion.yml) -match ".*next-version.*") {
					$versionFileContent = $(Get-Content GitVersion.yml) -replace "next-version.*(\r\n)?", "next-version: 1.1`r`n"
				} else {
					$versionFileContent = $(Get-Content GitVersion.yml)
					$versionFileContent = "next-version: $Version`r`n" + $versionFileContent
				}
				Set-Content GitVersion.yml -Value $versionFileContent
			} else {
				Write-Host "# GitVersion.yml does not exist. Create one."
				Set-Content GitVersion.yml -Value "next-version: $Version"
			}
			
			if (!$?) {
				Write-Host "# ERROR: Failed to update the content of GitVersion.yml"
				Pop-Location
				return $false
			}
	
			# Commit the changes
			git add GitVersion.yml
			git commit -m "BUILD: Bump GitVersion next-version to $Version."
			if (!$?) {
				Write-Host "# ERROR: Failed to commit change."
				Pop-Location
				return $false
			}
	
			# Push the changes
			git -c http.extraheader="AUTHORIZATION: Bearer $env:SYSTEM_ACCESSTOKEN" push
			if (!$?) {
				Write-Host "# ERROR: Failed to push to remote."
				Pop-Location
				return $false
			}
			
			Pop-Location
		} else {
			Write-Host "# ERROR: Failed to clone repository $ProjectName."
			return $false
		}
	} else {
		Write-Host "# ERROR: No remote url found for project $ProjectName."
		return $false
	}
	Write-Host "# OK"
	return $true
}

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
	$global:releaseConfig = Get-Content $ConfigFile | Out-String | ConvertFrom-Json
	$global:projects = $global:releaseConfig.projects | Get-Member -MemberType NoteProperty
	$global:actionTable = @{} # key is project name, value is true or false
	$global:traveledTable = @{} # key is project name, value is true or false
}

<#
  .Description
  Main function. Trigger the release process.
  
  .Parameter ConfigFile
  Path to the configration file
  
  .Outputs
  True or False
#>
function Start-Release {
	param (
		[string]$ConfigFile
	)

	# Reinitialise the global variables.
	Initialize-GlobalVariables -ConfigFile $ConfigFile
	
	# Loop through all projects and determine the ones that need further action.
	Write-Host ""
	Write-Host "Check projects for required actions."
	Write-Host "================================="
	foreach ($project in $global:projects) {
		Write-Host "# Check action for project $($project.Name)."
		Get-Action -ProjectName $project.Name
	}
	
	# Perform actions on the projects that require.
	foreach ($project in $global:actionTable.keys) {
		Write-Host ""
		Write-Host "Take action on project: $project."
		Write-Host "================================="
		$version = $global:releaseConfig.projects."$project".version
		$releaseBranch = Get-ReleaseBranchRef -ProjectName $project -Version $version
		if ($releaseBranch -ne $null) {
			Write-Host "# Process pull request on branch $releaseBranch."
			if (!$(Start-ProcessPullRequest -ProjectName $project -ReleaseBranch $releaseBranch)) {
				Write-Host "# ERROR: Failed to process pull request."
				return $false
			}
		} else {
			Write-Host "# Bump the release version to $version."
			if (!$(Update-Version -ProjectName $project -Version $version)) {
				Write-Host "# ERROR: Failed to bump version."
				return $false
			}
		}
	}
	return $true
}

<#
  .Description
  This work on the current directory, performing updating of
  submodule references, updating package dependencies, commit
  the changes and create a pull request if needed.
  
  .Parameter ConfigFile
  Full path to the configuration file.
  
  .Outputs
  true or false
#>
function Update-CommitPushPull {
	param (
		[string]$ConfigFile
	)

	Initialize-GlobalVariables -ConfigFile $ConfigFile
	$repoName = Get-RepositoryName
	$targetVersion = $global:projects."$repoName".version
	if ($targetVersion -eq $null) {
		Write-Host "# No release version is specified for $repoName. Stop."
		return $true
	}
	
	# Checkout release branch to update
	if (!$(Get-ReleaseBranch -Version $targetVersion)) {
		return $false
	}

	# Update the submodule references
	if (!$(Update-SubmoduleReferences -ConfigFile $ConfigFile)) {
		return $false
	}
	
	# Update the package dependencies
	if (!$(Update-PackageDependencies -ConfigFile $ConfigFile)) {
		return $false
	}
	
	# Commit and push any changes.
	if (!$(Start-CommitAndPush)) {
		return $false
	}
	
	Write-Host ""
	Write-Host "Create Pull Request if one doesn't exist"
	Write-Host "================"
	$targetBranch = Get-TargetBranch -Version $targetVersion
	$pullRequest = Get-PullRequestToMain -ProjectName $repoName -ReleaseBranch "refs/heads/$targetBranch"
	if ($pullRequest -eq $null) {
		if (!(Create-PullRequestToMain -ProjectName $repoName -SourceBranchRef "refs/heads/$targetBranch")) {
			return $false
		}
	} else {
		Write-Host "# A pull request to 'main' already exists. No need to create a new one."
	}
	return $true
}

Export-ModuleMember -Function Start-Release
Export-ModuleMember -Function Update-CommitPushPull