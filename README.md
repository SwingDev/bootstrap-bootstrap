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

## Update
If you are using old version of our bootstrap simply merge your branch with the changes from the upstream
```bash
git merge upstream master
```

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

## Running project
To run the project simply use run command:
```bash
./bootstrap.sh run
```

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
# Setup
## Adding new dependency
To add new dependency, simply use:
```bash
./bootstrap.sh add-module <repository-url> <directory>
```
This will add new line to `modules.txt` and fetch the repository.
If fetched repository constains `.docker-compose.template.yml`, it will be appended to your `docker-compose.yml` file.
In future versions we plan to extend this with templating mechanism, for now it is just pasting the content with the proper indentation (name of the container is set to the name of the directory you provide for the command).

# Authors
The tool is an Open Sourced version of the tool we are using internally in [SwingDev](https://swingdev.io).

## Contribution
We are open to your pull requests! If you want to improve the project, simply create a new pull request describing in detail new functionality, including update to this readme.

# License
This software is provided under MIT license.