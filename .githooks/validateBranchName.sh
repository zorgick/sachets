#!/bin/bash
. "$(dirname "$0")/vars.sh"
. "$(dirname "$0")/common.sh"

if [[ $BRANCH_NAME == "HEAD" ]]; then
  log info "Detached head state detected. Skipping branch checks."
elif [[ ! $BRANCH_NAME =~ $BRANCH_REGEXP ]]; then
  log error "\nCurrent branch name \"$BRANCH_NAME\" violates branch naming conventions."
  exit 1
else
  log success "Branch name was validated successfully"
fi
