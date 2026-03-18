# GitHub Reference Workflows

This repository also ships a GitHub reference implementation for the same Maven lifecycle.
It is not the GitLab catalog itself.

Visible workflows:

- `.github/workflows/maven-ci.yml`
- `.github/workflows/maven-snapshot.yml`
- `.github/workflows/maven-release.yml`

Internal reusable workflows:

- `.github/workflows/reusable-maven-build-test-quality.yml`
- `.github/workflows/reusable-maven-snapshot.yml`
- `.github/workflows/reusable-maven-release.yml`

## 1. Shared Maven settings

Use one shared secret named `MAVEN_SETTINGS_XML`.
Do not commit `settings.xml` in consumer repositories.

Recommended setup:

1. Go to `Organization settings > Secrets and variables > Actions`
2. Create a secret named `MAVEN_SETTINGS_XML`
3. Paste the full XML content of your Maven `settings.xml`
4. Grant it to the repositories that use the reusable workflows

If one repository needs a different registry configuration, override the same secret name locally.

Example for GitHub Packages:

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

## 2. Workflow behavior

### Validation

`Maven Build, Test, Quality and Security`:

- runs on `push`
- runs on `pull_request`
- can also be relaunched manually

### Snapshot

`Maven Snapshot Publish`:

- can be launched manually on any branch
- runs automatically after a successful validation workflow on a story branch matching `CI_SNAPSHOT_BRANCH_REGEX`
- publishes with `-DskipTests`

### Release

`Maven Release`:

- is manual
- runs only from the protected default branch
- requires the validation workflow to be green on the selected commit

## 3. Release prerequisites

Required in most repositories:

- `MAVEN_SETTINGS_XML`
- `RELEASE_PAT`

Optional repository or organization variable:

- `MAVEN_REPOSITORY_OWNER`

GitHub Packages notes:

- The canonical GitHub Packages configuration is `${env.GITHUB_ACTOR}` with `${env.GITHUB_TOKEN}` in `settings.xml`.
- The reusable workflows also expose `MAVEN_REPOSITORY_OWNER` and `MAVEN_REPOSITORY_TOKEN` for compatibility, but the recommended GitHub configuration is the built-in pair above.
- Set `MAVEN_REPOSITORY_OWNER` explicitly only when you intentionally keep a custom `settings.xml` that references it.

Optional:

- `GPG_PRIVATE_KEY`
- `GPG_PASSPHRASE`
- `SONAR_TOKEN`
- `NVD_API_KEY`

The release workflow:

- calls `maven-release-plugin`
- passes `tag`, `releaseVersion`, and `developmentVersion`
- creates a Git tag that matches the release version exactly
- expects the source `pom.xml` to stay on a `-SNAPSHOT` version with `scm.tag` set to `HEAD`

## 4. Witness project

`examples/spring-boot-actuator/` is the witness consumer used to validate the reusable workflows on a real Maven project.
It is not the model every consumer repository must publish unchanged.
