#!/usr/bin/env bash

# This script ignores certain paths for Time Machine backups
# Based on: https://gist.github.com/peterdemartini/4c918635208943e7a042ff5ffa789fc1

# Usage: tmexclude.sh ~/Path/to/code

if [ $# -eq 0 ]; then
    echo "Usage: tmexclude.sh ~/Path/to/code"
    exit
fi

# Always exclude downloads folder
tmutil addexclusion ~/Downloads
tmutil isexcluded ~/Downloads

# Ignore vendor and node_modules folders
find $1 -maxdepth 8 -type d -name node_modules -prune -exec tmutil addexclusion {} \;  -exec tmutil isexcluded {} \; -o -name vendor -prune -exec tmutil addexclusion {} \; -exec tmutil isexcluded {} \;
