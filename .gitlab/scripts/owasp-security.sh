#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

if [ "${ENABLE_OWASP:-true}" != "true" ]; then
  echo "OWASP skipped because ENABLE_OWASP=false."
  exit 0
fi

if [ -z "${NVD_API_KEY:-}" ] && [ "${OWASP_ALLOW_WITHOUT_NVD_API_KEY:-false}" != "true" ]; then
  echo "OWASP skipped. Configure NVD_API_KEY or set OWASP_ALLOW_WITHOUT_NVD_API_KEY=true."
  exit 0
fi

gitlab_component::load_maven_cli_args
owasp_args=(
  "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}"
  -f "$PROJECT_DIR/pom.xml"
  -Psecurity
  -DskipTests
  -Dquality.owasp.skip=false
  -Dquality.owasp.fail.cvss="$OWASP_FAIL_CVSS"
  -Dquality.owasp.nvd.valid.hours="$OWASP_NVD_VALID_HOURS"
  -Dquality.owasp.data.directory="$CI_PROJECT_DIR/.m2/dependency-check-data"
)

if gitlab_component::run_with_optional_failure "${OWASP_ALLOW_FAILURE:-false}" "$MVN" "${owasp_args[@]}" dependency-check:check; then
  exit 0
fi

if [ "${OWASP_ALLOW_FAILURE:-false}" = "true" ]; then
  echo "OWASP failed but OWASP_ALLOW_FAILURE=true, continuing."
  exit 0
fi

exit 1
