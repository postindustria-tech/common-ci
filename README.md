# Introduction

This repository contains all the common scripts and documentation associated with continuous integration and deployment (CI/CD) used across the organisation.

The subfolders with language names contain an equivalent document detailing language specific detail that is common across all repositories using the language.

The reader should be familiar with PowerShell and common Git based CI/CD techniques.

# Principles

The following rules are common across the organisation.

-   Minimal dependency between stages.
-   Relevant integration tests must be run against packages before they are released to the relevant package manager.
-   PowerShell scripts contain the implementation as they operate consistently across platform and avoid duplicating logic associated with a mixed environment.
-   PowerShell scripts contain all the necessary documentation at the top of the script.
-   PowerShell scripts have defined input parameters and outputs following PowerShell conventions.
-   All parameters are GitHub secrets and passed by the YAML script as parameters to the PowerShell script.
-   YAML scripts orchestrate the PowerShell scripts within the GitHub actions. Each YAML script will have a corresponding PowerShell script which can be used to test all the steps on any environment. These scripts must have the same name with only the file extension being different. The two scripts must be kept in sync.
-   GitHub triggers initiate the stages.
-   Use of GitHub actions and other platform specific features are minimised to enable portability of CI/CD. For example, cloning a repository is performed in PowerShell via a generic command line that works on Linux, Windows, and Mac rather than in a GitHub action. This ensures the PowerShell script can be tested outside a CI/CD deployment environment.
-   C/C++ is compiled using CMake on all platforms.
-   Versioning is performed using the most appropriate method for the target language. For example, GitVersion used for .NET, but Maven for Java.
-   Common PowerShell scripts are contained in this repository. Repository specific scripts are contained under the root `ci` folder. This repository is a sub-module under the root `ci` folder.
-   Code that is in the main branch has passed all relevant tests. This is a critical gate to avoid repeating tests.
-   The package output from a repository in the organisation is used as the input to other packages in the same organisation via the relevant package manager. This ensures that the organisations published packages are treated just like any other dependency and are not given special treatment.
-   Branching strategy is covered in the relevant CONTRIBUTIONS.md for the repository and not covered here. All organisation repositories must have a `main` branch which can accept pull requests via automated tasks.
-   Test assets that are not part of the repository are copied from a central location rather than fetched from their primary source. For example, device detection data files are not fetched from the primary source, but instead copied from the central location.

# Matrix

The following table provides the common functions that are associated with each of the triggers available to different repositories. The number in the table is the expected order of execution where common function marked 1 is executed first. The headings are the general name of the trigger with the letter prefix a unique identifier for the trigger.

| Common Steps                             | A. Nightly Data File Change | B. Nightly Package Dependency Update | C. Nightly Sub-Module Update | D. PR to Main | E. Nightly Main Package Publish |
|------------------------------------------|-----------------------------|--------------------------------------|------------------------------|---------------|---------------------------------|
| Approve PR                               |                             |                                      |                              | 7             |                                 |
| Build Docker                             |                             |                                      |                              |               |                                 |
| Build Environment                        | ?                           | 1                                    | 1                            | 1             | 2                               |
| Build Package                            |                             |                                      |                              |               | 5                               |
| Build Project                            |                             |                                      |                              | 4             |                                 |
| Check for Changes                        | 4                           | 4                                    | 4                            |               |                                 |
| Clone Repo                               | 1                           | 2                                    | 2                            | 2             | 3                               |
| Commit Changes                           | 5                           | 5                                    | 5                            |               |                                 |
| Fetch Data File Assets                   | 2                           |                                      |                              | 3             |                                 |
| Generate Accessors                       | 3                           |                                      |                              |               |                                 |
| Get Next Package Version                 |                             |                                      |                              |               | 4                               |
| PR to Main                               | 7                           | 7                                    | 7                            |               |                                 |
| Publish Package                          |                             |                                      |                              |               | 7                               |
| Push Changes                             | 6                           | 6                                    | 6                            |               |                                 |
| Run Unit Tests                           |                             |                                      |                              | 5             |                                 |
| Update Dependencies (patch version only) |                             | 3                                    |                              |               |                                 |
| Update Sub-Modules to latest main commit |                             |                                      | 3                            |               |                                 |
| Package Update Required                  |                             |                                      |                              |               | 1                               |
| Run Integration Tests                    |                             |                                      |                              | 5             | 6                               |
| Run Performance Tests                    |                             |                                      |                              | 6             |                                 |
| Update Tags                              |                             |                                      |                              |               | 7                               |

