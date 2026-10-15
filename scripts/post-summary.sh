#!/usr/bin/env bash
# Prints the title of the pull request whose number is the first argument.
set -euo pipefail
pr="${1:?usage: post-summary.sh <pull request number>}"
[[ "$pr" =~ ^[0-9]+$ ]] || { echo "pull request number must be digits, got '$pr'" >&2; exit 1; }
title=$(gh pr view "$pr" --json title --jq .title)
printf 'Summary for: %s\n' "$title"
# Usage: post-summary.sh <pull request number>
