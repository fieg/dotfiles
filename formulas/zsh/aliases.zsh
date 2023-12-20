# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if $(gls &>/dev/null)
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -lA --color'
fi

# Make zsh know about hosts already accessed by SSH
zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

errcho() { >&2 echo $@; }

# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run
retry() {
    local -r -i max_attempts="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1
    local -i sleep_num=1

    until eval ${cmd}
    do
        if (( attempt_num > max_attempts ))
        then
            return 1
        else
            local -i wait=$(( (attempt_num++)*sleep_num ))
            errcho "[$(date '+%H:%M:%S')] Retry $(( attempt_num-1 ))/${max_attempts} in ${wait}s..."
            sleep ${wait}
        fi
    done

    return $?
}
