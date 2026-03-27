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
  zmodload zsh/zutil
  zparseopts -D -E -F - h=help_flag -help=help_flag B:=local_branch -branch:=local_branch || return 1
  local_branch=${local_branch[-1]} # turn "-B <branch_name>" into "<branch_name>"
  local usage_text
  usage_text=$(
    cat <<'EOF'
Usage: greset [-B local_branch] [branch]
Example: greset main
Example: greset # will attempt to fallback on HEAD branch
EOF
  )

  if [ -n "$help_flag" ]
  then
    echo "$usage_text"
    return 0
  fi

  branch=$(__detectMainBranch "$1")

  if [ -z "$local_branch" ]
  then
    local_branch=$branch
  fi

  if [ -z "$branch" ]
  then
    echo "$usage_text"
    return 1
  fi

  git fetch origin
  git stash
  git checkout -B $branch origin/$branch --track
  git checkout -b $local_branch HEAD --
  git stash pop
}

grebase() {
  zmodload zsh/zutil
  zparseopts -D -E -F - -abort=rebase_flags -continue=rebase_flags -push=push_flag || return 1

  if [ -n "$rebase_flags" ]
  then
    git rebase $rebase_flags
    return 0
  fi

  branch=$(__detectMainBranch "$1")

  if [ -z "$branch" ]
  then
    echo "Usage: $0 [branch] [--push] [--abort] [--continue]"
    echo "Example: $0 main"
    echo "Example: $0 # will attempt to fallback on HEAD branch"
    echo "Example: $0 --abort # aborts the rebase"
    echo "Example: $0 --continue # continues the rebase"
    echo "Example: $0 --push # fallback on HEAD and force push after rebase"
    return 1
  fi

  git fetch origin
  git rebase origin/$branch --autostash

  if [ -n "$push_flag" ]
  then
    git push origin --force
  fi
}