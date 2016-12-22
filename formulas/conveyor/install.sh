test -d ~/git/conveyor || {
    git clone git@github.com:webcreate/conveyor.git ~/git/conveyor
    cd ~/git/conveyor
    composer install
}
