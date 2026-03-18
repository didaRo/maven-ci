# Maven CI/CD Components

Reusable GitLab CI/CD Catalog components for Maven Java projects.
The repository also keeps a GitHub reference implementation that follows the same lifecycle.

`examples/spring-boot-actuator/` is only a witness consumer.
It exists to validate the components end to end and catch regressions on a real Spring Boot Maven project.

## What You Get

### `maven-ci`

Recommended entrypoint for most projects.
It wires the lifecycle in this order:

1. build and test
2. Sonar quality gate
3. OWASP dependency-check
4. snapshot publish
5. release

### `maven-build-test-quality`

Low-level validation component:

- `mvn clean verify`
- optional Sonar
- optional OWASP

### `maven-snapshot`

Low-level snapshot component:

- automatic snapshot on story branches
- manual snapshot
- deploy with `-DskipTests`

### `maven-release`

Low-level release component:

- manual release on the protected default branch
- `mvn release:prepare release:perform`
- explicit `tag`, `releaseVersion`, and `developmentVersion`

## Quick Start

### GitLab catalog

```yaml
include:
  - component: $CI_SERVER_FQDN/my-group/maven-catalog/maven-ci@1.0.0
    inputs:
      project_dir: .
```

### Shared Maven settings

Use one shared variable named `MAVEN_SETTINGS_XML`.
Do not commit `settings.xml` in consumer repositories.

GitLab recommendation:

1. Go to the highest common scope:
   - `Group > Settings > CI/CD > Variables`
   - or `Admin > Settings > CI/CD > Variables`
2. Create `MAVEN_SETTINGS_XML`
3. Type: `File`
4. Paste the full XML content of your Maven `settings.xml`
5. Mark it `Protected` if publication only happens from protected refs

GitHub reference recommendation:

1. Go to `Organization settings > Secrets and variables > Actions`
2. Create a secret named `MAVEN_SETTINGS_XML`
3. Paste the full XML content of your Maven `settings.xml`
4. Grant it to the repositories that use the reusable workflows

Recommended GitHub Packages content:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>github</id>
      <username>${env.GITHUB_ACTOR}</username>
      <password>${env.GITHUB_TOKEN}</password>
    </server>
  </servers>
</settings>
```

For GitHub Packages, also declare:

- `MAVEN_REPOSITORY_OWNER`: optional override for the username referenced by `settings.xml`

The GitHub reference workflows already expose the built-in workflow token to Maven.
They also keep `MAVEN_REPOSITORY_OWNER` and `MAVEN_REPOSITORY_TOKEN` for compatibility when one repository needs a custom `settings.xml`.

The same key can then be overridden at project or repository level when one project needs a different registry configuration.

## Minimal Consumer Checklist

A consumer project must still own:

- its `pom.xml`
- its `distributionManagement`
- its `scm` section
- its protected secrets and variables
- its branch protection policy

For Maven release automation, keep the source `pom.xml` on a `-SNAPSHOT` version and keep `scm.tag` set to `HEAD`.

Required runtime values in most projects:

- `MAVEN_SETTINGS_XML`
- `RELEASE_PUSH_TOKEN` for release pushes
- `SONAR_TOKEN` only if Sonar is enabled
- `NVD_API_KEY` only if OWASP runs against external NVD feeds

## Why This Repo Uses Defaults Heavily

The components are designed for enterprise reuse:

- most projects should only override `project_dir`
- platform defaults live in component inputs
- enterprise defaults live in shared CI variables and secrets
- only exceptional projects need local overrides

## Repository Layout

- `templates/`: publishable GitLab catalog components
- `.gitlab-ci.yml`: pipeline that tests the catalog from the current SHA and publishes catalog releases on tags
- `docs/gitlab-end-to-end.md`: GitLab setup guide
- `docs/github-end-to-end.md`: GitHub reference guide
- `.github/workflows/`: GitHub reusable workflows plus three visible witness workflows
- `.github/actions/` and `.github/scripts/`: GitHub-only support assets
- `examples/spring-boot-actuator/`: witness consumer used for regression checks

## Notes

- The GitLab components are self-contained in `templates/`
- The GitHub side is now separated into three visible workflows: validation, snapshot, and release
- `.github/scripts/compare-jacoco.ps1` stays useful for the GitHub coverage regression gate and is not part of the GitLab catalog surface
