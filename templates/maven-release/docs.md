# Maven Release

Low-level release component.

It provides:

- manual release on the protected default branch
- `mvn release:prepare release:perform`
- explicit `tag`, `releaseVersion`, and `developmentVersion`

Example:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-group/maven-catalog/maven-release@1.0.0
    inputs:
      project_dir: .
```

Required runtime values:

- `MAVEN_SETTINGS_XML`
- `RELEASE_PUSH_TOKEN`

Optional runtime values:

- `RELEASE_VERSION`
- `NEXT_SNAPSHOT_VERSION`

Defaults:

- release profile `release`
- next snapshot strategy `patch`
