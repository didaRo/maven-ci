# GitLab end-to-end workflow

This repository now exposes a GitLab-first CI/CD component for Java Maven projects.
GitHub workflows remain in `.github/workflows/` as a reference, but Jenkins has been removed.

This component is reusable.
When another repository copies `.gitlab-ci.yml` and the related templates, the pipeline releases that consumer repository, provided its own `pom.xml`, variables and registry settings are aligned.

## 1. Main pipeline

File: `.gitlab-ci.yml`

The GitLab shell logic is intentionally kept in versioned scripts under `.gitlab/scripts/` to make the component easier to review and maintain than large inline `before_script` and `script` blocks.

Stages:

1. `build_test`
2. `sonar_quality`
3. `owasp_security`
4. `snapshot_publish_auto`
5. `snapshot_publish_manual`
6. `release`

Execution model:

- `build_test` runs `mvn clean verify` on every push and merge request
- tests run once in `build_test`
- `sonar_quality` and `owasp_security` are separated responsibilities
- snapshot publication uses `-DskipTests`
- release uses `-DskipTests` and relies on the green validation pipeline

## 2. GitLab package registry

For a GitLab-native project, align the project `pom.xml` with the GitLab Maven registry.

Recommended `distributionManagement` snippet:

```xml
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>${env.CI_API_V4_URL}/projects/${env.CI_PROJECT_ID}/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>${env.CI_API_V4_URL}/projects/${env.CI_PROJECT_ID}/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

Recommended `settings.xml` server entry:

```xml
<server>
  <id>gitlab-maven</id>
  <username>gitlab-ci-token</username>
  <password>${env.CI_JOB_TOKEN}</password>
</server>
```

If you prefer a deploy token, replace:

- `gitlab-ci-token` with your deploy token username
- `${env.CI_JOB_TOKEN}` with `${env.MAVEN_REGISTRY_PASSWORD}`

The provided template `templates/maven-settings.xml` is GitLab-oriented and ready to be injected through a masked GitLab variable.

## 3. GitLab CI/CD variables

Recommended project variables and defaults:

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

Effective defaults when nothing is set:

- Sonar stays disabled
- OWASP stays enabled
- OWASP is skipped if `NVD_API_KEY` is absent and `OWASP_ALLOW_WITHOUT_NVD_API_KEY` stays `false`
- snapshots are automatic only on branches matching `^US[0-9][A-Za-z0-9._/-]*$`
- release is manual and only visible on the protected default branch

## 4. Snapshot flow

The GitLab component exposes two jobs:

- `snapshot_publish_auto`: runs automatically on push for user story branches
- `snapshot_publish_manual`: remains available manually on the default branch and on user story branches

Default accepted user story branch examples:

- `US1234_feature`
- `US123_US456_refactor`

Default rejected examples:

- `UST123_fix`
- `feature/US1234`

Both snapshot jobs:

- verify that the Maven version ends with `-SNAPSHOT`
- publish with `-DskipTests`
- rely on the validation stage instead of rerunning tests

## 5. Release flow

The `release` job is:

- manual
- restricted to the protected default branch
- serialized through `resource_group: release`

The job computes versions from Maven plugins:

- `maven-help-plugin` reads `project.version`
- `build-helper-maven-plugin` parses the release version
- `maven-release-plugin` performs `release:prepare release:perform`

Default release behavior:

- if `RELEASE_VERSION` is empty, release the current snapshot base version
- if `NEXT_SNAPSHOT_VERSION` is empty, compute the next patch snapshot automatically
- Git tag equals the release version exactly, for example `1.0.0`

Examples:

- current version `0.4.0-SNAPSHOT` and no extra variables -> release `0.4.0`, next snapshot `0.4.1-SNAPSHOT`
- `RELEASE_VERSION=1.2.0` and no next snapshot override -> next snapshot `1.2.1-SNAPSHOT`
- `RELEASE_VERSION=2.0.0` and `NEXT_SNAPSHOT_VERSION=2.1.0-SNAPSHOT` -> explicit release plan

For SCM pushes during release, set a protected masked variable:

- `RELEASE_PUSH_TOKEN`

This token must be allowed to push commits and tags on the default branch.

## 6. Important note about the sample project

The sample `examples/spring-boot-actuator/pom.xml` still points to GitHub coordinates because this repository itself is hosted on GitHub.

For a real GitLab consumer project, replace:

- `distributionManagement`
- `scm.connection`
- `scm.developerConnection`
- `scm.url`

with your GitLab values.

Also set `PROJECT_DIR` so the component targets the consumer project's real Maven module instead of the sample path from this repository.
