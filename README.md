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
-   All parameters are GitHub secrets, or options defined in the repo, and passed by the YAML script as parameters to the PowerShell script.
-   YAML scripts orchestrate the PowerShell scripts within the GitHub actions. Each YAML script will have a corresponding PowerShell script which can be used to test all the steps on any environment. These scripts must have the same name with only the file extension being different. The two scripts must be kept in sync.
-   GitHub triggers initiate the stages.
-   Use of GitHub actions and other platform specific features are minimised to enable portability of CI/CD. For example, cloning a repository is performed in PowerShell via a generic command line that works on Linux, Windows, and Mac rather than in a GitHub action. This ensures the PowerShell script can be tested outside a CI/CD deployment environment.
-   C/C++ is compiled using CMake on all platforms.
-   Versioning is performed using the most appropriate method for the target language. For example, GitVersion used for .NET
-   Common PowerShell scripts are contained in this repository. Repository specific scripts are contained under the root `ci` folder.
-   Code that is in the `main` branch has passed all relevant tests. This is a critical gate to avoid repeating tests.
-   The package output from a repository in the organisation is used as the input to other packages in the same organisation via the relevant package manager. This ensures that the organisations published packages are treated just like any other dependency and are not given special treatment.
-   Branching strategy is covered in the relevant CONTRIBUTIONS.md for the repository and not covered here. All organisation repositories must have a `main` branch which can accept pull requests via automated tasks.

# Design

When implementing changes, see the [Design Document](/DESIGN.md) for detailed descriptions of how each part works.

# Workflows

## Nightly Publish Main

``` mermaid
flowchart LR;
subgraph Nightly Publish Main
conf --> bat
end

subgraph conf[Configure]
direction LR
style conf fill:#00C5,stroke:#00C9,stroke-width:2px;
A[Checkout Common]
B[Configure Git]
C[Clone Repo]
D[Get Next Package Version]
E[Package Update Required]
F[Get Build Options]
end

subgraph bat[Build And Test]
direction LR
style bat fill:#00C5,stroke: #00C9,stroke-width:2px;
Z[Checkout Common]
Y[Configure Git]
X[Clone Repo]
W[Fetch Assets]
V[Setup Environment]
U[Build Package]
T[Test Package]
S[Publish Package]
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
flowchart LR
  subgraph "Nightly PR to Main"
    subgraph conf[Configure]
        direction LR
        style conf fill:#00C5,stroke:#00C9,stroke-width:2px;
      A[Checkout Common] --> B[Configure Git]
      B --> C[Clone Repo]
      C --> D[Checkout Pull Request]
      D --> E[Get Build Options]
    end
    subgraph bat[Build and Test]
        direction LR
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
  graph LR
  subgraph "Nightly Submodule Update"
  direction LR
    A[Checkout Repository]
    B[Checkout reusable workflow dir]
    C[Configure Git]
    D[Clone Repo]
    E[Update Sub Modules]
    F[Check for Changes]
    G[Commit Changes]
    H[Push Changes]
    I[Create Pull Request]
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
graph LR
  subgraph "Nightly Package Update"
  direction LR
    A[Checkout Repository]
    B[Checkout reusable workflow dir]
    C[Configure Git]
    D[Clone Repo]
    E[Update Packages]
    F[Check for Changes]
    G[Commit Changes]
    H[Push Changes]
    I[Create Pull Request]
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


# Triggers

Each of the triggers shown is described at a high level. More detail is provided in the associated scripts and the following summary.

### Nightly Data File Change

When data files used by the packages change new properties might be added or current ones deprecated. The strongly type accessors for the language might therefore need to change resulting in a new version of the resulting package. Every night, data files are fetched, and the auto generated strongly typed accessor code is updated. Any changes are then committed to a branch and a pull request to `main` is created.

### Nightly Package Dependency Update and Nightly Sub-Module Update

Every night any dependencies of the package are updated automatically to the latest patch version of that package or `main` branch commit of the sub-module. This includes any dependencies on packages within the organisation. Where changes are identified a branch is created and a PR to `main` is initiated. The tests associated with any PR to `main` will identify any failures for engineers to address before the updated versions can be used.

### PR to Main

All tests associated with the repository are run only at this point to avoid repetition. Code can only be present in the main branch of the repository if all tests have passed.

PRs to `main` can only be initiated by a project Contributor, Administrator, or GitHub actions.

### Nightly Main Package Publish

**This job should only be run once all the other nightly jobs have completed.**

Any changes to the `main` branch are published automatically on a nightly basis as a new package at the target package manager environment.

### Common Scenarios

#### New property in data file

The Data File Change trigger creates new auto generated code for the strongly typed accessors. These are pushed to a branch and a PR to main commenced. All the tests associated with the repository will then be run. If they fail, then the engineers will be alerted to a problem. If they pass, then the PR will be approved and main branch updated. When the next nightly publish of packages occurs then the new property will be included in the package.

#### Update dependency

A package that the organisation uses is updated to a new version within the same `major.minor` version. The nightly dependency check will pick up on the new version and create a branch and associated PR to main. The changes will then propagate to the published packages if the tests executed for any PR to main pass.

#### Organisation package update

Packages associated with the organisation are treated like any other package dependency. Once the package manager has the new version the dependent packages will be updated automatically.

# Common Steps

For details of the common scripts, see [Common Steps](./steps/README.md).

# Prerequisites

To run these PowerShell scripts, either locally, or in a CI/CD pipeline, the following prerequisites must be set up.

- [Git CLI](https://git-scm.com/downloads)
- [Hub CLI](https://hub.github.com/)
- `GITHUB_TOKEN` environment variable (this is automatically set if using GitHub actions)
