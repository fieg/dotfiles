alias gfa='git fetch --all'
alias gmaster='greset master'
alias gmain='greset main'

__detectMainBranch() {
  if [ -n "$1" ]
  then
    echo "$1"
    return 0
  fi

  >&2 echo -n "Automatically detecting HEAD branch..."
  branch=$(git remote show origin 2> /dev/null | grep 'HEAD branch' | cut -d' ' -f 5)

  >&2 echo " $branch"

  if [ "$branch" = "master" ] || [ "$branch" = "main" ] || [ "$branch" = "trunk" ]
  then
    echo "$branch"
  else
    echo ""
  fi
}

greset() {
  branch=$(__detectMainBranch "$1")

  if [ -z "$branch" ]
  then
    echo "Usage: $0 [branch]"
    echo "Example: $0 main"
    echo "Example: $0 # will attempt to fallback on HEAD branch"
    return 1
  fi

  git fetch origin
  git stash
  git checkout -B $branch origin/$branch --track
  git stash pop
}

grebase() {
  if [ "$1" = "--abort" ] || [ "$1" = "--continue" ]
  then
    git rebase $1
    return 0
  fi

  branch=$(__detectMainBranch "$1")

  if [ -z "$branch" ]
  then
    echo "Usage: $0 [branch]"
    echo "Example: $0 main"
    echo "Example: $0 # will attempt to fallback on HEAD branch"
    return 1
  fi

  git fetch origin
  git rebase origin/$branch --autostash
}
