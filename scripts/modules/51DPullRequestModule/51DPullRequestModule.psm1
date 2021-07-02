<#
  ===================== Pull Request =====================
  .Description
  This module contains functions that perform actions on
  Azure Devops pull requests.
  For more information, please read description of
  each function.
#>

# Global variables to be updated when one of the main APIs is called.
$global:releaseConfig = $null
$global:projects = $null

<#
  .Description
  Get the existing pull request to 'main' branch.
  
  .Parameter ProjectName
  Name of the project
  
  .Parameter ReleaseBranch
  Ref of the release branch
  
  .Outputs
  A pull request object based on Azure Devops definition.
  $null if nothing is found.
#>
function Get-PullRequestToMain {
	param (
		[string]$ProjectName,
		[string]$ReleaseBranch
	)
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/pullrequests?api-version=6.0"
	
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to get the list of existing pull requests for $ProjectName.")){
		$content = $response.content | Out-String | ConvertFrom-Json
		for ($i = 0; $i -lt $content.value.count; $i++) {
			if ($content.value[$i].sourceRefName -match "$ReleaseBranch$" `
				-and $content.value[$i].targetRefName -match "refs/heads/(master|main)" `
				-and $content.value[$i].status -eq "active") {
				Write-Host "# Matching Pull Request: " $content.value[$i]
				return $content.value[$i]
			}
		}
	} else {
		Write-Host "# ERROR: Rest API call fails."
	}
	return $null
}

<#
  .Description
  Create a pull to 'main' branch.
  
  .Parameter ProjectName
  Name of a project
  
  .Parameter SourceBranchRef
  Full reference of the source branch. (i.e. prefixed with 'refs/heads')
  
  .Outputs true or false
#>
function Create-PullRequestToMain {
	param (
		[string]$ProjectName,
		[string]$SourceBranchRef
	)
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/pullrequests?api-version=6.0"
	$mainBranch = $(Get-MainBranchRef -ProjectName $ProjectName)
	$prTitle = "Merge branch '$SourceBranchRef' into '$mainBranch'"
	$jsonBody = @"
	{
		"title" : "$prTitle",
		"sourceRefName" : "$SourceBranchRef",
		"TargetRefName" : "$mainBranch"
	}
"@
	Write-Host "$jsonBody"

	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method POST `
	-ContentType "application/json" `
	-Body $jsonBody
	
	return $(Test-RestResponse `
		-Response $response `
		-ErrorMessage "Failed to create a pull request.")
}

<#
  .Description
  Decide an action on a release branch. Either request a test pipeline
  if a pull request eixsts, or create a new one.
  
  .Parameter ProjectName
  Name of the project
  
  .Parameter ReleaseBranch
  Full reference of the release branch.
  
  .Outputs
  True or False
#>
function Start-ProcessPullRequest {
	param (
		[string]$ProjectName,
		[string]$ReleaseBranch
	)
	
	# Check if a Pull Request already exist
	$pullRequest = Get-PullRequestToMain -ProjectName $ProjectName -ReleaseBranch $ReleaseBranch
	
	if ($pullRequest -ne $null) {
		Write-Host "# Pull request exists. Requeue the test pipeline."
		#Rerun the build-and-test pipeline for this pull request.
		return $(Restart-TestBuild `
			-ProjectName $ProjectName `
			-PullRequestId $pullRequest.pullRequestId)
	} else {
		Write-Host "# Pull request does not exist. Create one."
		#Create a pull request which should trigger the build-and-test pipeline.
		return $(Create-PullRequestToMain `
			-ProjectName $ProjectName `
			-SourceBranchRef $ReleaseBranch)
	}
}

<#
  .Description
  Check if all required votes for a pull requests have been approved.
  
  .Parameter ProjectName
  Name of the project that the PR belongs to
  
  .Parameter PullRequestId
  Id number of a pull request.
  
  .Outputs true or false
#>
function Test-PullRequestVotes {
	param (
		[string]$ProjectName,
		[int32]$PullRequestId
	)
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/pullrequests/$($PullRequestId)?api-version=6.0"
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse -Response $response -ErrorMessage "Failed to get pull request details.")) {
		$content = $response.content | Out-String | ConvertFrom-Json
		foreach ($reviewer in $content.reviewers) {
			if ($reviewer.isRequired `
				-and $reviewer.vote -ne 10 `
				-and $reviewer.vote -ne 5) {
				Write-Host "# Required reviewer has not accepted the PR."
				return $false
			}
		}
		return $true
	}
	return $false
}

