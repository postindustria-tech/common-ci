Describe 'Update-PackageDependencies' {
	It 'successfully update all package version java' {
		Mock Initialize-GlobalVariables { } `
			-ModuleName 51DPackageModule
		Mock Get-RepositoryName { return 'test-java' } `
			-ModuleName 51DPackageModule
		Mock Update-MavenPackageDependencies { return $true } `
			-ModuleName 51DPackageModule
		$result = Update-PackageDependencies `
			-Configuration $(New-Object -TypeName Object) `
			-TeamProjectName "testproj"
		$result | Should -BeExactly $true
	}
	
	It 'successfully update all package version dotnet' {
		Mock Initialize-GlobalVariables { } `
			-ModuleName 51DPackageModule
		Mock Get-RepositoryName { return 'test-dotnet' } `
			-ModuleName 51DPackageModule
		Mock Update-DotnetPackageDependencies { return $true } `
			-ModuleName 51DPackageModule
		$result = Update-PackageDependencies `
			-Configuration $(New-Object -TypeName Object) `
			-TeamProjectName "testproj"
		$result | Should -BeExactly $true
	}
	
	It 'successfully update all package version node' {
		Mock Initialize-GlobalVariables { } `
			-ModuleName 51DPackageModule
		Mock Get-RepositoryName { return 'test-node' } `
			-ModuleName 51DPackageModule
		Mock Update-NodePackageDependencies { return $true } `
			-ModuleName 51DPackageModule
		$result = Update-PackageDependencies `
			-Configuration $(New-Object -TypeName Object) `
			-TeamProjectName "testproj"
		$result | Should -BeExactly $true
	}
	
	It 'successfully update all package version python' {
		Mock Initialize-GlobalVariables { } `
			-ModuleName 51DPackageModule
		Mock Get-RepositoryName { return 'test-python' } `
			-ModuleName 51DPackageModule
		Mock Update-PythonPackageDependencies { return $true } `
			-ModuleName 51DPackageModule
		$result = Update-PackageDependencies `
			-Configuration $(New-Object -TypeName Object) `
			-TeamProjectName "testproj"
		$result | Should -BeExactly $true
	}
	
	It 'package does not need to be updated' {
		Mock Initialize-GlobalVariables { } `
			-ModuleName 51DPackageModule
		Mock Get-RepositoryName { return 'test-php-core' } `
			-ModuleName 51DPackageModule
		$result = Update-PackageDependencies `
			-Configuration $(New-Object -TypeName Object) `
			-TeamProjectName "testproj"
		$result | Should -BeExactly $true
	}
}

InModuleScope 51DPackageModule {
	Describe 'Update-PythonPackageContent' {
		BeforeAll {
			function Test-PythonSuccessfulVersionUpdate {
				param (
					[string]$SourceVersion
				)
				
				$depRepo = "dependent-python"
				$repoName = "test-python"
				$repoConfigStr = @"
				{
					"version": "4.3.0",
					"packageName": "test",
					"versionVariableName": "testVersion",
					"dependencies": [
						"$depRepo"
					]
				}
"@
				$repoConfig = $repoConfigStr | ConvertFrom-Json
				$reposStr = @"
				{
					"$repoName": $repoConfigStr,
					"$depRepo": {
						"version": "4.3.0",
						"packageName": "dep",
						"versionVariableName": "depVersion"
					}
				}
"@
				$repos = $reposStr | ConvertFrom-Json
				
				$configStr = @"
				{
					"repositories": $reposStr
				}
"@
				$config = $configStr | ConvertFrom-Json
				
				# Initialize script scope variable
				Initialize-GlobalVariables -Configuration $config
				
				Mock Test-TagExist { return $true } `
					-ModuleName 51DPackageModule
				$content = "name: depVersion`r`nvalue: '==$SourceVersion'"
				$updatedContent = Update-PythonPackageContent `
					-Dependencies $repoConfig.dependencies `
					-SharedVariableContent $content `
					-TeamProjectName "TestProject"
				$updatedContent | Should -BeExactly "name: depVersion`r`nvalue: '==4.3.0'"
			}
		}

		It 'successfully update the content with well formed version' {
			Test-PythonSuccessfulVersionUpdate -SourceVersion "0.0.0"
		}
		
		It 'successfully update the content with non release well formed version' {
			Test-PythonSuccessfulVersionUpdate -SourceVersion "0.0.0-beta.18+1"
		}
	}
}