# Triggers

Each of the triggers shown is described at a high level. More detail is provided in the associated scripts and the following summary.

### Nightly Data File Change

When data files used by the packages change new properties might be added or current ones deprecated. The strongly type accessors for the language might therefore need to change resulting in a new version of the resulting package. Every night, data files are fetched, and the auto generated strongly typed accessor code is updated. Any changes are then committed to a branch and a pull request to `main` is created.

### Nightly Package Dependency Update and Nightly Sub-Module Update

Every night any dependencies of the package are updated automatically to the latest patch version of that package or main branch commit of the sub-module. This includes any dependencies on packages within the organisation. Where changes are identified a branch is created and a PR to main is initiated. The tests associated with any PR to main will identify any failures for engineers to address before the updated versions can be used.

### PR to Main

All tests associated with the repository are run only at this point to avoid repetition. Code can only be present in the main branch of the repository if all tests have passed.

PRs to `main` can only be initiated by a project Contributor, Administrator, or GitHub actions.

### Nightly Main Package Publish

**This job should only be run once all the other nightly jobs have completed.**

Any changes to the main branch are published automatically on a nightly basis as a new package at the target package manager environment.

### Common Scenarios

#### New property in data file

The Data File Change trigger creates new auto generated code for the strongly typed accessors. These are pushed to a branch and a PR to main commenced. All the tests associated with the repository will then be run. If they fail, then the engineers will be alerted to a problem. If they pass, then the PR will be approved and main branch updated. When the next nightly publish of packages occurs then the new property will be included in the package.

#### Update dependency

A package that the organisation uses is updated to a new version within the same `major.minor` version. The nightly dependency check will pick up on the new version and create a branch and associated PR to main. The changes will then propagate to the published packages if the tests executed for any PR to main pass.

#### Organisation package update

Packages associated with the organisation are treated like any other package dependency. Once the package manager has the new version the dependent packages will be updated automatically.

# Common Steps

The previous table contained a title for each of the steps available in the common continuous integration and development repository. This section describes the steps in more detail including the parameters that are provided to each script. More details information is available in the specific implementation scripts listed under each step.

All steps that fail must do so in a manner that make it clear in GitHub actions output logs what the cause of the failure is.

## Common Parameters

The following common parameters are used by the scripts.

-   Artifact – the location of an artifact
-   Credentials – for the package manager that the package will be published to. These should be stored as secrets.
-   GitUrl – the URL for a git repo
-   LicenseKey - used to fetch test assets
-   Message – to include with an action
-   Tag(s) – to apply to the operation
-   Version – a string with three numbers separated by decimal points in the form `major.minor.patch`.

## Git Credentials

The scripts assume that the environment has been configured via environment variables or other means with the necessary credentials to perform the actions on the Git repository. These credentials are not passed as parameters to the scripts.

## Steps

### Approve PR

Automates the approval of a PR after tests and merge checks have been complete. Might fail if these conditions are not achieved.

No parameters

Implementations

-   approve-pr.ps1

### Build Docker

If a dockerfile is present in the current folder then builds a docker image.

No parameters

Implementations

-   build-docker.ps1

### Build Environment

Creates an environment for the latest long term support version of the target operating system with all dependencies needed for subsequent steps. Build, test, and publish operations use this environment.

No parameters

Implementations

-   build-environment-ubuntu.ps1
-   build-environment-windows.ps1
-   build-environment-mac.ps1

### Build Package

Builds a package for the current folder repository and branch with the version information provided. Common parameters across the organisation should be applied in the scripts. The name of the package should be calculated from the project name.

Parameters

-   Version

Implementations

-   dotnet/build-package-nuget.ps1
-   java/build-package-maven.ps1
-   python/build-package-pypi.ps1
-   node/build-package-npm.ps1
-   php/build-package-composer.ps1

