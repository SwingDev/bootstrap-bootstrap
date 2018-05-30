#!/bin/bash
set -e

COMMAND_STATUS='status'
COMMAND_BRANCH='branch'
COMMAND_ADD='add-module'
COMMAND_RUN='run'

function indent_string() {
    sed -e 's/^/     /'
}

function iterate_over_modules() {
    fn=$1;
    while IFS='' read -r line; do
        el=($line)
        repo="${el[0]}"
        dir="${el[1]}"
        ($fn $repo $dir)
    done < "modules.txt"
}

function fetch_or_update() {
    repo=$1;
    dir=$2;
    if [ -e "./$dir" ]; then
        echo "${dir}: Updating"
        cd ${dir}
        git checkout -q master
        git pull | indent_string
        cd ..
    else
        echo "${dir}: Fetching from ${repo}"
        git clone ${repo} ${dir} 2>&1 | indent_string
    fi
}

function status() {
    repo=$1;
    dir=$2;
    if [ -e "./$dir" ]; then
        echo "${dir}"
        cd ${dir}
        git status | indent_string
        cd ..
    else
        echo "{$dir} does not exist"
    fi
}

function branch() {
    repo=$1;
    dir=$2;
    if [ -e "./$dir" ]; then
        cd ${dir}
        branch=`git rev-parse --abbrev-ref HEAD`
        printf "%-15s %s\n" "${dir}:" $branch
#        echo -e "${dir}: \t\t"
        cd ..
    else
        echo "${dir} does not exist"
    fi
}

function add_module() {
    url=$1;
    folder=$2;
    echo "Adding module $url $folder";
    echo "$url $folder" >> modules.txt
    (fetch_or_update $url $folder);
    # Updating docker compose
    if [ -f "${folder}/.docker-compose.template.yml" ]; then
        echo "Updating docker-compose.yml"
        TAB=$'\t'
        echo -e "${TAB}${folder}:" >> docker-compose.yml
        sed -e "s/^/${TAB}${TAB}/" "./${folder}/.docker-compose.template.yml" >> docker-compose.yml
    else
        echo "No template for docker compose module, you have to setup the module manually.";
    fi
}

function cleanup {
  docker-compose -f docker-compose.yml stop
}

function run_docker_compose() {
    echo "RUN";
    cleanup
    trap cleanup EXIT
    docker-compose -f docker-compose.yml up -d --build
    docker-compose -f docker-compose.yml logs --follow
}


case "$1" in
    "$COMMAND_STATUS")
        (iterate_over_modules status);;
    "$COMMAND_BRANCH")
        (iterate_over_modules branch);;
    "$COMMAND_ADD")
        (add_module $2 $3);;
    "$COMMAND_RUN")
        (run_docker_compose);;
    "")
        (iterate_over_modules fetch_or_update);;
esac