#!/bin/bash

# Info
function print_usage() {
    info "Home Infrastructure Utility Run: $ ./run.sh \n\
        \t -k Kill all existing containers and restart \n\
        \t -v Verbose";
}

kill_burn="false";

# Silencing
# We can't just devnull stdout, that would hide info and error feedback.
# Instead create a new output stream #3 to be used for git command stdout; default it to devnull
exec 3>/dev/null;
# Redirect stderr to devnull by default
exec 2>/dev/null;
# This will be handled in input flags later.
while getopts "kv" flag; do
    case "${flag}" in
        k) kill_burn="true" ;;
        v) exec 2>&1; exec 3>&1 ;; # redirect stderr, and git command stdout, to stdout
        *) print_usage
            exit 1 ;;
    esac
done

if [[ "$kill_burn" == "true" ]]; then
    # Kill all containers
    echo "Killing All Containers";
    docker kill $(docker ps -aq) >&3;
    # Remove all containers
    echo "Removing...";
    docker rm $(docker ps -aq) >&3;
    # Make everything available
fi

echo "Starting Containers...";
docker-compose up -d >&3;
echo "Containers Restarted";