### Build Project

Builds the project for the current folder repository and branch in the current environment. Where possible each language should have a common convention for building projects to avoid project specific logic being required in these scripts.

No parameters

Implementations

-   dotnet/build-project-core.ps1
-   dotnet/build-project-framework.ps1
-   java/build-project.ps1
-   python/build-project.ps1
-   node/build-project.ps1
-   php/build-project.ps1
-   cxx/build-project.ps1

### Clone Repo

Clones the git repository URL provided including all the sub modules.

Parameters

-   GitUrl

Implementations

-   clone-repo.ps1

### Commit Changes

Commits any changes to the current folder repository and branch.

Parameters

-   Message

Implementations

-   commit-changes.ps1

### Fetch Assets

Obtains all the files that are needed for the repositories in the organisation.

Parameters

-   LicenseKey

Implementations

-   fetch-assets.ps1

### Generate Accessors

Recreates the files that are auto generated for engines that have strongly typed accessors. A single script is provided to create all language specific files.

Implementations

-   generate-accessors.ps1

### Get Next Package Version

Returns a string representation of the next package version to use for package at publication time or assemblies that form the package at build time.

The root script provides common functions that are shared across all language specific implementations.

No parameters

Implementations

-   get-next-package-version.ps1
-   dotnet/get-next-package-version.ps1
-   java/get-next-package-version.ps1
-   python/get-next-package-version.ps1
-   node/get-next-package-version.ps1
-   php/get-next-package-version.ps1

### Has Changed

Returns true if there are changes in the current folder repository and branch that are not included in the origin. Used to determine if the result of an operation to generate code, fetch dependencies, or update sub-modules has resulted in a change to the branch.

No parameters

Implementations

-   has-changed.ps1

### Package Update Required

Returns true if the package associated with the current folder repository and branch needs to be updated to reflect code changes. If false no update needed.

No Parameters

Implementations

-   dotnet/package-update-required.ps1
-   java/package-update-required.ps1
-   python/package-update-required.ps1
-   node/package-update-required.ps1
-   php/package-update-required.ps1

### Pull Request to Main

Creates a pull request from the current folder repository current branch to the `main` branch for the repository.

No parameters

Implementations

-   pull-request-to-main.ps1

### Publish Package

Publishes the asset provided to the relevant package manager using the credentials provided.

Parameters

-   Artifact
-   Credentials

Implementations

-   dotnet/publish-package-nuget.ps1
-   java/publish-package-maven.ps1
-   python/publish-package-pypi.ps1
-   node/publish-package-npm.ps1
-   php/publish-package-composer.ps1

### Push Changes

Pushes the current folder repository branch to the current default origin including any tags.

No parameters

Implementations

-   push-changes.ps1

### Run Performance Tests

Executes the performance tests for the current folder repository and branch in the current environment. Where possible each language should have a common convention for the execution of performance tests to avoid project specific logic being required in these scripts. Any assets required for the test should be fetched prior to calling the common steps.

No parameters

Implementations

-   dotnet/run-performance-tests.ps1
-   java/run-performance-tests.ps1
-   python/run-performance-tests.ps1
-   node/run-performance-tests.ps1
-   php/run-performance-tests.ps1
-   cxx/run-performance-tests.ps1

### Run Integration Tests

Executes the integration tests for the current folder repository and branch in the current environment. Where possible each language should have a common convention for the execution of integration tests to avoid project specific logic being required in these scripts. Any assets required for the test should be fetched prior to calling the common steps.

No parameters

Implementations

-   dotnet/run-integration-tests.ps1
-   java/run-integration-tests.ps1
-   python/run-integration-tests.ps1
-   node/run-integration-tests.ps1
-   php/run-integration-tests.ps1
-   cxx/run-integration-tests.ps1

### Run Update Dependencies

Uses the public package manager for the target language to update patch version dependencies for the projects that are contained in the current folder.

No parameters

Implementations

-   dotnet/run-update-dependencies.ps1
-   java/run-update-dependencies.ps1
-   python/run-update-dependencies.ps1
-   node/run-update-dependencies.ps1
-   php/run-update-dependencies.ps1

