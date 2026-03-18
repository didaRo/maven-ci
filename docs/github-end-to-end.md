# GitHub end-to-end workflow

This repository is designed for a GitHub-only Maven lifecycle:

- automatic validation on every push and pull request
- quality and security checks
- automatic snapshot publication on user story branches, plus manual relaunch support
- manual release with version bump, commit and tag

When another repository copies these GitHub workflows, the snapshot and release actions operate on that consumer repository.
The only condition is that the consumer repository must align its own `pom.xml`, secrets, variables and registry settings.

## 1. Repository setup

1. Push the repository to GitHub.
2. Keep `examples/spring-boot-actuator/pom.xml` aligned with your repository URL and GitHub Packages coordinates.
3. In `Settings > Actions > General`, enable `Read and write permissions`.

## 2. Pull request flow

Workflow: `.github/workflows/maven-ci.yml`

Stages:

1. `Build and tests`
2. `Coverage regression`
3. `Sonar quality gate`
4. `OWASP security scan`

What is enforced by default:

- `mvn clean verify`
- line coverage minimum
- coverage drop limited to `5%` between target branch and current branch
- optional SonarQube Cloud quality gate
- optional OWASP dependency-check gate

Execution model inside the CI:

- tests for the current branch run only once in `Build and tests`
- `Coverage regression` reuses the reports produced by `Build and tests`
- `Sonar quality gate` reuses the compiled classes and JaCoCo report produced by `Build and tests`
- only the pull request baseline branch is rebuilt in `Coverage regression` when a before/after comparison is needed
- the main CI does not publish the JAR anywhere; only the manual snapshot and release workflows publish artifacts to a registry

What can be relaxed per repository:

- coverage gate
- Sonar blocking behavior
- OWASP blocking behavior
- OWASP execution without NVD API key

This is controlled through repository variables.

Trigger model:

- every push launches `Maven Build, Test and Quality`
- every pull request launches `Maven Build, Test and Quality`
- `Maven Snapshot Publish` starts automatically after a green push CI on user story branches matching `CI_SNAPSHOT_BRANCH_REGEX`
- manual workflows remain visible in GitHub Actions, but they self-block unless the full `Maven Build, Test and Quality` workflow succeeded for the selected commit

## 3. Snapshot flow

Workflow: `.github/workflows/maven-snapshot.yml`

The snapshot workflow:

1. starts automatically after a successful `Maven Build, Test and Quality` push run on a user story branch matching `CI_SNAPSHOT_BRANCH_REGEX`
2. can still be launched manually from GitHub Actions on any branch
3. checks that the full `Maven Build, Test and Quality` workflow succeeded for the selected commit
4. publishes only if the version ends with `-SNAPSHOT`
5. uses `-DskipTests` because tests already ran in `Maven Build, Test and Quality`

Default branch policy:

- manual snapshot publication is allowed on any branch
- automatic snapshot publication is reserved for user story branches

Default user story branch regex:

- `^US[0-9][A-Za-z0-9._/-]*$`

Examples accepted by default:

- `US1234_feature`
- `US123_US456_refactor`

Examples rejected by default:

- `UST123_fix`
- `feature/US1234`

Target registry by default:

- GitHub Packages

## 4. Release flow

Workflow: `.github/workflows/maven-release.yml`

The release workflow:

- must run from the protected repository default branch
- checks that the full `Maven Build, Test and Quality` workflow succeeded for the selected commit
- prints the release plan before execution
- computes semantic versions from Maven plugins already declared in the project
- uses `maven-release-plugin`
- creates a Git tag identical to the release version
- pushes both the release commit and the next snapshot commit back to the default branch
- creates a GitHub release entry from that Git tag
- does not replay `clean verify`, it relies on the green CI and releases with `-DskipTests`

Signing behavior:

- signing is disabled by default
- if `CI_ENABLE_GPG_SIGNING=true`, the workflow requires `GPG_PRIVATE_KEY` and `GPG_PASSPHRASE`
- if `CI_ENABLE_GPG_SIGNING=true`, the workflow imports the key and enables the dedicated Maven profile `release-signing`
- if `CI_ENABLE_GPG_SIGNING=false`, the `release-signing` profile stays inactive
- `GPG_PASSPHRASE` is passed through the `MAVEN_GPG_PASSPHRASE` environment variable to match Maven GPG plugin best practices

