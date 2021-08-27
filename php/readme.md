# PHP Specific CI/CD Approach
This API complies with the `common-ci` approach.

## Deploy External
The deployment to external of PHP involves a stage that builds and tests on actual external package. This is not required for internal pipelines such as `build-and-test.yml` as it is acceptable to just use submodule references. However, before deploy to external, the solution is required to work with other external packages. Thus, the deployment to external will fail as some dependencies packages are left waiting for a release engineer to approve. In this case, the failed deployment will need to be rerun after their dependency packages have been deployed to external.

Typically the deploy external pipelines should be completed in the following order:

1. `pipeline-php-core`
2. `pipeline-php-engines`
3. `pipeline-php-cloudrequestengine`
4. `device-detection-php`
5. `location-php`

`device-detection-onpremise-php` is not deployed as a package to Packagist but should be completed after `device-detection-php`