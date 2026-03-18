# GitLab End To End

This repository is structured as a GitLab CI/CD Catalog project.
The default entrypoint for consumer repositories is `maven-ci`.

## 1. Consumer include

```yaml
include:
  - component: $CI_SERVER_FQDN/my-group/maven-catalog/maven-ci@1.0.0
    inputs:
      project_dir: .
```

Pin a released version tag for normal usage.
Use `@$CI_COMMIT_SHA` only to test the component project itself.

## 2. Shared Maven settings

The standard mechanism is a single CI/CD variable named `MAVEN_SETTINGS_XML`.

Recommended setup:

1. Go to the highest common scope:
   - `Group > Settings > CI/CD > Variables`
   - or `Admin > Settings > CI/CD > Variables`
2. Create `MAVEN_SETTINGS_XML`
3. Type: `File`
4. Paste the full XML content of your Maven `settings.xml`
5. Mark it `Protected` when publication is limited to protected refs
6. Save

Inheritance model:

- define it once at the highest common group and let subgroups/projects inherit it
- if a project needs a special registry configuration, override the same key locally
- do not duplicate a committed `settings.xml` in every consumer repository

The components accept two forms:

- a GitLab file variable path
- raw XML content

Typical GitLab Package Registry server entry:

```xml
<server>
  <id>gitlab-maven</id>
  <configuration>
    <httpHeaders>
      <property>
        <name>Job-Token</name>
        <value>${env.CI_JOB_TOKEN}</value>
      </property>
    </httpHeaders>
  </configuration>
</server>
```

Typical `distributionManagement`:

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

## 3. Component defaults

`maven-ci` is designed so that most projects only need to override `project_dir`.

Default behavior:

- `mvn clean verify`
- Sonar disabled by default
- OWASP enabled by default
- automatic snapshot on branches matching `^US[0-9][A-Za-z0-9._/-]*$`
- manual snapshot enabled
- manual release only on the protected default branch
- release profile `release`
- next snapshot strategy `patch`

## 4. Variables used by the jobs

Usually required:

- `MAVEN_SETTINGS_XML`
- `RELEASE_PUSH_TOKEN`

Optional:

- `SONAR_PROJECT_KEY`
- `SONAR_TOKEN`
- `SONAR_ORGANIZATION`
- `NVD_API_KEY`
- `RELEASE_VERSION`
- `NEXT_SNAPSHOT_VERSION`

## 5. Consumer prerequisites

The component does not define the identity of the consumer project.
The consumer repository must still provide:

- a valid `pom.xml`
- a correct `scm` section
- a correct `distributionManagement` section
- a protected default branch for release

## 6. Witness project

`examples/spring-boot-actuator/` is only the witness consumer used to validate the catalog.
It is not the deliverable that consumer repositories are expected to publish.
