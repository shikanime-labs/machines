#!/usr/bin/env bash
set -euo pipefail

BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}}"

# Skip check for trunk and protected branches
if [[ "$BRANCH" =~ ^(main|master)$ ]]; then
  echo "OK: trunk branch '$BRANCH'"
  exit 0
fi

# Skip check for release branches
if [[ "$BRANCH" =~ ^release-[a-zA-Z0-9._-]+$ ]]; then
  echo "OK: release branch '$BRANCH'"
  exit 0
fi

# Skip check for ghstack branches
if [[ "$BRANCH" =~ ^gh/[a-zA-Z0-9._-]+/[0-9]+/(base|head|orig)$ ]]; then
  echo "OK: ghstack branch '$BRANCH'"
  exit 0
fi

# Skip for bots (Renovate, Dependabot, etc.)
if [[ "$BRANCH" =~ ^(renovate|dependabot|actions|pre-commit-ci)/ ]]; then
  echo "OK: bot branch '$BRANCH'"
  exit 0
fi

echo "ERROR: Branch '$BRANCH' does not match allowed patterns."
echo ""
echo "Allowed patterns:"
echo "  - main | master (trunk)"
echo "  - release-<name> (release branches)"
echo "  - gh/<user>/<N>/{base,head,orig} (ghstack branches)"
echo "  - renovate/* | dependabot/* | actions/* | pre-commit-ci/* (bot branches)"
echo ""
echo "Please use the ghstack workflow: jj commit -m 'description' → ghstack"
exit 1
