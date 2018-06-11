#!/bin/bash
set -e

COMMAND_STATUS='status'
COMMAND_BRANCH='branch'
COMMAND_ADD='add-module'
COMMAND_DOWN='down'
COMMAND_UP='up'
COMMAND_LOGS='logs'

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

function docker_compose_down() {
    docker-compose -f docker-compose.yml down $@
}

function docker_compose_up() {
    docker-compose -f docker-compose.yml up -d --remove-orphans --build $@
}

function docker_compose_logs() {
    echo "Attaching logs. Press Ctrl+C twice to exit."
    while sleep .5; do
        echo "Reattaching logs. Press Ctrl+C twice to exit."
        docker-compose -f docker-compose.yml logs --tail 100 --follow $@
    done
}

case "$1" in
    "$COMMAND_STATUS")
        (iterate_over_modules status);;
    "$COMMAND_BRANCH")
        (iterate_over_modules branch);;
    "$COMMAND_ADD")
        (add_module $2 $3);;
    "$COMMAND_DOWN")
        (docker_compose_down "${@:2}");;
    "$COMMAND_UP")
        (docker_compose_up "${@:2}");;
    "$COMMAND_LOGS")
        (docker_compose_logs "${@:2}");;
    "")
        (iterate_over_modules fetch_or_update);;
esac