<#
  .Description
  Check if all comments have been resolved for a pull request.
  
  .Parameter ProjectName
  Name of a project that a pull request belongs to.
  
  .Parameter PullRequestId
  Id number of a pull request.
  
  .Outputs true or false.
#>
function Test-PullRequestComments {
	param (
		[string]$ProjectName,
		[int32]$PullRequestId
	)
	
	$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/pullrequests/$($PullRequestId)/threads?api-version=6.0"
	$response = Invoke-WebRequest `
	-URI $url `
	-Headers @{
		Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
	} `
	-Method GET
	
	if ($(Test-RestResponse -Response $response -ErrorMessage "Failed to get pull request threads.")) {
		$content = $response.content | Out-String | ConvertFrom-Json
		foreach ($thread in $content.value) {
			if ($thread.status -eq "active") {
				Write-Host "# Comment has not been resolved."
				return $false
			}
		}
		return $true
	}
	return $false
}

<#
  .Description
  Complete a pull request.
  
  .Parameter ProjectName
  Name of a project that the pull request belongs to.
  
  .Parameter PullRequestId
  Id number of a pull request.
  
  .Parameter ApprovalRequired.
  Whether approval is required to complete.
  
  .Outputs true or false.
#>
function Complete-PullRequest {
	param (
		[string]$ProjectName,
		[int32]$PullRequestId,
		[bool]$ApprovalRequired
	)
	
	$canComplete = $false
	if (!$ApprovalRequired) {
		Write-Host "# No approval is required. Bypass any policies."
		$canComplete = $true
	} elseif ((-$(Test-PullRequestVotes -ProjectName $ProjectName -PullRequestId $PullRequestId) `
		-and $(Test-PullRequestComments -ProjectName $ProjectName -PullRequestId $PullRequestId))) {
		Write-Host "# Pull request has been approved and no comments left unresolved."
		$canComplete = $true
	}
	
	if ($canComplete) {
		# Get Last Merge Source Commit
		$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/pullrequests/$($PullRequestId)?api-version=6.0"
		Write-Host "$url"
		$response = Invoke-WebRequest `
		-URI $url `
		-Headers @{
			Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
		} `
		-Method GET
	
		if ($(Test-RestResponse -Response $response -ErrorMessage "Failed to get pull request info.")) {
			$content = $response.content | Out-String | ConvertFrom-Json
			$lastMergeSourceCommit = $content.lastMergeSourceCommit.commitId
			
			$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$ProjectName/pullrequests/$($PullRequestId)?api-version=6.0"
			$jsonBody = @"
			{
				"lastMergeSourceCommit" : {
					"commitId" : "$lastMergeSourceCommit"
				},
				"status" : "completed",
				"completionOptions" : {
					"bypassPolicy" : true,
					"bypassReason" : "Auto Release Process"
				}
			}
"@

			$response = Invoke-WebRequest `
			-URI $url `
			-Headers @{
				Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
			} `
			-Method PATCH `
			-ContentType "application/json" `
			-Body $jsonBody
			
			return $(Test-RestResponse -Response $response -ErrorMessage "Failed to complete pull request.")
		} else {
			return $false
		}
		
	} else {
		Write-Host "# Can't complete pull request as comments has not been resolved or reviewer has not approved."
		return $false
	}
}

<#
  .Description
  Check if a pull request is from a release/hotfix branch to main.
  
  .Parameter PullRequestId
  The id number of a pull request
  
  .Outputs
  true or false
