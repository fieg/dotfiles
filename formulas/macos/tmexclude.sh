#!/usr/bin/env bash

# This script ignores certain paths for Time Machine backups
# Based on: https://gist.github.com/peterdemartini/4c918635208943e7a042ff5ffa789fc1

# Usage: tmexclude.sh ~/Path/to/code

if [ $# -lt 1 ]; then
    echo "Usage: tmexclude.sh ~/Path/to/code"
    exit
fi

CODE_PATH=$1

# Always exclude downloads folder
EXCLUDED_DIRECTORIES=( "~/Downloads" "~/.composer" "~/.npm/" )

for EXCLUDED_DIRECTORY in "${EXCLUDED_DIRECTORIES[@]}"; do
  tmutil addexclusion ${EXCLUDED_DIRECTORY}
  tmutil isexcluded ${EXCLUDED_DIRECTORY}
done

# Ignore vendor and node_modules folders
find $CODE_PATH -maxdepth 8 -type d -name node_modules -prune -exec tmutil addexclusion {} \;  -exec tmutil isexcluded {} \; -o -name vendor -prune -exec tmutil addexclusion {} \; -exec tmutil isexcluded {} \;