InModuleScope 51DPackageModule {
	Describe 'Update-NodePackageDependencies' {
		It 'successfully update the package version' {
			$depRepo = "dependent-node"
			$repoName = "test-node"
			$repoConfigStr = @"
			{
				"version": "4.3.0",
				"packageName": "test.node",
				"dependencies": [
					"$depRepo"
				]
			}
"@
			$repoConfig = $repoConfigStr | ConvertFrom-Json
			$reposStr = @"
			{
				"$repoName": $repoConfigStr,
				"$depRepo": {
					"version": "4.3.0",
					"packageName": "dep.node"
				}
			}
"@
			$repos = $reposStr | ConvertFrom-Json
			$configStr = @"
			{
				"repositories": $reposStr
			}
"@
			$config = $configStr | ConvertFrom-Json
			
			# Initialize script scope variable
			Initialize-GlobalVariables -Configuration $config
			Mock Update-NodeDependenciesSub { return $true } `
				-ModuleName 51DPackageModule
			
			$result = Update-NodePackageDependencies `
				-RepositoryName $repoName `
				-TeamProjectName "testproject"
			$result | Should -BeExactly $true
		}
		
		It 'failed to update package dependencies' {
			$depRepo = "dependent-node"
			$repoName = "test-node"
			$repoConfigStr = @"
			{
				"version": "4.3.0",
				"packageName": "test.node",
				"dependencies": [
					"$depRepo"
				]
			}
"@
			$repoConfig = $repoConfigStr | ConvertFrom-Json
			$reposStr = @"
			{
				"$repoName": $repoConfigStr,
				"$depRepo": {
					"version": "4.3.0",
					"packageName": "dep.node"
				}
			}
"@
			$repos = $reposStr | ConvertFrom-Json
			$configStr = @"
			{
				"repositories": $reposStr
			}
"@
			$config = $configStr | ConvertFrom-Json
			
			# Initialize script scope variable
			Initialize-GlobalVariables -Configuration $config
			Mock Update-NodeDependenciesSub { return $false } `
				-ModuleName 51DPackageModule
			
			$result = Update-NodePackageDependencies `
				-RepositoryName $repoName `
				-TeamProjectName "testproject"
			$result | Should -BeExactly $false
		}
	}
	
	Describe 'Update-NodePackageDependency' {
		BeforeAll {
			function Test-NodeSuccessfulVersionUpdate {
				param (
					[string]$SourceVersion
				)
				
				$depRepo = "dependent-node"
				$repoName = "test-node"
				$repoConfigStr = @"
				{
					"version": "4.3.0",
					"packageName": "test.node",
					"dependencies": [
						"$depRepo"
					]
				}
"@
				$repoConfig = $repoConfigStr | ConvertFrom-Json
				$reposStr = @"
				{
					"$repoName": $repoConfigStr,
					"$depRepo": {
						"version": "4.3.0",
						"packageName": "dep.node"
					}
				}
"@
				$repos = $reposStr | ConvertFrom-Json
				$configStr = @"
				{
					"repositories": $reposStr
				}
"@
				$config = $configStr | ConvertFrom-Json
				
				# Initialize script scope variable
				Initialize-GlobalVariables -Configuration $config
				Mock Test-TagExist { return $true } `
					-ModuleName 51DPackageModule
				$content = '"dep.node.test" : "^$SourceVersion"'
				$updatedContent = Update-NodePackageDependency `
					-RepositoryName $depRepo `
					-PackageFileContent $content `
					-IsRemotePackage $false `
					-TeamProjectName "testproject"
				$updatedContent | Should -BeExactly '"dep.node.test": "^4.3.0"'
			}
		}
		
		It 'successfully update the file content with well formed version' {
			Test-NodeSuccessfulVersionUpdate -SourceVersion "0.0.0"
		}
		
		It 'successfully update the file content with non release well formed version' {
			Test-NodeSuccessfulVersionUpdate -SourceVersion "0.0.0-beta.18+1"
		}
		
		It 'successfully update the file content of remote-package.json' {
			$depRepo = "dependent-node"
			$repoName = "test-node"
			$repoConfigStr = @"
			{
				"version": "4.3.0",
				"packageName": "test.node",
				"dependencies": [
					"$depRepo"
				]
			}
"@
			$repoConfig = $repoConfigStr | ConvertFrom-Json
			$reposStr = @"
			{
				"$repoName": $repoConfigStr,
				"$depRepo": {
					"version": "4.3.0",
					"packageName": "dep.node"
				}
			}
"@
			$repos = $reposStr | ConvertFrom-Json
			$configStr = @"
			{
				"repositories": $reposStr
			}
"@
			$config = $configStr | ConvertFrom-Json
			
			# Initialize script scope variable
			Initialize-GlobalVariables -Configuration $config
			Mock Test-TagExist { return $false } `
				-ModuleName 51DPackageModule
			$content = '"dep.node.test" : "^0.0.0"'
			$updatedContent = Update-NodePackageDependency `
				-RepositoryName $depRepo `
				-PackageFileContent $content `
				-IsRemotePackage $true `
				-TeamProjectName "testproject"
			$updatedContent | Should -BeExactly '"dep.node.test": "^4.3.0"'
		}
	}
}

InModuleScope '51DPackageModule' {
	Describe 'Update-DotnetPackageFileContent' {
		BeforeAll {
			function Test-DotnetSuccessfulVersionUpdateOneLine {
				param (
					[string]$SourceVersion
				)
				
				$depRepo = "dependent-dotnet"
				$repoName = "test-dotnet"
				$repoConfigStr = @"
				{
					"version": "4.3.0",
					"packageName": "test.dotnet",
					"dependencies": [
						"$depRepo"
					]
				}
"@
				$repoConfig = $repoConfigStr | ConvertFrom-Json
				$reposStr = @"
				{
					"$repoName": $repoConfigStr,
					"$depRepo": {
						"version": "4.3.0",
						"packageName": "dep.dotnet"
					}
				}
"@
				$repos = $reposStr | ConvertFrom-Json
				
				$configStr = @"
				{
					"repositories": $reposStr
				}
"@
				$config = $configStr | ConvertFrom-Json
	
				# Initialize script scope variable
				Initialize-GlobalVariables -Configuration $config
				
				Mock Test-TagExist { return $true } `
					-ModuleName 51DPackageModule
				$content = '<PackageReference Include="dep.dotnet" Version="$SourceVersion" />'
				
				$updatedContent = Update-DotnetPackageFileContent `
					-Dependencies $repoConfig.dependencies `
					-ProjectFileContent $content `
					-TeamProjectName "testproject" `
					-IsPackagesConfig $false
				
				$updatedContent | Should -BeExactly '<PackageReference Include="dep.dotnet" Version="4.3.0" />'
			}
			
			function Test-DotnetSuccessfulVersionUpdateMultiLines {
				param (
					[string]$SourceVersion
				)
				
				$depRepo = "dependent-dotnet"
				$repoName = "test-dotnet"
				$repoConfigStr = @"
				{
					"version": "4.3.0",
					"packageName": "test.dotnet",
					"dependencies": [
						"$depRepo"
					]
				}
"@
				$repoConfig = $repoConfigStr | ConvertFrom-Json
				$reposStr = @"
				{
					"$repoName": $repoConfigStr,
					"$depRepo": {
						"version": "4.3.0",
						"packageName": "dep.dotnet"
					}
				}
"@
				$repos = $reposStr | ConvertFrom-Json
				
				$configStr = @"
				{
					"repositories": $reposStr
				}
"@
				$config = $configStr | ConvertFrom-Json
				
				Mock Test-TagExist { return $true } `
					-ModuleName 51DPackageModule
	
				# Initialize script scope variable
				Initialize-GlobalVariables -Configuration $config
				
				$content = "<PackageReference Include=`"dep.dotnet`">`r`n<Version>$SourceVersion</Version>`r`n</PackageReference>"
				
				$updatedContent = Update-DotnetPackageFileContent `
					-Dependencies $repoConfig.dependencies `
					-ProjectFileContent $content `
					-TeamProjectName "testproject" `
					-IsPackagesConfig $false
				
				$updatedContent | Should -BeExactly "<PackageReference Include=`"dep.dotnet`">`r`n<Version>4.3.0</Version>`r`n</PackageReference>"
			}
			
			function Test-DotnetSuccessfulVersionUpdateNetFrameworkProject {
				param (
					[string]$SourceVersion
				)
				
				$depRepo = "dependent-dotnet"
				$repoName = "test-dotnet"
				$repoConfigStr = @"
				{
					"version": "4.3.0",
					"packageName": "test.dotnet",
					"dependencies": [
						"$depRepo"
					]
				}
"@
				$repoConfig = $repoConfigStr | ConvertFrom-Json
				$reposStr = @"
				{
					"$repoName": $repoConfigStr,
					"$depRepo": {
						"version": "4.3.0",
						"packageName": "dep.dotnet"
					}
				}
"@
				$repos = $reposStr | ConvertFrom-Json
				
				$configStr = @"
				{
					"repositories": $reposStr
				}
"@
				$config = $configStr | ConvertFrom-Json
				
				Mock Test-TagExist { return $true } `
					-ModuleName 51DPackageModule
	
				# Initialize script scope variable
				Initialize-GlobalVariables -Configuration $config
				
				$content = "<HintPath>..\..\..\..\..\packages\dep.dotnet.test.$SourceVersion\lib\netstandard2.0\dep.dotnet.test.dll</HintPath>"
				
				$updatedContent = Update-DotnetPackageFileContent `
					-Dependencies $repoConfig.dependencies `
					-ProjectFileContent $content `
					-TeamProjectName "testproject" `
					-IsPackagesConfig $false
				
				$updatedContent | Should -BeExactly "<HintPath>..\..\..\..\..\packages\dep.dotnet.test.4.3.0\lib\netstandard2.0\dep.dotnet.test.dll</HintPath>"
			}
			
			function Test-DotnetSuccessfulVersionUpdateNetFrameworkPackagesConfig {
				param (
					[string]$SourceVersion
				)
				
				$depRepo = "dependent-dotnet"
				$repoName = "test-dotnet"
				$repoConfigStr = @"
				{
					"version": "4.3.0",
					"packageName": "test.dotnet",
					"dependencies": [
						"$depRepo"
					]
				}
"@
				$repoConfig = $repoConfigStr | ConvertFrom-Json
				$reposStr = @"
				{
					"$repoName": $repoConfigStr,
					"$depRepo": {
						"version": "4.3.0",
						"packageName": "dep.dotnet"
					}
				}
"@
				$repos = $reposStr | ConvertFrom-Json
				
				$configStr = @"
				{
					"repositories": $reposStr
				}
"@
				$config = $configStr | ConvertFrom-Json
				
				Mock Test-TagExist { return $true } `
					-ModuleName 51DPackageModule
	
				# Initialize script scope variable
				Initialize-GlobalVariables -Configuration $config
				
				$content = "<package id=`"dep.dotnet.test`" version=`"$SourceVersion`" targetFramework=`"net472`" />"
				
				$updatedContent = Update-DotnetPackageFileContent `
					-Dependencies $repoConfig.dependencies `
					-ProjectFileContent $content `
					-TeamProjectName "testproject" `
					-IsPackagesConfig $true
				
				$updatedContent | Should -BeExactly "<package id=`"dep.dotnet.test`" version=`"4.3.0`" targetFramework=`"net472`" />"
			}
		}
		It 'successfully update the well formed package version xml syntax `<PackageReference `/`>' {
			Test-DotnetSuccessfulVersionUpdateOneLine -SourceVersion "0.0.0"
		}
		
		It 'successfully update the non release well formed package version xml syntax `<PackageReference `/`>' {
			Test-DotnetSuccessfulVersionUpdateOneLine -SourceVersion "0.0.0-beta.18+1"
		}
		
		It 'successfully update the well formed package version xml syntax `<PackageReference`>`<`/PackageReference`>' {
			Test-DotnetSuccessfulVersionUpdateMultiLines -SourceVersion "0.0.0"
		}
		
		It 'successfully update the non well formed package version xml syntax `<PackageReference`>`<`/PackageReference`>' {
			Test-DotnetSuccessfulVersionUpdateMultiLines -SourceVersion "0.0.0-beta.18+1"
		}
		
		It 'successfully update the well formed package version xml dotnet framework syntax' {
			Test-DotnetSuccessfulVersionUpdateNetFrameworkProject -SourceVersion "0.0.0"
		}
		
		It 'successfully update the non well formed package version xml dotnet framework syntax' {
			Test-DotnetSuccessfulVersionUpdateNetFrameworkProject -SourceVersion "0.0.0-beta.18+1"
		}
		
		It 'successfully update the well formed package version xml dotnet framework packages config file' {
			Test-DotnetSuccessfulVersionUpdateNetFrameworkPackagesConfig -SourceVersion "0.0.0"
		}
		
		It 'successfully update the non well formed package version xml dotnet framework packages config file' {
			Test-DotnetSuccessfulVersionUpdateNetFrameworkPackagesConfig -SourceVersion "0.0.0-beta.18+1"
		}
	}
}

InModuleScope 51DPackageModule {
	Describe 'Update-MavenPackageFileContent' {
		BeforeAll {
			function Test-MavenSuccessfulVersionUpdate {
				param (
					[string]$SourceVersion
				)
				
				$depRepo = "dependent-java"
				$repoName = "test-java"
				$repoConfigStr = @"
				{
					"version": "4.3.0",
					"packageName": "test",
					"versionVariableName": "test.version",
					"dependencies": [
						"$depRepo"
					]
				}
"@
				$repoConfig = $repoConfigStr | ConvertFrom-Json
				$reposStr = @"
				{
					"$repoName": $repoConfigStr,
					"$depRepo": {
						"version": "4.3.0",
						"packageName": "dep",
						"versionVariableName": "dep.version"
					}
				}
"@
				$repos = $reposStr | ConvertFrom-Json
				$configStr = @"
				{
					"repositories": $reposStr
				}
"@
				$config = $configStr | ConvertFrom-Json
				
				Mock Test-TagExist { return $true } `
					-ModuleName 51DPackageModule
				
				# Initialize script scope variable
				Initialize-GlobalVariables -Configuration $config
				
				$content = '<dep.version>$SourceVersion</dep.version>'
				
				$updatedContent = Update-MavenPackageFileContent `
					-Dependencies $repoConfig.dependencies `
					-PomContent $content `
					-TeamProjectName "testproject"
				
				$updatedContent | Should -BeExactly '<dep.version>4.3.0</dep.version>'
			}
		}

		It 'successfully update the well formed package version' {
			Test-MavenSuccessfulVersionUpdate -SourceVersion "0.0.0"
		}
		
		It 'successfully update the non-release well formed package version' {
			Test-MavenSuccessfulVersionUpdate -SourceVersion "0.0.0-beta.18+1"
		}
	}
}