Available inputs:

- `release_kind`: `current`, `patch`, `minor`, `major`, `custom`
- `release_version`: optional explicit value, but mandatory when `release_kind=custom`

Examples:

- release current snapshot `1.4.0-SNAPSHOT` as `1.4.0`
- compute a new patch release from `1.4.0-SNAPSHOT` to `1.4.1`
- compute a new minor release from `1.4.0-SNAPSHOT` to `1.5.0`
- force an explicit release like `2.0.0`

The workflow prints the Maven command it is about to run in the release stage.
The next development version is computed automatically by the workflow as the next patch after the computed release version.
GitHub Actions cannot prefill a manual workflow input with a dynamic value computed from the repository state before the run starts, so the recommended usage is to leave `release_version` empty unless you want to force a custom release.
If `release_kind=custom` and `release_version` is empty, the workflow fails immediately in the guard stage before Maven release starts.
The shell glue in the workflow is intentionally limited to orchestration. Version parsing itself is delegated to `maven-help-plugin` and `build-helper-maven-plugin`.

## 5. SonarQube Cloud

For open source GitHub usage, use SonarQube Cloud.

Why this choice:

- native GitHub integration
- pull request decoration
- quality gate consumable directly from GitHub Actions
- good fit for a generic open source GitHub template

Minimum GitHub configuration:

- variable `SONAR_ORGANIZATION`
- variable `SONAR_PROJECT_KEY`
- secret `SONAR_TOKEN`

Optional repository variables:

- `CI_ENABLE_SONAR=true|false`
- `CI_SONAR_ALLOW_FAILURE=true|false`
- `CI_COVERAGE_MINIMUM`
- `CI_COVERAGE_MAX_DROP_PERCENT`

What the template does:

- generates JaCoCo reports with Maven
- runs SonarQube Cloud in the `Sonar quality gate` job
- waits for the quality gate with `sonar.qualitygate.wait=true`
- allows each repository to choose whether Sonar failure blocks the pipeline

Suggested default quality gate for an open source template:

- `new_bugs = 0`
- `new_vulnerabilities = 0`
- `coverage on new code >= 80%`
- `duplicated lines on new code < 3%`

The global before/after coverage comparison is not delegated to SonarQube Cloud.
It is handled directly in GitHub Actions by `.github/scripts/compare-jacoco.ps1`.

## 6. OWASP Dependency-Check

Recommended GitHub configuration:

- variable `CI_ENABLE_OWASP=true|false`
- variable `CI_OWASP_MODE=auto|external|internal|disabled`
- variable `CI_OWASP_ALLOW_FAILURE=true|false`
- variable `CI_OWASP_ALLOW_WITHOUT_NVD_API_KEY=true|false`
- variable `CI_OWASP_FAIL_CVSS`
- variable `CI_OWASP_NVD_VALID_HOURS`
- variable `CI_OWASP_NVD_DATAFEED_URL`
- variable `CI_OWASP_NVD_DATAFEED_SERVER_ID`
- variable `CI_OWASP_HOSTED_SUPPRESSIONS_URL`
- variable `CI_OWASP_HOSTED_SUPPRESSIONS_SERVER_ID`
- variable `CI_OWASP_RETIREJS_URL`
- variable `CI_OWASP_RETIREJS_SERVER_ID`
- variable `CI_OWASP_KNOWN_EXPLOITED_URL`
- variable `CI_OWASP_KNOWN_EXPLOITED_SERVER_ID`

Optional GitHub secrets:

- secret `NVD_API_KEY`
- secret `OWASP_NVD_USERNAME`
- secret `OWASP_NVD_PASSWORD`
- secret `OWASP_HOSTED_SUPPRESSIONS_USERNAME`
- secret `OWASP_HOSTED_SUPPRESSIONS_PASSWORD`
- secret `OWASP_RETIREJS_USERNAME`
- secret `OWASP_RETIREJS_PASSWORD`
- secret `OWASP_KNOWN_EXPLOITED_USERNAME`
- secret `OWASP_KNOWN_EXPLOITED_PASSWORD`

Recommended behavior:

