#export KUBECONFIG="~/.kube/config:$(test -d ~/.kube/conf.d && find ~/.kube/conf.d -type f -maxdepth 1 | tr '\n' ':')"
export KUBECONFIG="$HOME/.kube/config"
