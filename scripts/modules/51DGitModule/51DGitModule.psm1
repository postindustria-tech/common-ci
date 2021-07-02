<#
  ===================== Git =====================
  .Description
  This module contains functions that perform Git
  actions.
  For more information, please read description of
  each function.
#>

# For testing purpose only
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
  Determine whether a release is a major release or a hotfix.
  
  .Parameter Version
  Version of a project
  
  .Outputs
  Type of release
#>
function Get-ReleaseType {
	param (
		[string]$Version
	)
	
	# Determine if version is minor or major
	$isMajor = $Version -match '\d+\.\d+\.0'

	# Determine the target release/hotfix branch
	if ($isMajor) {
		$type = "release"
	} else {
		$type = "hotfix"
	}
	return $type
}

<#
  .Description
  Determine if a tag has been created
  for a version of a project.

  .Parameter ProjectName
  Name of the project
  
  .Parameter Version
  Release version of the project
#>
function Get-Tag {
	param (
		[string]$ProjectName,
		[string]$Version
	)
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/refs?api-version=6.0&filter=tags/$Version"
	
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to get all tags which started with $Version for $ProjectName.")){
		$content = $response.content | Out-String | ConvertFrom-Json
		for ($i = 0; $i -le $content.value.count; $i++) {
			if ($content.value[$i].name -match "$Version(\+\d+)?$") {
				return $true
			}
		}
	}
	return $false
}

<#
  .Description
  Get the existing release branch.
  
  .Parameter ProjectName
  Name of the project
  
  .Parameter Version
  Target release version of the project.
  
  .Outputs
  Full name of the release branch, prefixed with 'refs/heads' or $null if not found.
#>
function Get-ReleaseBranchRef {
	param (
		[string]$ProjectName,
		[string]$Version
	)
	
	$releaseType = Get-ReleaseType -Version $Version
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/refs?api-version=6.0&filter=heads/$releaseType/"
	
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to get the list of existing branches for $ProjectName.")){
		$content = $response.content | Out-String | ConvertFrom-Json
		for ($i = 0; $i -lt $content.value.count; $i++) {
			if ($content.value[$i].name -match "refs/heads/$releaseType/(v)?$Version$") {
				return $content.value[$i].name
			}
		}
	}
	return $null
}

<#
  .Description
  Construct a merge branch name from pull request Id.
  
  .Parameter PullRequestId
  Id number of a pull request
  
  .Outputs
  Full reference name of a merge branch.
#>
function Get-MergeBranchName {
	param (
		[int32]$PullRequestId
	)
	return "refs/pull/$PullRequestId/merge"
}

<#
  .Description
  Get the existing 'main' branch reference. It should be 'main'
  but can also be 'master' for older projects.
  
  .Parameter ProjectName
  Name of a project
  
  .Outputs
  Full reference to the 'main' branch.
#>
function Get-MainBranchRef {
	param (
		$ProjectName
	)
	
	$masterBranch = "master"
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/refs?filter=heads/$masterBranch&api-version=6.0-preview.1"
	
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to query the existence of the 'main' branch.")){
		$content = $response.content | Out-String | ConvertFrom-Json
		if ($content.value.count -eq 1) {
			return "refs/heads/$masterBranch"
		}
	}
	return "refs/heads/main"
}

<#
  .Description
  Get the remote Url to clone the project.
  
  .Parameter ProjectName
  Name of the project
  
  .Outputs
  Remote Url or $null if not found.
#>
function Get-RepositoryRemoteUrl {
	param (
		[string]$ProjectName
	)
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$($ProjectName)?api-version=6.0"
	
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to query repository $ProjectName.")){
		$content = $response.content | Out-String | ConvertFrom-Json
		return $content.remoteUrl
	}
	return $null
}

<#
  .Description
  Extract the submodule path from a git submodule entry.
  
  .Parameter GitSubmodulePath
  A git submodule entry.
  
  .Outputs
  A submodule path or $null if the submodule entry does not conform
  the standard format.