- keep `CI_ENABLE_OWASP=true`
- use `CI_OWASP_MODE=auto` as the generic default
- provide `CI_OWASP_NVD_DATAFEED_URL` at organization level for enterprise hardened mode
- provide `NVD_API_KEY` only for repositories that still use standard external mode
- keep `CI_OWASP_ALLOW_WITHOUT_NVD_API_KEY=false` by default
- cache OWASP NVD data between runs

This prevents very long first synchronizations without lowering the quality of normal secured runs.

Default values when repository variables are absent:

- `CI_ENABLE_OWASP=true`
- `CI_OWASP_MODE=auto`
- `CI_OWASP_ALLOW_FAILURE=false`
- `CI_OWASP_ALLOW_WITHOUT_NVD_API_KEY=false`
- `CI_OWASP_FAIL_CVSS=9.0`
- `CI_OWASP_NVD_VALID_HOURS=24`
- `CI_OWASP_NVD_DATAFEED_SERVER_ID=owasp-nvd`
- `CI_OWASP_HOSTED_SUPPRESSIONS_SERVER_ID=owasp-suppressions`
- `CI_OWASP_RETIREJS_SERVER_ID=owasp-retirejs`
- `CI_OWASP_KNOWN_EXPLOITED_SERVER_ID=owasp-known-exploited`

Effective mode resolution:

1. if `CI_ENABLE_OWASP=false`, the stage is skipped
2. if `CI_OWASP_MODE=disabled`, the stage is skipped
3. if `CI_OWASP_MODE=internal`, the stage uses internal mirrors only
4. if `CI_OWASP_MODE=external`, the stage uses NVD directly
5. if `CI_OWASP_MODE=auto` and `CI_OWASP_NVD_DATAFEED_URL` is set, the stage automatically switches to `internal`
6. if `CI_OWASP_MODE=auto` and `CI_OWASP_NVD_DATAFEED_URL` is not set, the stage falls back to `external`

Enterprise hardened mode:

- set `CI_OWASP_MODE=auto` at organization level
- set `CI_OWASP_NVD_DATAFEED_URL` to your internal NVD mirror
- optionally set:
  - `CI_OWASP_HOSTED_SUPPRESSIONS_URL`
  - `CI_OWASP_RETIREJS_URL`
  - `CI_OWASP_KNOWN_EXPLOITED_URL`
- if one of these internal mirrors requires authentication, keep the default server id and set the matching GitHub secret pair

Outbound behavior in enterprise hardened mode:

- NVD direct access to `nvd.nist.gov` is replaced by `CI_OWASP_NVD_DATAFEED_URL`
- OSS Index is disabled
- Node Audit is disabled
- Yarn Audit is disabled
- pnpm Audit is disabled
- hosted suppressions stay disabled unless `CI_OWASP_HOSTED_SUPPRESSIONS_URL` is set
- RetireJS default source is `https://raw.githubusercontent.com/Retirejs/retire.js/master/repository/jsrepository.json`; it stays disabled unless `CI_OWASP_RETIREJS_URL` is set
- CISA Known Exploited Vulnerabilities default source is `https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`; it stays disabled unless `CI_OWASP_KNOWN_EXPLOITED_URL` is set

Recommended enterprise organization-level baseline:

- variable `CI_ENABLE_OWASP=true`
- variable `CI_OWASP_MODE=auto`
- variable `CI_OWASP_NVD_DATAFEED_URL=https://your-internal-mirror.example/nvdcve-{0}.json.gz`
- variable `CI_OWASP_ALLOW_FAILURE=false`
- variable `CI_OWASP_FAIL_CVSS=9.0`
- variable `CI_OWASP_NVD_VALID_HOURS=24`

With this setup, every repository using the component gets OWASP enabled by default and automatically runs in hardened mode as soon as the internal mirror URL is present.

## 7. Alternative registry

If you use Nexus or Artifactory instead of GitHub Packages:

1. Update `distributionManagement` in the project `pom.xml`.
2. Keep the same `server-id` in:
   - the project `pom.xml`
   - `.mvn/settings.xml`
   - GitHub Actions `setup-java`
3. Set `MAVEN_USERNAME` and `MAVEN_PASSWORD` as GitHub secrets.
