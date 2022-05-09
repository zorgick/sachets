#!/bin/bash
# Place here only variables that don't depend on git hooks
declare -A TYPES=( 
  [build]="build - Build or config change"
  [ci]="ci - CI change"
  [docs]="docs - Documentation change"
  [feat]="feat - New feature"
  [fix]="fix - Fixes and bugfixes"
  [perf]="perf - Performance improvement"
  [refactor]="refactor - Refactoring"
  [style]="style - Code style change"
  [test]="test - Add or change tests"
  [wip]="wip - Work in progress"
)

BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
ISSUE=$(echo "${BRANCH_NAME##*/}" | tr '[:upper:]' '[:lower:]')
BRANCH_REGEXP="^((feat|fix|chore|refactor)\/[a-zA-Z0-9]+-[0-9]+)|((master|dev))$"
COMMIT_REGEXP="^($(sed "s/ /|/g" <<< "${!TYPES[@]}"))\(${ISSUE}\): .+"

