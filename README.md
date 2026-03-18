# Maven CI/CD component for GitLab

This repository now focuses on a GitLab-first CI/CD component for Java Maven projects.
The GitHub workflows remain available in `.github/workflows/` as a reference implementation, but Jenkins has been removed from the component.

The sample project under `examples/spring-boot-actuator/` stays opinionated on purpose:

- Java `25` by default
- Spring Boot `4.0.3`
- unit tests plus integration tests
- JaCoCo coverage gate
- Sonar integration
- OWASP dependency-check
- snapshot publication
- release automation with `maven-release-plugin`

## Main files

- `.gitlab-ci.yml`: GitLab pipeline with separated verification, quality, snapshot and release responsibilities
- `.gitlab/scripts/`: versioned shell entrypoints used by `.gitlab-ci.yml`
- `docs/gitlab-end-to-end.md`: GitLab setup, registry alignment and CI/CD variables
- `templates/maven-settings.xml`: GitLab-oriented Maven settings template
- `examples/spring-boot-actuator/pom.xml`: reference POM
- `.github/workflows/`: optional GitHub reference workflows kept for comparison

## Reusing this component in another repository

This repository is meant to be reused as a CI/CD component.
When you copy the workflows into another repository, the snapshot and release jobs act on that consumer repository, not on this POC.

For a consumer repository, adapt at least:

1. `CI_PROJECT_DIR` so the workflows point to the correct `pom.xml`
2. the consumer `pom.xml` `scm` section
3. the consumer `pom.xml` `distributionManagement`
4. the registry credentials and release token for that repository
5. the default branch protection rules expected by the release workflow

What the consumer project must own:

- its Maven coordinates
- its SCM coordinates
- its target registry
- its secrets and variables

The reusable component only orchestrates the lifecycle:

- `mvn clean verify`
- quality and security gates
- snapshot publication
- `mvn release:prepare release:perform`

If a consumer project forgets to update its `pom.xml`, the release can still target the wrong SCM or registry.
So the main integration checkpoint is always the consumer project's own `pom.xml`.

## GitLab pipeline model

Stages:

1. `build_test`
2. `sonar_quality`
3. `owasp_security`
4. `snapshot_publish_auto`
5. `snapshot_publish_manual`
6. `release`

Execution rules:

- `build_test` runs `mvn clean verify`
- tests run once in `build_test`
- `sonar_quality` and `owasp_security` stay separated by responsibility
- snapshot publication uses `-DskipTests`
- release uses `-DskipTests`
- release is manual and only available on the protected default branch

## GitLab CI/CD variables

Default variables:

- `PROJECT_DIR=examples/spring-boot-actuator`
- `MAVEN_CLI_OPTS=-B -ntp`
- `MAVEN_DEPLOY_SERVER_ID=gitlab-maven`
- `GIT_DEPTH=0`
- `SNAPSHOT_BRANCH_REGEX=^US[0-9][A-Za-z0-9._/-]*$`
- `ENABLE_SONAR=false`
- `SONAR_ALLOW_FAILURE=true`
- `ENABLE_OWASP=true`
- `OWASP_ALLOW_FAILURE=false`
- `OWASP_ALLOW_WITHOUT_NVD_API_KEY=false`
- `OWASP_FAIL_CVSS=9.0`
- `OWASP_NVD_VALID_HOURS=24`
- `RELEASE_ARGS=-DskipTests -Dquality.owasp.skip=true -Dsonar.skip=true`

Masked or protected variables when needed:

- `MAVEN_SETTINGS_XML`
- `MAVEN_REGISTRY_USERNAME`
- `MAVEN_REGISTRY_PASSWORD`
- `SONAR_TOKEN`
- `SONAR_PROJECT_KEY`
- `SONAR_ORGANIZATION`
- `SONAR_HOST_URL`
- `NVD_API_KEY`
- `RELEASE_PUSH_TOKEN`

Effective defaults:

- Sonar stays disabled until you configure it
- OWASP stays enabled
- OWASP is skipped if `NVD_API_KEY` is absent and `OWASP_ALLOW_WITHOUT_NVD_API_KEY=false`
- automatic snapshot publication is limited to branches matching `^US[0-9][A-Za-z0-9._/-]*$`
- manual snapshot remains available on any branch
- release stays manual and protected-branch only

## Release versioning

The release job delegates version parsing to Maven plugins instead of custom shell math:

- `maven-help-plugin` reads `project.version`
- `build-helper-maven-plugin` parses the target release version
- `maven-release-plugin` performs the tag, commit and next snapshot bump

Default behavior:

- if `RELEASE_VERSION` is empty, release the current snapshot base version
- if `NEXT_SNAPSHOT_VERSION` is empty, compute the next patch snapshot automatically
- Git tag matches the release version exactly, for example `1.0.0`
- the GitHub release workflow can also create a GitHub release entry from the Git tag so the version is visible in the `Releases` tab

## GitHub reference workflows

The GitHub reference workflows keep the manual `Snapshot` and `Release` buttons visible because GitHub Actions cannot gray them out dynamically.
Instead, they stop immediately unless the full `Maven Build, Test and Quality` workflow succeeded for the selected commit.

## Notes

- The sample `pom.xml` still points to GitHub coordinates because this example repository itself is hosted on GitHub. A real GitLab consumer project must replace `distributionManagement` and `scm`.
- `templates/maven-settings.xml` now targets GitLab Package Registry by default.
- If you prefer Nexus or Artifactory, keep the same server id alignment between `distributionManagement`, `settings.xml` and the pipeline variables.
- `docs/gitlab-end-to-end.md` is now the main setup guide.
