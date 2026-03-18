#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

if [ "${CI_COMMIT_BRANCH:-}" != "${CI_DEFAULT_BRANCH:-}" ]; then
  echo "Release is allowed only from the default branch."
  exit 1
fi

if [ "${CI_COMMIT_REF_PROTECTED:-false}" != "true" ]; then
  echo "Release requires a protected default branch."
  exit 1
fi

if [ -n "${RELEASE_PUSH_TOKEN:-}" ]; then
  git remote set-url origin "https://oauth2:${RELEASE_PUSH_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git"
else
  echo "RELEASE_PUSH_TOKEN is not configured. Release will rely on the runner checkout credentials."
fi

git config user.name "${GITLAB_USER_NAME:-gitlab-ci}"
git config user.email "${GITLAB_USER_EMAIL:-gitlab-ci@example.com}"
git checkout -B "$CI_COMMIT_BRANCH" "$CI_COMMIT_SHA"

current_version="$(gitlab_component::project_version)"
current_base_version="${current_version%-SNAPSHOT}"
release_version="${RELEASE_VERSION:-$current_base_version}"
release_version="${release_version%-SNAPSHOT}"

if [ -z "${NEXT_SNAPSHOT_VERSION:-}" ]; then
  next_snapshot_version="$(gitlab_component::compute_next_snapshot_version "$release_version")"
else
  next_snapshot_version="${NEXT_SNAPSHOT_VERSION%-SNAPSHOT}-SNAPSHOT"
fi

echo "Release plan"
echo "  current version: $current_version"
echo "  release version: $release_version"
echo "  next snapshot:   $next_snapshot_version"
echo "  git tag:         $release_version"

gitlab_component::load_maven_cli_args
"$MVN" "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" release:clean
"$MVN" "${GITLAB_COMPONENT_MAVEN_CLI_ARGS[@]}" -f "$PROJECT_DIR/pom.xml" \
  -Dtag="$release_version" \
  -DreleaseVersion="$release_version" \
  -DdevelopmentVersion="$next_snapshot_version" \
  -DreleaseProfiles=release \
  -Darguments="$RELEASE_ARGS" \
  release:prepare release:perform
