# The next line updates PATH for the Google Cloud SDK.
if [ -f /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.in ]; then
  source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.in'
fi

# Deprecated
if [ -f /usr/local/lib/gcloud/google-cloud-sdk/path.zsh.inc ]; then
  source '/usr/local/lib/gcloud/google-cloud-sdk/path.zsh.inc'
fi