#>
function Find-SubmodulePath {
	param (
		[string]$GitSubmodulePath
	)
	
	if ($GitSubmodulePath -match "submodule\.(?<content>(.)+)\.path") {
		return $Matches['content']
	}
	return $null
}

<#
  .Description
  Determine the target branch to be assessed.
  
  .Parameter Version
  The version of a project
  
  .Outputs
  Target branch without 'refs/heads'.
#>
function Get-TargetBranch {
	param (
		[string]$Version
	)
	
	$releaseType = Get-ReleaseType -Version $Version
	
	# Determine whether the name should contains 'v' or not.
	$remoteRepo = git config --get remote.origin.url
	if (!$(git ls-remote $remoteRepo "refs/heads/$releaseType/$Version") -eq $null) {
		return $releaseType + "/" + $Version
	}
	return $releaseType + "/v" + $Version
}

<#
  .Description
  Get the repository name of current branch.
  
  .Outputs
  Repo name or $null if not found.
#>
function Get-RepositoryName {
	$remoteUrl = git config --get remote.origin.url
	if ($remoteUrl -match ".*/(?<content>((?!/).)*)") {
		return $Matches['content']
	}
	return $null
}

<#
  .Description
  Check if a branch exist in the remote repository.
  This run on the current git directory.
  
  .Parameter Branch
  Name of the branch.
  
  .Outputs true or false
#>
function Test-BranchExistRemotely {
	param (
		[string]$Branch
	)
	
	$remoteRepo = git config --get remote.origin.url
	$exists = $false
	if ($(git ls-remote $remoteRepo "refs/heads/$Branch") -ne $null) {
		$exists = $true
	}
	return $exists
}

<#
  .Description
  Check out a release branch based on the detail in the release config file.
  If no release is required, return false.

  .Parameter Version
  Version to release
  
  .Outputs
  true or false
#>
function Get-ReleaseBranch {
	param (
		[string]$Version
	)
	
	# Check if the release/hotfix branch exist. Create if it doesn't.
	Write-Host ""
	Write-Host "Verify release/hotfix branch existance"
	Write-Host "================"
	$targetBranch = Get-TargetBranch -Version $Version
	$remoteRepo = git config --get remote.origin.url
	if ($(git ls-remote $remoteRepo "refs/heads/$targetBranch") -eq $null) {
		Write-Host "# No $targetBranch exists. Create one."
		$repoName = Get-RepositoryName
		$mainBranchRef = Get-MainBranchRef -ProjectName $repoName
		if ($mainBranchRef -eq $null) {
			Write-Host "ERROR: No main branch found."
			return $false
		}
		$mainBranchRef -match "refs/heads/(?<name>(master|main))"
		$mainBranchName = $Matches['name']

		git checkout $mainBranchName
		if (!$?) {
			git checkout --track "origin/$mainBranchName"
			if (!$?) {
				Write-Host "# ERROR: Failed to checkout $mainBranchRef"
				return $false
			}
		}
		git pull
		if (!$?) {
			Write-Host "# ERROR: Failed to get the latest version of the main branch $mainBranchRef"
			return $false
		}
		
		git checkout -b $targetBranch
		if (!$?) {
			Write-Host "# ERROR: Failed to create target release branch $targetBranch"
			$false
		}
	} else {
		# NOTE: This might cause some issue as common-ci has been updated.
		# Might want to use 'git stash' to keep the changes."
		Write-Host "# $targetBranch exists. Checkout."
		git checkout --track "refs/heads/$targetBranch"
		if (!$?) {
			git checkout $targetBranch
			if (!$?) {
				Write-Host "# ERROR: Failed to checkout target release branch $targetBranch"
				return $false
			}
		}
		git pull
		if (!$?) {
			Write-Host "# ERROR: Failed to get the latest version of target release branch $targetBranch"
			return $false
		}
	}
	Write-Host "# OK"
	return $true
}

<#
  .Description
  Update all submodule references of a current git directory.
  This will run on the current directory.
  
  .Parameter ConfigFile
  Path to the release configuration file.
  
  .Outputs
  true or false.
