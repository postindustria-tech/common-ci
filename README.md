# Common-CI
Common-CI project contains a guideline for creation of continuous integration scripts and describes a general approach to continuous integration within 51Degrees. This readme should provide a comprehensive overview of rules and conventions to be expected from existing jobs and which should be followed when new jobs are created.

# Table of content
- [Common-CI](#common-ci)
- [Table of content](#table-of-content)
- [Reasoning](#reasoning)
- [Continuous integration](#continuous-integration)
  - [Approach](#approach)
    - [Overview](#overview)
    - [Build and test](#build-and-test)
    - [Build, test and publish](#build,-test-and-publish)
  - [Naming convention](#naming-convention)
    - [Azure DevOps Pipelines](#azure-devops-pipelines)
  - [Development guideline](#development-guideline)
    - [Microsoft Azure DevOps Pipelines](#microsoft-azure-devops-pipelines)
    - [YML file](#yml-file)
    - [Build and test platforms](#build-and-test-platforms)
    - [Additional documentation](#additional-documentation)
- [Continuous deployment](#continuous-deployment)
  - [Configuration](#configuration)
    - [Internal package managers](#internal-package-managers)
  - [Release process](#release-process)
    - [Packages release](#packages-release)
    - [External package managers and public repositories](#external-package-managers-and-public-repositories)
- [License](#license)

# Reasoning
In order to keep high hygiene of development work and have clear indication of successful build, test and package creation, a common set of rules should be followed to measure the quality in a consistent manner across all of the projects. The main reason for having continuous integration in 51Degrees is to assure the best possible quality of software products by confirming successful execution of unit, functional, regression and example tests whenever change to the code base is made. Apart from the code related test, other measures prove the quality of software development through verification of successful execution of build and test processes on all supported platforms and architectures. 

 The reason for this document is to describe the technical solutions used for continuous integration in 51Degrees as well as provide a clear guidance on common rules across: 
- Naming conventions;
- Compulsory elements of CI scripts;
- Platforms and environments;
- Requirements for additional documentation;

# Continuous integration
## Approach
### Overview 
This section describes the general approach to continuous integration in 51Degrees. 

As an internal repository management system 51Degrees is using the Azure DevOps services and continuous integration is achieved through Azure DevOps Pipelines. Each pipeline is defined by a single or multiple `yml` scripts. High maintainability of continuous integration is achieved by keeping the tasks shared between the jobs in separate `yml` scripts and reuse them when possible to avoid code duplications and “copy & paste” errors.

51Degrees is using continuous software development practices described in principle as [Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).

At least two main continuous integration jobs should be provided for each software project/repository:
- “[Build and test](#build-and-test)”, and
- “[Build, test and publish](#build,-test-and-publish)”

Binaries built by continuous integration should be configured to perform a release built by default. If debug build configuration is required, additional, explicit jobs should be created to clearly indicate that pipeline output will be in debug mode.

### Build and test
Build and test job should be used for general purpose building and testing process, and should be the initial step of “Build, test and publish”. Continuous integration should be configured to automatically trigger this type of job whenever pull request is created regardless of the destination branch. Job should be automatically performed whenever any code change is made to the active pull request.

Build and test job provides tasks required for the project to build and run unit and regression tests. This job usually runs a sequence of tasks:
- Configuration<br />
This task (or tasks) configures the environment to meet the build requirements. Task should install all dependencies and platform specific packages required for the build and test processes.
- Code checkout<br />
Task to checkout the source code from the version control system. 51Degrees is using Git repositories hosted on Azure DevOps platform: `git clone` with, where required, submodules initialisation (`git submodule update --init --recursive`) should be used.
- Build<br />
Language and project specific build tool execution. 
- Test (and publish the results)<br />
Language and project specific unit, functional, example, or regression testing execution.

Set of tasks may differ between projects due to a requirement of individual approach for language or platform specific solutions. If an individual solution is in place, it should be documented in the `ci/readme.md` file of the given project.

Job <b>must</b> indicate a <b>fail state</b> if any of the following occurs:
- Configuration step fails on installation of any of the dependencies
- Code checkout step fails regardless of the reason
- Build step fails with error or warning - all warnings should be treated as errors
- Any test fails

If multiple operating system platforms should be supported according to [version support table](https://51degrees.com/documentation/_info__version_support.html) “Build and test” job should either:
- implement support for each operating system in a single `yml` file, or
- implement support for each operating system in a separate `yml` file and create a combining `yml` script.

General guideline for selecting the approach is to keep the `yml` file in a consumable size; if environment configuration, build, test, and any platform specific tasks sums up to more than 4 tasks - create a separate `yml` file. Try to use multi-platform matrix configuration whenever possible, more details can be found in [Microsoft documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/get-started-multiplatform?view=azure-devops)

<i>Note: Build and test job should be configured in a separate `yml` file to allow performing the set of tasks defined in this job as a part of "Build, test and publish" job.</i>

### Build, test and publish
Build, test and publish job should be used for creation of packages or tagging the repository and continuous integration system should be configured to automatically execute this job whenever pull request from `release` or `hotfix` branch is merged to `main` branch (as described in  [gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)).

Build, test and publish job uses tasks created for [Build and test](#build-and-test) job and extends them by any tasks required for creation of packages and/or repository version tag. This job usually runs a sequence of tasks which differ for creating the packages and tagging the repository. <br />

Typical tasks for packages creation:<br />
- Build and test<br />
As described in [Build and test](#build-and-test) section.
- Package creation<br />
Language and project specific task generating the packages for given language and/or platform. This task should be documented in project specific `ci/readme.md` file.
- Digital signing<br />
This task should digitally sign the generated binaries or packages to assure a high level of quality and trust for the end user.
- Publish artifacts<br />
Packages or binaries produced by [Build, test and publish](#build,-test-and-publish) job should be published as artifacts of the Azure DevOps Pipeline execution. This task is important to support a smooth release process where the product of this step is used as the final release package.

Typical tasks for creating a repository tag:<br />
- Build and test<br />
As described in [Build and test](#build-and-test) section.
- Determine repository version number<br />
This step should determine the version number to be used for repository tagging. 51Degrees is using [GitVersion](https://gitversion.readthedocs.io/en/latest/input/docs/build-server-support/build-server/azure-devops/) Azure DevOps plugin to identify the repository version based on the [gitflow workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow).
- Tag the repository<br />
Perform `git tag` operation on the repository using the version number determined in the previous step and `push` the newly created tag to remote.

Job <b>must</b> indicate a <b>fail state</b> if any of the following occurs:
- Build and test step fails as described in [build and test](#build-and-test) section.
- Package creation fails
- Digital signature process fails
- Artifacts cannot be found or published

## Naming convention
### Azure DevOps Pipelines
There are two main jobs per pipeline: `build and test`, and `build, test and publish` the common naming convention is as follows:
- For “build and test” job:<br />
`<package-name>-test` where `<package-name>` represents dash-separated repository name; for example for repository `pipeline-python`, “build and test” job name should be configured as `pipeline-python-test`.
- For “build, test and publish” job when packages are created:<br /> `<package-name>-create-packages`, where `<package-name>` represents dash-separated repository name; for example for repository `pipeline-python`, “build, test and publish” job name should be configured as `pipeline-python-create-packages`.
- For “build, test and publish” job when repository is only tagged:<br />
`<package-name>-tag-repository`, where `<package-name>` represents dash-separated repository name; for example for repository `location-php`, “build, test and publish” job name should be configured as `location-php-tag-repository`.
- For jobs in debug configuration:<br />
`<package-name>-<job>-debug`, where `<package-name>` represents dash-separated repository name, `<job>` represents job suffix selected above; for example for repository `device-detection-dotnet`, “build, test and publish” job in `debug` the name should be configured as `device-detection-dotnet-create-packages-debug`.

## Development guideline
### Microsoft Azure DevOps Pipelines
Detailed documentation and useful information about Azure DevOps pipelines can be found in [Microsoft documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/?view=azure-devops).
### YML file
YAML Ain't Markup Language configuration files are used to configure Azure DevOps continuous integration pipelines and more details about how to use them can be found in [Microsoft documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema?view=azure-devops&tabs=schema%2Cparameter-schema).


This guideline obligates the CI developer to add comments to any tasks defined in `yml` files that are not self descriptive and requires more information to understand the implemented process. Follow the general rule that “if in doubt - comment” and always ask for peer review in order to address any concerns or possible misunderstandings. 

Comments in `yml` files are achieved by `#` character prefix, for example:<br />
Visual Studio build task from `pipeline-dotnet` project:
```
- task: VSBuild@1
  displayName: 'Build solutions'
  inputs:
    solution: '$(RestoreBuildProjects)'
    vsVersion: '15.0'
    platform: 'Any CPU'
    configuration: '$(BuildConfiguration)'
    clean: true
```
Although relatively self descriptive, could be extended by comments:
```
# Visual studio build task - VS2017 configuration
- task: VSBuild@1
  displayName: 'Build solutions' # defines name of the task displayed in Azure DevOps
  inputs: # Task specific inputs
    solution: '$(RestoreBuildProjects)' # Location of solution file obtained from RestoreBuildProjects variable set by previous NuGet restore step
    vsVersion: '15.0' # Version of Visual Studio to be used (version 15.0 is VS2017)
    platform: 'Any CPU' # Target platform 
    configuration: '$(BuildConfiguration)' # Build configuration as set by strategy matrix at the top of this file
    clean: true # Should we clean?
```

### Build and test platforms
51Degrees provides information about supported platforms and language/API versions. The full table is available on [51Degrees documentation website](https://51degrees.com/documentation/index.html) on [Information/Version support page](https://51degrees.com/documentation/_info__version_support.html). Azure DevOps Pipelines should be configured to at least mirror the requirements setup by the documentation. If platform architecture is not specified in the support version matrix, it is assumed that both 32 and 64 bit platforms are supported and relevant continuous jobs should be provided. If any changes are applied, support removed or added, either the documentation table or CI configuration must be updated to assure full synchronization between the two.
### Additional documentation
This guideline covers high-level overview and basic principles for continuous integration configuration in 51Degrees. Due to the nature of software products supported and provided by the company, different approaches may be required for various types of platforms, languages, APIs and their versions. Therefore, this document should be treated as the guideline and any project specific configuration that alters the information provided by this document should be explained in the `readme.md` file stored under the `ci` folder of the given project. Repository containing this document should be added as a submodule to any project that contains Continuous Integration pipeline configured within 51Degrees Azure DevOps environment. Example directory tree expected in the project:
```
<project_root>
  \ci
    \common-ci
      \readme.md
    \readme.md
    \build_and_test.yml
    \build_and_publish.yml
```
# Continuous deployment
## Configuration
Continuous deployment in 51Degrees is configured to continuously publish packages to the internal package manager feed available in Azure DevOps Artifacts service. Deployment is configured to create and publish the packages internally on a daily basis (overnightly) so that the latest version is available for development purposes. 

All of the packages for daily continuous deployment are created based on the latest version of the `develop` repository branch.
### Internal package managers
51Degrees is using Azure DevOps services for continuous integration and deployment configuration. Azure DevOps provides internal repository managers for the main languages supported by 51Degrees APIs: 
- NuGet
- Maven
- NPM
- PyPi

Deployment to internal package managers is performed daily (overnightly) based on changes applied to `develop` branches of the source code repositories. 

## Release process
### Packages release
Packages release process in 51Degrees is handled through Azure DevOps and the deployment to the public repositories is performed manually using packages generated by [Build, test and publish](#build,-test-and-publish) continuous integration job. As explained in “[build, test and publish](#build,-test-and-publish)” section, process of creating the packages is automatically triggered by completion of pull request to the `main` branch of the repository. Created packages are stored as artifacts in Azure DevOps Artifacts and are used in internal release pipelines in order to upload them to the public package managers/repositories.

API release process steps:
- PR completed to the `main` branch.
- Automatic execution of [build, test and publish](#build,-test-and-publish) job.
- Automatic trigger for release pipeline:
  - Automatic upload to internal package manager
  - Manual deployment to public package manager/repository

### External package managers and public repositories
51Degrees provides APIs for a selection of programming languages and packages are available on the following public package managers:
- [NuGet](https://www.nuget.org/profiles/51Degrees)
- [Maven](https://mvnrepository.com/artifact/com.51degrees)
- [Packagist](https://packagist.org/packages/51degrees/)
- [NPM](https://www.npmjs.com/~51degrees)
- [PyPi](https://pypi.org/search/?q=51degrees) (and [TestPyPi](https://test.pypi.org/search/?q=51degrees))
- Source code on [Github](https://github.com/51Degrees/)

# License
License information can be found in the `LICENSE` file available in this repository.



