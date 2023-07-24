# PHP Specific CI/CD Approach
This API complies with the `common-ci` approach.

## `package-dev.json`

The `package-dev.json` file, which uses development versions of dependencies from submodules instead of getting them
from packagist, uses a workaround to force transitive dependencies to also use the development versions of common
dependencies. Consider the following case:

1. `php-pipeline-cloudrequestengine` repository has 2 submodules: `php-pipeline-core` and `php-pipeline-engines`.

2. `php-pipeline-engines` also has a submodule - `php-pipeline-core`.

3. When installing cloudrequestengine's dependencies from `composer-dev.json`, the submodules are always preferred.

4. Their versions are resolved as `dev-main` or `dev-commithash`, so `php-pipeline-core` now has version `dev-main`.

5. This causes a conflict, because the version of `php-pipeline-core` from a higher-priority repo (local path) doesn't
meet the constraints of `php-pipeline-engines`'s `composer.json` which requires version `4.*`.

Earlier, the solution was to rename each submodules' `composer-dev.json` (which has the correct constraints) to
`composer.json`. But this requires mutating the repository, instead of simply setting the `COMPOSER` variable to
`composer-dev.json`. Now, the solution is to [always treat the version of the submodule as version 4](https://github.com/51Degrees/pipeline-php-cloudrequestengine/pull/8/files#diff-38962aa8c8c9209a2a60a0247b8dce03c675508d2283f5e58520d737a1fa0a3aR40),
which satisfies the transitive dependencies' constraints. But if the constraints were to change, for example to require
new major version `5.*`, the forced version would also need to be changed to `5` as part of the major version bump
process.
