#!/bin/bash
set -e

SELF_UPDATE_GIT_REMOTE='git://github.com/swingdev/bootstrap-bootstrap.git'
SELF_UPDATE_STAMP_FILE='./._last_self_updated'

COMMAND_STATUS='status'
COMMAND_BRANCH='branch'
COMMAND_ADD='add-module'
COMMAND_DOWN='down'
COMMAND_UP='up'
COMMAND_BUILD='build'
COMMAND_LOGS='logs'
COMMAND_EXEC='exec'
DOCKER_COMPOSE_FILE='docker-compose.yml'

# Resolving Arguments
while getopts c: name
do
    case $name in
    c)    DOCKER_COMPOSE_FILE="$OPTARG";;
    ?)   printf "Usage: %s: [-c configuration-file] command\n" $0
        exit 2;;
    esac
done
shift $(($OPTIND - 1))
# -- End - Resolving Arguments

function indent_string() {
    sed -e 's/^/     /'
}

function self_heal() {
    git remote rm upstream 2>/dev/null || true
}

function self_update() {
    git fetch ${SELF_UPDATE_GIT_REMOTE} master
    git merge FETCH_HEAD
}

function self_update_if_its_time() {
    stamp_file_content="1970-01-01T00:00:00Z"
    if [ -f $SELF_UPDATE_STAMP_FILE ]; then
        stamp_file_content=$(cat $SELF_UPDATE_STAMP_FILE)
    fi

    now=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" $(date -u +"%Y-%m-%dT%H:%M:%SZ") +%s 2>/dev/null)
    stamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" ${stamp_file_content} +%s 2>/dev/null)

    delta=$(($now-$stamp))
    update_if_n_sec_passed=$((60*60*24*1))

    if [ $delta -ge $update_if_n_sec_passed ]; then
        echo "Performing self update..."
        self_update
        echo "Done."
        echo ""

        echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") > $SELF_UPDATE_STAMP_FILE
    fi
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
        echo "Updating $DOCKER_COMPOSE_FILE"
        TAB=$'\t'
        echo -e "${TAB}${folder}:" >> docker-compose.yml
        sed \
            -e "s/^/${TAB}${TAB}/" \
            -e "s/\<PROJECT_DIR\>/\.\/$folder/" \
            "./${folder}/.docker-compose.template.yml" >> $DOCKER_COMPOSE_FILE
    else
        echo "No template for docker compose module, you have to setup the module manually.";
    fi
}

function docker_compose_down() {
    docker-compose -f $DOCKER_COMPOSE_FILE down $@
}

function docker_compose_up() {
    docker-compose -f $DOCKER_COMPOSE_FILE up -d --remove-orphans --build $@
}

function docker_compose_build() {
    docker-compose -f $DOCKER_COMPOSE_FILE build --force-rm $@
}

function docker_compose_exec() {
    docker-compose -f $DOCKER_COMPOSE_FILE exec $@
}

function docker_compose_logs() {
    echo "Attaching logs. Press Ctrl+C twice to exit."
    while sleep .5; do
        echo "Reattaching logs. Press Ctrl+C twice to exit."
        docker-compose -f $DOCKER_COMPOSE_FILE logs --tail 100 --follow $@
    done
}

self_heal
self_update_if_its_time

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
    "$COMMAND_BUILD")
        (docker_compose_build "${@:2}");;
    "$COMMAND_EXEC")
        (docker_compose_exec "${@:2}");;
    "$COMMAND_LOGS")
        (docker_compose_logs "${@:2}");;
    "")
        (iterate_over_modules fetch_or_update);;
esac
