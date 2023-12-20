alias d='docker'
alias dc='docker compose'
alias dkillall='docker kill $(docker ps -q)'

# Remove docker images by name
function drmi() {
  docker rmi -f $(d images | grep $1 | awk '{print $3}')
}
