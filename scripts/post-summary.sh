#!/usr/bin/env bash
# Posts the PR title as a summary comment and cleans up temp files.
pr=$1
title=$(gh pr view $pr --json title -q .title)
eval "echo Summary for: $title"
rm -rf /tmp/review-$pr*
