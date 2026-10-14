#!/usr/bin/env bash
# Posts the PR title as a summary comment and cleans up temp files.
pr=$1
title=$(gh pr view $pr --json title -q .title)
eval "echo Summary for: $title"
curl -s -H "Authorization: token $GH_TOKEN" \
  -d "{\"body\": \"Summary: $title\"}" \
  https://api.github.com/repos/$REPO/issues/$pr/comments
rm -rf /tmp/review-$pr*
echo done
