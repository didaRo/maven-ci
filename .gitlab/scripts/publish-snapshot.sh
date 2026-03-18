#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

mode="${1:-manual}"

case "$mode" in
  auto)
    if ! printf '%s' "${CI_COMMIT_BRANCH:-}" | grep -Eq "${SNAPSHOT_BRANCH_REGEX}"; then
      echo "Branch ${CI_COMMIT_BRANCH:-unknown} does not match SNAPSHOT_BRANCH_REGEX=${SNAPSHOT_BRANCH_REGEX}. Nothing to publish."
      exit 0
    fi
    ;;
  manual)
    if [ "${CI_COMMIT_BRANCH:-}" != "${CI_DEFAULT_BRANCH:-}" ] && ! printf '%s' "${CI_COMMIT_BRANCH:-}" | grep -Eq "${SNAPSHOT_BRANCH_REGEX}"; then
      echo "Manual snapshot is allowed only on the default branch or on branches matching SNAPSHOT_BRANCH_REGEX=${SNAPSHOT_BRANCH_REGEX}."
      exit 0
    fi
    ;;
  *)
    echo "Unsupported snapshot mode: $mode"
    exit 1
    ;;
esac

current_version="$(gitlab_component::ensure_snapshot_version)"
echo "Publishing snapshot $current_version from branch ${CI_COMMIT_BRANCH:-unknown}"

gitlab_component::load_maven_cli_args
"$MVN" "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" -DskipTests deploy
