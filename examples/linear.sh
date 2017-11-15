#!/bin/bash

set -e

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DATADIR="$THISDIR/data/linear"
rm -r -f "$DATADIR"
mkdir -p "$DATADIR"

declare -A WORKING_DIRS

function runas
{
  PERSON="$1"
  COMMAND="$2"
  echo "################################################################################"
  echo "# $PERSON: $COMMAND"
  echo "################################################################################"
  if [[ -v WORKING_DIRS[$PERSON] ]];
  then
    cd ${WORKING_DIRS[$PERSON]}
  else
    mkdir -p "$DATADIR/$PERSON"
    cd "$DATADIR/$PERSON"
  fi
  eval "$COMMAND"
  WORKING_DIRS[$PERSON]=`pwd`
  sleep 1s
}

function upstream { runas "upstream" "$@"; }
function alice { runas "alice" "$@"; }
function bob { runas "bob" "$@"; }
function eve { runas "eve" "$@"; }

function section
{
  echo "################################################################################"
  echo "# $1"
  echo "################################################################################"
}

################################################################################
section "INITIALIZE UPSTREAM"

upstream 'mkdir project.git && cd project.git'
upstream 'git init --bare'

################################################################################
section "FIRST COMMIT"

alice 'git clone $DATADIR/upstream/project.git && cd project'
alice 'git config user.name "Alice"'
alice 'git config user.email alice@example.com'

alice 'echo "Hello World!" > README.md'
alice 'git add README.md && git commit -am "add readme"'
alice 'git push --set-upstream origin master'

################################################################################
section "DEVELOP BRANCH"

alice 'git checkout -b develop'
alice 'git push --set-upstream origin develop'

bob 'git clone $DATADIR/upstream/project.git && cd project'
bob 'git config user.name "Bob"'
bob 'git config user.email bob@example.com'
bob 'git checkout develop'

eve 'git clone $DATADIR/upstream/project.git && cd project'
eve 'git config user.name "Eve"'
eve 'git config user.email eve@example.com'
eve 'git checkout develop'

################################################################################
section "FEATURE BRANCHES"

alice 'git checkout -b feature/backend'
alice 'git push --set-upstream origin feature/backend'

bob 'git checkout -b feature/frontend'
bob 'git push --set-upstream origin feature/frontend'

eve 'git fetch --all'
eve 'git checkout feature/frontend'

################################################################################
section "BACKEND IMPLEMENTATION"

alice 'echo "console.log(\"This is the backend!\");" > backend.js';
alice 'git add backend.js && git commit -am "add backend"'
alice 'git push'

alice 'git checkout develop'
alice 'git merge --ff-only feature/backend'
alice 'git push'

################################################################################
section "FRONTEND IMPLEMENTATION PART 1"

bob 'echo "console.log(\"This is a frontend helper!\");" > frontend-helper.js';
bob 'git add frontend-helper.js && git commit -am "add frontend helper"'
bob 'git push'

################################################################################
section "FRONTEND IMPLEMENTATION PART 2"

eve 'echo "console.log(\"This is the frontend!\");" > frontend.js';
eve 'git add frontend.js && git commit -am "add frontend"'
eve 'git pull --rebase'

################################################################################
section "SYNC FRONTEND BRANCHES 1"

eve 'git push'
bob 'git pull --ff-only'

################################################################################
section "REBASE FRONTEND ONTO DEVELOP"

bob 'git fetch --all && git rebase origin/develop'
bob 'git push --force-with-lease'

################################################################################
section "FRONTEND IMPLEMENTATION PART 3"

eve 'echo "console.log(\"This is the frontend AGAIN!\");" >> frontend.js';
eve 'git commit -am "extend frontend"'

################################################################################
section "SYNC FRONTEND BRANCHES 2"

eve 'git pull --rebase'
eve 'git push'

################################################################################
section "MERGE FRONTEND INTO DEVELOP"

eve 'git checkout develop && git pull --ff-only'
eve 'git merge --ff-only feature/frontend'
eve 'git push'

################################################################################
section "DONE!"