#>
function Update-SubmoduleReferences {
	param (
		[string]$ConfigFile
	)

	# Load the configuration into global variables.
	Initialize-GlobalVariables -ConfigFile $ConfigFile
	
	# Check if all submodules have been deployed
	Write-Host ""
	Write-Host "Update all submodules"
	Write-Host "================"
	foreach ($submodule in $(git config --file .gitmodules --name-only --get-regexp path)) {
		Write-Host ""
		Write-Host "# Process submodule path $submodulePath."
		$submodulePath = Find-SubmodulePath -GitSubmodulePath $submodule
		if ($submodulePath -ne $null) {
			Write-Host "# Path $submodulePath extracted."
			Push-Location $submodulePath
			
			# Get repo name
			$subRepoName = Get-RepositoryName
			Write-Host "# Processing module $subRepoName."
			
			# Check and update the submodule to the correct tag.
			$targetTag = $global:projects."$subRepoName".version
			
			# Get all tag
			git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" fetch --all --tags
			if (!$?) {
				Write-Host "# ERROR: Failed to fetch tags. Cannot reliably check submodule deployment."
				Pop-Location
				return $false
			}
			
			$tagUpdated = $false
			if ($targetTag -ne $null) {
				$remoteRepo = git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" config --get remote.origin.url
				# Make sure to sort the tag, so only pick up the biggest tag.
				# e.g. If 4.3.0 and 4.3.0+1 then pick the later.
				foreach ($tag in $(git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" ls-remote --tags --sort=-v:refname $remoteRepo "$($targetTag)*")) {
					# By presorted the tags, the first only that match the tag format will be the latest one.
					if ($tag -match ".*/(?<content>$targetTag(\+(\d)+)?)$") {
						Write-Host "# Tag $targetTag found with value $($Matches['content']). The submodule has been been deployed."
	
						git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" checkout "tags/$($Matches['content'])"
						if (!$?) {
							Write-Host "# ERROR: Failed to checkout the tag $($Matches['content'])."
							break
						}
						
						$tagUpdated = $true
						break
					}
				}
			} else {
				# If no version is found from the configuration file.
				# Treat it as nothing to be changed for this submodule.
				Write-Host "# No target version has been specified for $subRepoName. No update required."
				$tagUpdated = $true
			}
			
			Pop-Location
			
			# Exit if not all tags have been found.
			if (!$tagUpdated) {
				Write-Host "# ERROR: Failed to update Submodule $subRepoName to tag $targetTag."
				return $false
			}
			
			# Stage the submodule update
			Write-Host "# Stage the submodule $submodulePath"
			git add $submodulePath
			if (!$?) {
				Write-Host "# ERROR: Failed to stage the submodule $subRepoName."
				return $false
			}
		} else {
			Write-Host "# ERROR: Failed to extract module path from $submodulePath"
			return $false
		}
	}
	
	Write-Host "# OK"
	return $true
}

<#
  .Description
  Commit any staged changes and push to remote repository.
  
  .Outputs
  true or false
#>
function Start-CommitAndPush {
	# Commit changes
	Write-Host ""
	Write-Host "# Commit and push staged changes."
	Write-Host "================"
	$branchName = git rev-parse --abbrev-ref HEAD
	$existingBranch = Test-BranchExistRemotely -Branch $branchName
	git status
	git config user.email "ciuser@51degrees.com"
	git config user.name "CIUser"
	if ($(git diff --cached --name-only).count -gt 0 ) {
		Write-Host "# There are changes. Commit now."
		git commit -m "REF: Update submodules references."
		if (!$?) {
			Write-Host "# ERROR: Failed to commit the submodules updates."
			return $false
		}
		
		# Push changes
		Write-Host "# Push the changes."
		if (!$existingBranch) {
			git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push origin "$branchName"
		} else {
			git -c http.extraheader="AUTHORIZATION: bearer $env:SYSTEM_ACCESSTOKEN" push
		}
		
		if (!$?) {
			Write-Host "# ERROR: Failed to push changes."
			return $false
		}
	} else {
		Write-Host "# There is nothing to commit."
	}
	return $true
}