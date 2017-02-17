# The next line enables shell command completion for gcloud.
if [ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc ]; then
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'
fi

# Deprecated
if [ -f /usr/local/lib/gcloud/google-cloud-sdk/completion.zsh.inc ]; then
  source '/usr/local/lib/gcloud/google-cloud-sdk/completion.zsh.inc'
fi