### Run Unit Tests

Executes the unit tests for the current folder repository and branch in the current environment. Where possible each language should have a common convention for the execution of unit tests to avoid project specific logic being required in these scripts. Any assets required for the test should be fetched prior to calling the common steps.

No parameters

Implementations

-   dotnet/run-unit-tests.ps1
-   java/run-unit-tests.ps1
-   python/run-unit-tests.ps1
-   node/run-unit-tests.ps1
-   php/run-unit-tests.ps1
-   cxx/run-unit-tests.ps1

### Update Sub Modules

Updates all the sub modules recursively for the current folder repository and branch.

No parameters

Implementations

-   update-sub-modules.ps1

### Update Tags

Adds the tag to the current folder repository and branch. The subsequent push operation must include the tags.

Parameters

-   Tag

Implementations

-   update-tags.ps1

# Prerequisites

To run these PowerShell scripts, either locally, or in a CI/CD pipeline, the following prerequisites must be set up.

- [Git CLI](https://git-scm.com/downloads)
- [Hub CLI](https://hub.github.com/)
- `GITHUB_TOKEN` environment variable (this is automatically set if using GitHub actions)


# DIAGRAMS

## Nightly Publish Main

``` mermaid
flowchart TD;
subgraph Nightly Publish Main
conf --> bat
end

subgraph conf[Configure]
style conf fill:#00C5,stroke:#00C9,stroke-width:2px;
A[Checkout_Common]
B[Configure_Git]
C[Clone_Repo]
D[Get_Next_Package_Version]
E[Package_Update_Required]
F[Get_Build_Options]
end

subgraph bat[Build_And_Test]
style bat fill:#00C5,stroke: #00C9,stroke-width:2px;
Z[Checkout_Common]
Y[Configure_Git]
X[Clone_Repo]
W[Fetch_Assets]
V[Setup_Environment]
U[Build_Package]
T[Test_Package]
S[Publish_Package]
end

A --> B;
B --> C;
C --> D;
D --> E;
E --> F;

Z --> Y;
Y --> X;
X --> W
W --> V;
V --> U;
U --> T;
T --> S;
```
## Nightly PR to Main 

``` mermaid
flowchart TD
  subgraph "Nightly PR to Main"
    subgraph conf[Configure]
        direction TB
        style conf fill:#00C5,stroke:#00C9,stroke-width:2px;
      A[Checkout Common] --> B[Configure Git]
      B --> C[Clone Repo]
      C --> D[Checkout Pull Request]
      D --> E[Get Build Options]
    end
    subgraph bat[Build-and-Test]
        direction TB
        style bat fill:#00C5,stroke:#00C9,stroke-width:2px;
      F[Checkout Common] --> G[Configure Git]
      G --> H[Clone Repo]
      H --> I[Checkout Pull Request]
      I --> J[Fetch Assets]
      J --> K[Setup Environment]
      K --> L[Build Project]
      L --> M[Run Unit Tests]
      M --> N[Run Integration Tests]
      N --> O[Run Performance Tests]
    end
    conf-->bat
  end
  ```

  ## Nightly Submodule Update
``` mermaid
  graph TD
  subgraph "Nightly Submodule Update"
  direction TB
    A["Checkout Repository"]
    B["Checkout reusable workflow dir"]
    C["Configure Git"]
    D["Clone Repo"]
    E["Update Sub Modules"]
    F["Check for Changes"]
    G["Commit Changes"]
    H["Push Changes"]
    I["Create Pull Request"]
  end
  
A --> B
B --> C
C --> D
D --> E
E --> F
F --> G
G --> H
H --> I
```
## Nightly Package Update

``` mermaid
graph TD
  subgraph "Nightly Package Update"
  direction TB
    A["Checkout Repository"]
    B["Checkout reusable workflow dir"]
    C["Configure Git"]
    D["Clone Repo"]
    E["Update Packages"]
    F["Check for Changes"]
    G["Commit Changes"]
    H["Push Changes"]
    I["Create Pull Request"]
  end
  
A --> B
B --> C
C --> D
D --> E
E --> F
F --> G
G --> H
H --> I
```