#>
function Test-IsReleasePullRequest {
	param (
		[int32]$PullRequestId
	)
	
	$prSourceBranch = $Env:SYSTEM_PULLREQUEST_SOURCEBRANCH
	$prTargetBranch = $Env:SYSTEM_PULLREQUEST_TARGETBRANCH
	$repoName = $Env:BUILD_REPOSITORY_NAME # This should always be available.
	# If the source or target branch is not available from environment variables
	# Try the query it using the REST api.
	if ($prSourceBranch -eq $null `
		-or $prTargetBranch -eq $null) {
		$url = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/git/repositories/$repoName/pullrequests/$($PullRequestId)?api-version=6.0"
		$response = Invoke-WebRequest `
		-URI $url `
		-Headers @{
			Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
		} `
		-Method GET
		
		if (Test-RestResponse `
			-Response $response `
			-ErrorMessage "Failed to query pull request details.") {
			$content = $response.content | Out-String | ConvertFrom-Json
			$prSourceBranch = $content.sourceRefName
			$prTargetBranch = $content.targetRefName
		} else {
			Write-Host "# ERROR: Can obtain source and target branch of the pull request $PullRequestId."
			return $false
		}
	}
	
	if ($prSourceBranch -match "refs/heads/(release|hotfix)/v?(?<version>\d+\.\d+\.\d+)") {
		Write-Host "# Pull request is from a release/hotfix branch."
		$prVersion = $Matches['version']
	} else {
		Write-Host "# Pull request is not from a release/hotfix branch."
		return $false
	}
	
	if (!$($prTargetBranch -match "refs/heads/(main|master)")) {
		Write-Host "# Pull request is not to the 'main' branch."
		return $false
	}
	
	# Check if the pull request is from a release target versions.
	# Get the module name
	$targetVersion = $global:projects."$repoName".version
	if ($prVersion -eq $targetVersion) {
		Write-Host "# Pull request matches the target release version. Proceed to complete."
	} else {
		Write-Host "# Pull request does not match the target release version. `
			The pull request version is $prVersion, while the target version is $targetVersion. `
			Do not proceed."
		return $false
	}
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
	Write-Host "# Initialise form configuration file: " + $ConfigFile
	$global:releaseConfig = Get-Content $ConfigFile | Out-String | ConvertFrom-Json
	$global:projects = $global:releaseConfig.projects
	Write-Host "# Init config: " + $global:releaseConfig
	Write-Host "# Init projects: " + $global:projects
}

<#
  .Description
  If the script is called in a build running on a pullrequest branch, try
  to complete the corresponding pull request.
	
  .Parameter ConfigFile
  Path to the configration file
  
  .Outputs
  true or false
  NOTE: The only time when this should return false is when the build is
  triggered by a pull request and it failed to complete the pull request.
#>
function Complete-CorrespondingPullRequest {
	param (
		[string]$ConfigFile
	)

	# Initialise global variables
	Initialize-GlobalVariables -ConfigFile $ConfigFile

	# Get pull request
	Write-Host "Build.SourceBranch: " $Env:BUILD_SOURCEBRANCH
	Write-Host "System.PullRequest.SourceBranch: " $Env:SYSTEM_PULLREQUEST_SOURCEBRANCH
	Write-Host "System.PullRequest.TargetBranch: " $Env:SYSTEM_PULLREQUEST_TARGETBRANCH
	Write-Host "Build.Repository.Name: " $Env:BUILD_REPOSITORY_NAME
	$sourceBranch = $Env:BUILD_SOURCEBRANCH
	if ($sourceBranch -match "refs/pull/(?<content>\d+)/merge") {
		Write-Host "# Triggered by a pull request."
		$pullRequestId = $Matches['content']
		if ($(Test-IsReleasePullRequest -PullRequestId $pullRequestId)) {
			if ($(Update-SubmoduleReferences -ConfigFile $ConfigFile)) {
				# Check if any changes are required. If there are, submodules are not up to date.
				if ($(git diff --cached --name-only).count -eq 0 ) {
					Write-Host "# All submodules are up to date. Complete the corresponding pull request now."
					# Complete the pull request
					if (!$(Complete-PullRequest `
						-ProjectName $Env:BUILD_REPOSITORY_NAME `
						-PullRequestId $pullRequestId `
						-ApprovalRequired $global:releaseConfig.approvalRequired)) {
						Write-Host "# ERROR: Cannot complete the pull request $pullRequestId."
						return $false
					}
				} else {
					Write-Host "# ERROR: Not all submodules are up to date. Don't complete the pull request."
					return $false
				}
			} else {
				Write-Host "# ERROR: Failed to check if all submodules are up to date."
				return $false
			}
		} else {
			Write-Host "# Not a release pull request. Nothing to complete."
			return $false
		}
	} else {
		Write-Host "# Not triggered by a pull request. Nothing to complete."
		return $false
	}
	return $true
}

Export-ModuleMember -Function Get-PullRequestToMain
Export-ModuleMember -Function Create-PullRequestToMain
Export-ModuleMember -Function Start-ProcessPullRequest
Export-ModuleMember -Function Complete-CorrespondingPullRequest