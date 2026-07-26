#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

output=$(tofu -chdir="$(dirname "$0")/../shikanime-hcp" output -json)
projects=$(echo "$output" | jq -r '.projects.value')

echo "$projects" | jq -r '.studio' >"$(dirname "$0")/studio.tfvars.json"
echo "$projects" | jq -r '.["studio-labs"]' >"$(dirname "$0")/studio-labs.tfvars.json"
