# Bootstrap Bootstrap

# Requirements
- Bash
- Docker
- Git

# Installation
To start working with bootstrap simply clone bootstrap repository with our repository upstream renamed to upstream. It will help you get the updates from our repository while keeping your changes for your project.

```bash
git clone git@github.com:SwingDev/bootstrap-bootstrap.git . -o upstream
```

## Self-update
Script updates itself automatically on a daily basis.

# Usage
The repository consists of three main components:
- `modules.txt` - which points to all dependent repositories
- `docker-compose.yml` - which describes how the components should build and interact
- `boostrap.sh` - main script for managing and running the project

## Fetching all the dependencies
To fetch all dependencies simply run:
```bash
./bootstrap.sh
```

## Running / rebuilding project
To run the project simply use up command:

```bash
./bootstrap.sh up
```

Optionally you can pass a list of services to be rebuilt:

```bash
./bootstrap.sh up api web
```

## Services pre-run setup
Some services will need to perform a certain set of actions before they are able to start successfully. This might include eg. running migrations, setting up fixtures, etc.

To accommodate this, this script will run all the setup scripts, every time they change since the last setup run (as per last git modification timestamp).

Adding the setup scripts is as simple as
```bash
mkdir -p ./setup
touch ./setup/initialize-database.sh
```

All the `.sh` files in `./setup` directory are considered to be setup scripts. They are executed in alphabetical order as per bash.

**ATTENTION**: setup scripts **must** be idempotent (able to run multiple times without adverse effects), as they will run multiple times - on each change to the setup scripts.

Setup step will run right after `up` command.

Setup can be forced (regardless of the timestamps) by running:

```bash
./bootstrap.sh setup
```

**NOTE**: each setup script will be run up to 10 times, with a delay of 3 seconds (determined by it's exit code).

## Building only

You can just build the services without starting them up:

```bash
./bootstrap build
```

As with other commands you can specify which services to build

```bash
./bootstrap build api
```

## Logs
To see the logs use the `logs` command:

```bash
./bootstrap.sh logs
```

To see logs from only a couple of services, pass their names as arguments:

```bash
./bootstrap.sh logs api web
```

## Running commands on containers

You can run arbitrary commands within running containers via:

```bash
./bootstrap.sh exec api /bin/sh
```

The above example will start a shell on the api service.

## Stopping the project
To stop the project simply use down command:

```bash
./bootstrap.sh down
```

Stopping will delete all containers and all network leftovers, so make sure to mount everything you need persisted.

## Checking branches
To check on which branch each of the modules is, simply use the following command:

```bash
./bootstrap.sh branch
```

```bash
# Example of the output
frontend:       master
backend:        feature/#54
pdf-generator:  master
```

## Checking statuses
To check status of all the modules, use the following command:

```bash
./boostrap.sh status
```

```bash
# Example of the output
frontend:
     On branch master
     Your branch is up-to-date with 'origin/master'.
     nothing to commit, working tree clean
 backend:
      On branch master
      Your branch is up-to-date with 'origin/master'.
      Untracked files:
        (use "git add <file>..." to include in what will be committed)

      	new-file.txt

      nothing added to commit but untracked files present (use "git add" to track)
pdf-generator:
     On branch master
     Your branch is up-to-date with 'origin/master'.
     nothing to commit, working tree clean
```

## Custom docker-compose.yml location
It is possible to specify custom docker-compose.yml location. It might be useful if you have few configurations with different settings - for example configuration with frontend live-reload, backend live-reload or verbose output or different configuration for your CI with different ports binding. To do that, use `-c` parameter for any command:
```
./bootstrap.sh -c docker-compose.frontend.yml up
```

# Setup
## Adding new dependency
To add new dependency, simply use:

```bash
./bootstrap.sh add-module <repository-url> <directory>
```

This will add new line to `modules.txt`, fetch the repository and add its directory to bootstrap's `.gitignore`.
If fetched repository constains `.docker-compose.template.yml`, it will be appended to your `docker-compose.yml` file.
In future versions we plan to extend this with templating mechanism, for now it is just pasting the content with the proper indentation (name of the container is set to the name of the directory you provide for the command).

In the template, you can use `<PROJECT_DIR>` template string which will be replaced with a directory name where the project will be fetched. You can use it to setup docker volumes correctly for example.

# Authors
The tool is an Open Sourced version of the tool we are using internally in [SwingDev](https://swingdev.io).

## Contribution
We are open to your pull requests! If you want to improve the project, simply create a new pull request describing in detail new functionality, including update to this readme.

# License
This software is provided under MIT license.
